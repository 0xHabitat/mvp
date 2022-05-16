import hre, { deployments, ethers } from "hardhat";
import { Wallet, Contract } from "ethers";
import { AddressZero } from "@ethersproject/constants";
import solc from "solc";
import { logGas } from "./execution";
import { safeContractUnderTest } from "./config";

export const defaultCallbackHandlerDeployment = async () => {
    return await deployments.get("DefaultCallbackHandler");
}

export const defaultCallbackHandlerContract = async () => {
    return await hre.ethers.getContractFactory("DefaultCallbackHandler");
}

export const compatFallbackHandlerDeployment = async () => {
    return await deployments.get("CompatibilityFallbackHandler");
}

export const compatFallbackHandlerContract = async () => {
    return await hre.ethers.getContractFactory("CompatibilityFallbackHandler");
}

export const getHabitatSingleton = async () => {
    await deployments.fixture('ManagementSystem');
    const HabitatDeployment = await ethers.getContract('ManagementSystem');
    const Habitat = await hre.ethers.getContractFactory(safeContractUnderTest());
    return Habitat.attach(HabitatDeployment.address);
}

export const getOwnerDecider = async (owners: string[]) => {
    await deployments.fixture('OnlyOwnerDecider');
    const DeciderDeployment = await ethers.getContract('OnlyOwnerDecider');
    const Decider = await hre.ethers.getContractFactory("OnlyOwnerDecider");
    let abiCoder = ethers.utils.defaultAbiCoder;
    await DeciderDeployment.setup(abiCoder.encode([ "address[]" ], [ owners ]));
    return Decider.attach(DeciderDeployment.address);
}

export const getFactory = async () => {
    const FactoryDeployment = await deployments.get("ProxyFactory");
    const Factory = await hre.ethers.getContractFactory("ProxyFactory");
    return Factory.attach(FactoryDeployment.address);
}

export const getSimulateTxAccessor = async () => {
    const SimulateTxAccessorDeployment = await deployments.get("SimulateTxAccessor");
    const SimulateTxAccessor = await hre.ethers.getContractFactory("SimulateTxAccessor");
    return SimulateTxAccessor.attach(SimulateTxAccessorDeployment.address);
}

export const getMultiSend = async () => {
    const MultiSendDeployment = await deployments.get("MultiSend");
    const MultiSend = await hre.ethers.getContractFactory("MultiSend");
    return MultiSend.attach(MultiSendDeployment.address);
}

export const getMultiSendCallOnly = async () => {
    const MultiSendDeployment = await deployments.get("MultiSendCallOnly");
    const MultiSend = await hre.ethers.getContractFactory("MultiSendCallOnly");
    return MultiSend.attach(MultiSendDeployment.address);
}

export const getCreateCall = async () => {
    const CreateCallDeployment = await deployments.get("CreateCall");
    const CreateCall = await hre.ethers.getContractFactory("CreateCall");
    return CreateCall.attach(CreateCallDeployment.address);
}

export const migrationContract = async () => {
    return await hre.ethers.getContractFactory("Migration");
}


export const getMock = async () => {
    const Mock = await hre.ethers.getContractFactory("MockContract");
    return await Mock.deploy();
}

export const getHabitatTemplate = async () => {
    const singleton = await getHabitatSingleton();
    const factory = await getFactory();
    const template = await factory.callStatic.createProxy(singleton.address, "0x");
    await factory.createProxy(singleton.address, "0x").then((tx: any) => tx.wait());
    const Habitat = await hre.ethers.getContractFactory(safeContractUnderTest());
    return Habitat.attach(template);
}

export const getHabitatWithOwners = async (owners: string[], threshold?: number, fallbackHandler?: string, logGasUsage?: boolean) => {
    const template = await getHabitatTemplate();
    const decider = await getOwnerDecider(owners);
    await logGas(
        `Setup Habitat with ${owners.length} owner(s)${fallbackHandler && fallbackHandler !== AddressZero ? " and fallback handler" : ""}`, 
        template.setup(decider.address),
        !logGasUsage
    )
    return template
}

export const getDefaultCallbackHandler = async () => {
    return (await defaultCallbackHandlerContract()).attach((await defaultCallbackHandlerDeployment()).address);
}

export const getCompatFallbackHandler = async () => {
    return (await compatFallbackHandlerContract()).attach((await compatFallbackHandlerDeployment()).address);
}

export const compile = async (source: string) => {
    const input = JSON.stringify({
        'language': 'Solidity',
        'settings': {
            'outputSelection': {
            '*': {
                '*': [ 'abi', 'evm.bytecode' ]
            }
            }
        },
        'sources': {
            'tmp.sol': {
                'content': source
            }
        }
    });
    const solcData = await solc.compile(input)
    const output = JSON.parse(solcData);
    if (!output['contracts']) {
        throw Error("Could not compile contract")
    }
    const fileOutput = output['contracts']['tmp.sol']
    const contractOutput = fileOutput[Object.keys(fileOutput)[0]]
    const abi = contractOutput['abi']
    const data = '0x' + contractOutput['evm']['bytecode']['object']
    return {
        "data": data,
        "interface": abi
    }
}

export const deployContract = async (deployer: Wallet, source: string): Promise<Contract> => {
    const output = await compile(source)
    const transaction = await deployer.sendTransaction({ data: output.data, gasLimit: 6000000 })
    const receipt = await transaction.wait()
    return new Contract(receipt.contractAddress, output.interface, deployer)
}