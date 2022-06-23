import { Contract, Wallet, utils, BigNumber, BigNumberish, Signer, PopulatedTransaction } from "ethers"
import { TypedDataSigner } from "@ethersproject/abstract-signer";
import { AddressZero } from "@ethersproject/constants";

export const EIP_DOMAIN = {
    EIP712Domain: [
        { type: "uint256", name: "chainId" },
        { type: "address", name: "verifyingContract" }
    ]
}

export const EIP712_SAFE_TX_TYPE = {
    // "HabitatTx(address to,uint256 value,bytes data,uint8 operation,uint256 txGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    HabitatTx: [
        { type: "address", name: "to" },
        { type: "uint256", name: "value" },
        { type: "bytes", name: "data" },
        { type: "uint8", name: "operation" },
        { type: "uint256", name: "txGas" },
        { type: "uint256", name: "baseGas" },
        { type: "uint256", name: "gasPrice" },
        { type: "address", name: "gasToken" },
        { type: "address", name: "refundReceiver" },
        { type: "uint256", name: "nonce" },
    ]
}

export const EIP712_SAFE_MESSAGE_TYPE = {
    // "SafeMessage(bytes message)"
    SafeMessage: [
        { type: "bytes", name: "message" },
    ]
}

export interface MetaTransaction {
    to: string,
    value: string | number | BigNumber,
    data: string,
    operation: number,
}

export interface HabitatTransaction extends MetaTransaction {
    txGas: string | number,
    baseGas: string | number,
    gasPrice: string | number,
    gasToken: string,
    refundReceiver: string,
    nonce: string | number
}

export interface HabitatSignature {
    signer: string,
    data: string
}

export const calculateHabitatDomainSeparator = (habitat: Contract, chainId: BigNumberish): string => {
    return utils._TypedDataEncoder.hashDomain({ verifyingContract: habitat.address, chainId })
}

export const preimageHabitatTransactionHash = (habitat: Contract, habitatTx: HabitatTransaction, chainId: BigNumberish): string => {
    return utils._TypedDataEncoder.encode({ verifyingContract: habitat.address, chainId }, EIP712_SAFE_TX_TYPE, habitatTx)
}

export const calculateHabitatTransactionHash = (habitat: Contract, habitatTx: HabitatTransaction, chainId: BigNumberish): string => {
    return utils._TypedDataEncoder.hash({ verifyingContract: habitat.address, chainId }, EIP712_SAFE_TX_TYPE, habitatTx)
}

export const calculateSafeMessageHash = (habitat: Contract, message: string, chainId: BigNumberish): string => {
    return utils._TypedDataEncoder.hash({ verifyingContract: habitat.address, chainId }, EIP712_SAFE_MESSAGE_TYPE, { message })
}

export const habitatApproveHash = async (signer: Signer, habitat: Contract, habitatTx: HabitatTransaction, skipOnChainApproval?: boolean): Promise<HabitatSignature> => {
    if (!skipOnChainApproval) {
        if (!signer.provider) throw Error("Provider required for on-chain approval")
        const chainId = (await signer.provider.getNetwork()).chainId
        const typedDataHash = utils.arrayify(calculateHabitatTransactionHash(habitat, habitatTx, chainId))
        const signerSafe = habitat.connect(signer)
        await signerSafe.approveHash(typedDataHash)
    }
    const signerAddress = await signer.getAddress()
    return {
        signer: signerAddress,
        data: "0x000000000000000000000000" + signerAddress.slice(2) + "0000000000000000000000000000000000000000000000000000000000000000" + "01"
    }
}

export const habitatSignTypedData = async (signer: Signer & TypedDataSigner, habitat: Contract, habitatTx: HabitatTransaction, chainId?: BigNumberish): Promise<HabitatSignature> => {
    if (!chainId && !signer.provider) throw Error("Provider required to retrieve chainId")
    const cid = chainId || (await signer.provider!!.getNetwork()).chainId
    const signerAddress = await signer.getAddress()
    return {
        signer: signerAddress,
        data: await signer._signTypedData({ verifyingContract: habitat.address, chainId: cid }, EIP712_SAFE_TX_TYPE, habitatTx)
    }
}

