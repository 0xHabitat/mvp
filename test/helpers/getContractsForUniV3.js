const { ethers } = require("hardhat");
const nfPositionManagerABI = require('../abis/NonfungiblePositionManager.json');
const uniswapV3PoolABI = require('../abis/UniswapV3Pool.json');
const wETHABI = require('../abis/WETH.json');
const nfPositionManagerAddress = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88";
const wETHAddress = "0x4200000000000000000000000000000000000006";
const wETHAddressGoerli = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6";
const POOL_BYTECODE_HASH = "0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54";
const FACTORY_ADDRESS = "0x1F98431c8aD98523631AE4a59f267346ea31F984";

function getContractsForUniV3(habitatAddress, fee, signer) {
  const weth = new ethers.Contract(wETHAddress, wETHABI.abi, signer);
  const nfPositionManager = new ethers.Contract(nfPositionManagerAddress, nfPositionManagerABI.abi, signer);
  const poolAddress = computePoolAddress([wETHAddress, habitatAddress], fee);
  const pool = new ethers.Contract(poolAddress, uniswapV3PoolABI.abi, signer);
  return {weth, nfPositionManager, pool};
}

function getWETH(signer) {
  const weth = new ethers.Contract(wETHAddress, wETHABI.abi, signer);
  return weth;
}

function computePoolAddress([tokenA, tokenB], fee) {
  const [token0, token1] = tokenA.toLowerCase() < tokenB.toLowerCase() ? [tokenA, tokenB] : [tokenB, tokenA]
  const constructorArgumentsEncoded = ethers.utils.defaultAbiCoder.encode(
    ['address', 'address', 'uint24'],
    [token0, token1, fee]
  )
  const create2Inputs = [
    '0xff',
    FACTORY_ADDRESS,
    // salt
    ethers.utils.keccak256(constructorArgumentsEncoded),
    // init code hash
    POOL_BYTECODE_HASH,
  ]
  const sanitizedInputs = `0x${create2Inputs.map((i) => i.slice(2)).join('')}`
  return ethers.utils.getAddress(`0x${ethers.utils.keccak256(sanitizedInputs).slice(-40)}`)
}

exports.getContractsForUniV3 = getContractsForUniV3;
exports.getWETH = getWETH;
