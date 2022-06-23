import { expect } from './utils/chai-setup';
import { ethers, deployments } from "hardhat";
import "@nomiclabs/hardhat-ethers";
import { AddressZero } from "@ethersproject/constants";
import { getHabitatTemplate, getHabitatWithOwners } from "./utils/setup";
import { habitatSignTypedData, executeTx, habitatSignMessage, calculateHabitatTransactionHash, habitatApproveHash, buildHabitatTask, logGas, calculateHabitatDomainSeparator, preimageHabitatTransactionHash, buildSignatureBytes } from "./utils/execution";
import { chainId } from "./utils/encoding";

describe("ManagementSystem", async () => {

    const [user1, user2, user3, user4] = await ethers.getSigners();

    const setupTests = deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const habitat = await getHabitatWithOwners([user1.address]);
        return {
            habitat: habitat,
            decider: (await habitat.decider())
        }
    })
    describe("domainSeparator", async () => {
        it('should be correct according to EIP-712', async () => {
            const { habitat } = await setupTests()
            const domainSeparator = calculateHabitatDomainSeparator(habitat, await chainId())
            await expect(
                await habitat.domainSeparator()
            ).to.be.eq(domainSeparator)
        })
    })

    describe("hashTask", async () => {
        it('should correctly calculate EIP-712 hash', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const typedDataHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            await expect(
                await habitat.hashTask(
                    tx.to, tx.value, tx.data, tx.operation, tx.txGas, tx.baseGas, tx.gasPrice, tx.gasToken, tx.refundReceiver, tx.nonce
                )
            ).to.be.eq(typedDataHash)
        })
    })

    describe("getChainId", async () => {
        it('should return correct id', async () => {
            const { habitat } = await setupTests()
            expect(
                await habitat.getChainId()
            ).to.be.eq(await chainId())
        })
    })

    describe("approveHash", async () => {
        it('approving should only be allowed for owners', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            let decider = await habitat.decider();
            console.log(decider);
            decider = decider.connect(user2);
            await expect(
                decider.approveHash(txHash)
            ).to.be.revertedWith("GS030")
        })

        it('approving should emit event', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            await expect(
                habitat.approveHash(txHash)
            ).emit(habitat, "ApproveHash").withArgs(txHash, user1.address)
        })
    })

    describe("execTask", async () => {
        it('should fail if signature points into static part', async () => {
            const { habitat } = await setupTests()
            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000020" + "00" + // r, s, v  
                "0000000000000000000000000000000000000000000000000000000000000000" // Some data to read
            await expect(
                habitat.execTask(habitat.address, 0, "0x", 0, 0, 0, 0, AddressZero, AddressZero, signatures)
            ).to.be.revertedWith("GS021")
        })

        it('should fail if sigantures data is not present', async () => {
            const { habitat } = await setupTests()

            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000041" + "00" // r, s, v

            await expect(
                habitat.execTask(habitat.address, 0, "0x", 0, 0, 0, 0, AddressZero, AddressZero, signatures)
            ).to.be.revertedWith("GS022")
        })

        it('should fail if sigantures data is too short', async () => {
            const { habitat } = await setupTests()

            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000041" + "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000020" // length

            await expect(
                habitat.execTask(habitat.address, 0, "0x", 0, 0, 0, 0, AddressZero, AddressZero, signatures)
            ).to.be.revertedWith("GS023")
        })

        it('should be able to use EIP-712 for signature generation', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                logGas(
                    "Execute cancel transaction with EIP-712 signature",
                    executeTx(habitat, tx, [await habitatSignTypedData(user1, habitat, tx)])
                )
            ).to.emit(habitat, "ExecutionSuccess")
        })

        it('should not be able to use different chainId for signing', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                executeTx(habitat, tx, [await habitatSignTypedData(user1, habitat, tx, 1)])
            ).to.be.revertedWith("GS026")
        })

        it('should be able to use Signed Ethereum Messages for signature generation', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                logGas(
                    "Execute cancel transaction with signed Ethereum message",
                    executeTx(habitat, tx, [await habitatSignMessage(user1, habitat, tx)])
                )
            ).to.emit(habitat, "ExecutionSuccess")
        })

        it('msg.sender does not need to approve before', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                logGas(
                    "Without pre approved signature for msg.sender",
                    executeTx(habitat, tx, [await habitatApproveHash(user1, habitat, tx, true)])
                )
            ).to.emit(habitat, "ExecutionSuccess")
        })

        it('if not msg.sender on-chain approval is required', async () => {
            const { habitat } = await setupTests()
            const user2Safe = habitat.connect(user2)
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                executeTx(user2Safe, tx, [await habitatApproveHash(user1, habitat, tx, true)])
            ).to.be.revertedWith("GS025")
        })

        it('should be able to use pre approved hashes for signature generation', async () => {
            const { habitat } = await setupTests()
            const user2Safe = habitat.connect(user2)
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const approveHashSig = await habitatApproveHash(user1, habitat, tx)
            expect(
                await habitat.approvedHashes(user1.address, txHash)
            ).to.be.eq(1)
            await expect(
                logGas(
                    "With pre approved signature",
                    executeTx(user2Safe, tx, [approveHashSig])
                )
            ).to.emit(habitat, "ExecutionSuccess")
            // Approved hash should not reset automatically
            expect(
                await habitat.approvedHashes(user1.address, txHash)
            ).to.be.eq(1)
        })

        it('should revert if threshold is not set', async () => {
            await setupTests()
            const habitat = await getHabitatTemplate()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                executeTx(habitat, tx, [])
            ).to.be.revertedWith("GS001")
        })

        it('should revert if not the required amount of signature data is provided', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                executeTx(habitat, tx, [])
            ).to.be.revertedWith("GS020")
        })

        it('should not be able to use different signature type of same owner', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                executeTx(habitat, tx, [await habitatApproveHash(user1, habitat, tx), await habitatSignTypedData(user1, habitat, tx), await habitatSignTypedData(user3, habitat, tx)])
            ).to.be.revertedWith("GS026")
        })

        it('should be able to mix all signature types', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address, user4.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            await expect(
                logGas(
                    "Execute cancel transaction with 4 owners",
                    executeTx(habitat, tx, [
                        await habitatApproveHash(user1, habitat, tx, true),
                        await habitatApproveHash(user4, habitat, tx),
                        await habitatSignTypedData(user2, habitat, tx),
                        await habitatSignTypedData(user3, habitat, tx)
                    ])
                )
            ).to.emit(habitat, "ExecutionSuccess")
        })
    })

    describe("checkSignatures", async () => {
        it('should fail if signature points into static part', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000020" + "00" + // r, s, v  
                "0000000000000000000000000000000000000000000000000000000000000000" // Some data to read
            await expect(
                habitat.checkSignatures(txHash, txHashData, signatures)
            ).to.be.revertedWith("GS021")
        })

        it('should fail if signatures data is not present', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())

            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000041" + "00" // r, s, v

            await expect(
                habitat.checkSignatures(txHash, txHashData, signatures)
            ).to.be.revertedWith("GS022")
        })

        it('should fail if signatures data is too short', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())

            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000041" + "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000020" // length

            await expect(
                habitat.checkSignatures(txHash, txHashData, signatures)
            ).to.be.revertedWith("GS023")
        })

        it('should not be able to use different chainId for signing', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([await habitatSignTypedData(user1, habitat, tx, 1)])
            await expect(
                habitat.checkSignatures(txHash, txHashData, signatures)
            ).to.be.revertedWith("GS026")
        })

        it('if not msg.sender on-chain approval is required', async () => {
            const { habitat } = await setupTests()
            const user2Safe = habitat.connect(user2)
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([await habitatApproveHash(user1, habitat, tx, true)])
            await expect(
                user2Safe.checkSignatures(txHash, txHashData, signatures)
            ).to.be.revertedWith("GS025")
        })

        it('should revert if threshold is not set', async () => {
            await setupTests()
            const habitat = await getHabitatTemplate()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            await expect(
                habitat.checkSignatures(txHash, txHashData, "0x")
            ).to.be.revertedWith("GS001")
        })

        it('should revert if not the required amount of signature data is provided', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            await expect(
                habitat.checkSignatures(txHash, txHashData, "0x")
            ).to.be.revertedWith("GS020")
        })

        it('should not be able to use different signature type of same owner', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([
                await habitatApproveHash(user1, habitat, tx),
                await habitatSignTypedData(user1, habitat, tx),
                await habitatSignTypedData(user3, habitat, tx)
            ])
            await expect(
                habitat.checkSignatures(txHash, txHashData, signatures)
            ).to.be.revertedWith("GS026")
        })

        it('should be able to mix all signature types', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address, user4.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([
                await habitatApproveHash(user1, habitat, tx, true),
                await habitatApproveHash(user4, habitat, tx),
                await habitatSignTypedData(user2, habitat, tx),
                await habitatSignTypedData(user3, habitat, tx)
            ])

            await habitat.checkSignatures(txHash, txHashData, signatures)
        })
    })

    describe("checkSignatures", async () => {
        it('should fail if signature points into static part', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000020" + "00" + // r, s, v  
                "0000000000000000000000000000000000000000000000000000000000000000" // Some data to read
            await expect(
                habitat.checkNSignatures(txHash, txHashData, signatures, 1)
            ).to.be.revertedWith("GS021")
        })

        it('should fail if signatures data is not present', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())

            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000041" + "00" // r, s, v

            await expect(
                habitat.checkNSignatures(txHash, txHashData, signatures, 1)
            ).to.be.revertedWith("GS022")
        })

        it('should fail if signatures data is too short', async () => {
            const { habitat } = await setupTests()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())

            const signatures = "0x" + "000000000000000000000000" + user1.address.slice(2) + "0000000000000000000000000000000000000000000000000000000000000041" + "00" + // r, s, v
                "0000000000000000000000000000000000000000000000000000000000000020" // length

            await expect(
                habitat.checkNSignatures(txHash, txHashData, signatures, 1)
            ).to.be.revertedWith("GS023")
        })

        it('should not be able to use different chainId for signing', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([await habitatSignTypedData(user1, habitat, tx, 1)])
            await expect(
                habitat.checkNSignatures(txHash, txHashData, signatures, 1)
            ).to.be.revertedWith("GS026")
        })

        it('if not msg.sender on-chain approval is required', async () => {
            const { habitat } = await setupTests()
            const user2Safe = habitat.connect(user2)
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([await habitatApproveHash(user1, habitat, tx, true)])
            await expect(
                user2Safe.checkNSignatures(txHash, txHashData, signatures, 1)
            ).to.be.revertedWith("GS025")
        })

        it('should revert if not the required amount of signature data is provided', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            await expect(
                habitat.checkNSignatures(txHash, txHashData, "0x", 1)
            ).to.be.revertedWith("GS020")
        })

        it('should not be able to use different signature type of same owner', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([
                await habitatApproveHash(user1, habitat, tx),
                await habitatSignTypedData(user1, habitat, tx),
                await habitatSignTypedData(user3, habitat, tx)
            ])
            await expect(
                habitat.checkNSignatures(txHash, txHashData, signatures, 3)
            ).to.be.revertedWith("GS026")
        })

        it('should be able to mix all signature types', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address, user4.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([
                await habitatApproveHash(user1, habitat, tx, true),
                await habitatApproveHash(user4, habitat, tx),
                await habitatSignTypedData(user2, habitat, tx),
                await habitatSignTypedData(user3, habitat, tx)
            ])

            await habitat.checkNSignatures(txHash, txHashData, signatures, 3)
        })

        it('should be able to require no signatures', async () => {
            await setupTests()
            const habitat = await getHabitatTemplate()
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())

            await habitat.checkNSignatures(txHash, txHashData, "0x", 0)
        })

        it('should be able to require less signatures than the threshold', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address, user4.address])
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([
                await habitatSignTypedData(user3, habitat, tx)
            ])

            await habitat.checkNSignatures(txHash, txHashData, signatures, 1)
        })

        it('should be able to require more signatures than the threshold', async () => {
            await setupTests()
            const habitat = await getHabitatWithOwners([user1.address, user2.address, user3.address, user4.address], 2)
            const tx = buildHabitatTask({ to: habitat.address, nonce: await habitat.nonce() })
            const txHashData = preimageHabitatTransactionHash(habitat, tx, await chainId())
            const txHash = calculateHabitatTransactionHash(habitat, tx, await chainId())
            const signatures = buildSignatureBytes([
                await habitatApproveHash(user1, habitat, tx, true),
                await habitatApproveHash(user4, habitat, tx),
                await habitatSignTypedData(user2, habitat, tx)
            ])
            // Should fail as only 3 signaures are provided
            await expect(
                habitat.checkNSignatures(txHash, txHashData, signatures, 4)
            ).to.be.revertedWith("GS020")

            await habitat.checkNSignatures(txHash, txHashData, signatures, 3)
        })
    })
})