export const signHash = async (signer: Signer, hash: string): Promise<HabitatSignature> => {
    const typedDataHash = utils.arrayify(hash)
    const signerAddress = await signer.getAddress()
    return {
        signer: signerAddress,
        data: (await signer.signMessage(typedDataHash)).replace(/1b$/, "1f").replace(/1c$/, "20")
    }
}

export const habitatSignMessage = async (signer: Signer, habitat: Contract, habitatTx: HabitatTransaction, chainId?: BigNumberish): Promise<HabitatSignature> => {
    const cid = chainId || (await signer.provider!!.getNetwork()).chainId
    return signHash(signer, calculateHabitatTransactionHash(habitat, habitatTx, cid))
}

export const buildSignatureBytes = (signatures: HabitatSignature[]): string => {
    signatures.sort((left, right) => left.signer.toLowerCase().localeCompare(right.signer.toLowerCase()))
    let signatureBytes = "0x"
    for (const sig of signatures) {
        signatureBytes += sig.data.slice(2)
    }
    return signatureBytes
}

export const logGas = async (message: string, tx: Promise<any>, skip?: boolean): Promise<any> => {
    return tx.then(async (result) => {
        const receipt = await result.wait()
        if (!skip) console.log("           Used", receipt.gasUsed.toNumber(), `gas for >${message}<`)
        return result
    })
}

export const executeTx = async (habitat: Contract, habitatTx: HabitatTransaction, signatures: HabitatSignature[], overrides?: any): Promise<any> => {
    const signatureBytes = buildSignatureBytes(signatures)
    return habitat.execTransaction(habitatTx.to, habitatTx.value, habitatTx.data, habitatTx.operation, habitatTx.txGas, habitatTx.baseGas, habitatTx.gasPrice, habitatTx.gasToken, habitatTx.refundReceiver, signatureBytes, overrides || {})
}

export const populateExecuteTx = async (habitat: Contract, habitatTx: HabitatTransaction, signatures: HabitatSignature[], overrides?: any): Promise<PopulatedTransaction> => {
    const signatureBytes = buildSignatureBytes(signatures)
    return habitat.populateTransaction.execTransaction(
        habitatTx.to, habitatTx.value, habitatTx.data, habitatTx.operation, habitatTx.txGas, habitatTx.baseGas, habitatTx.gasPrice, habitatTx.gasToken, habitatTx.refundReceiver,
        signatureBytes,
        overrides || {}
    )
}

export const buildContractCall = (contract: Contract, method: string, params: any[], nonce: number, delegateCall?: boolean, overrides?: Partial<HabitatTransaction>): HabitatTransaction => {
    const data = contract.interface.encodeFunctionData(method, params)
    return buildHabitatTask(Object.assign({
        to: contract.address,
        data,
        operation: delegateCall ? 1 : 0,
        nonce
    }, overrides))
}

export const executeTxWithSigners = async (habitat: Contract, tx: HabitatTransaction, signers: Wallet[], overrides?: any) => {
    const sigs = await Promise.all(signers.map((signer) => habitatSignTypedData(signer, habitat, tx)))
    return executeTx(habitat, tx, sigs, overrides)
}

export const executeContractCallWithSigners = async (habitat: Contract, contract: Contract, method: string, params: any[], signers: Wallet[], delegateCall?: boolean, overrides?: Partial<HabitatTransaction>) => {
    const tx = buildContractCall(contract, method, params, await habitat.nonce(), delegateCall, overrides)
    return executeTxWithSigners(habitat, tx, signers)
}

export const buildHabitatTask = (template: {
    to: string, value?: BigNumber | number | string, data?: string, operation?: number, txGas?: number | string,
    baseGas?: number | string, gasPrice?: number | string, gasToken?: string, refundReceiver?: string, nonce: number
}): HabitatTransaction => {
    return {
        to: template.to,
        value: template.value || 0,
        data: template.data || "0x",
        operation: template.operation || 0,
        txGas: template.txGas || 0,
        baseGas: template.baseGas || 0,
        gasPrice: template.gasPrice || 0,
        gasToken: template.gasToken || AddressZero,
        refundReceiver: template.refundReceiver || AddressZero,
        nonce: template.nonce
    }
}