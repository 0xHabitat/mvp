const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const nfPositionManagerABI = require('./abis/NonfungiblePositionManager.json');
const uniswapV3PoolABI = require('./abis/UniswapV3Pool.json');
const wETHABI = require('./abis/WETH.json');
const nfPositionManagerAddress = "0xC36442b4a4522E871399CD717aBDD847Ab11FE88";
const wETHAddress = "0x4200000000000000000000000000000000000006";

const tickSpacing = {
  "500": 10,
  "3000": 60,
  "10000": 200
}

describe('Stake', function () {
  let accounts;
  let signer;
  let tester1;
  let tester2;
  let hbtToken;
  let weth;
  let votingPowerHolder;
  let stakeContractERC20UniV3;
  let nfPositionManager;
  let positionValueTest;
  let isHBTToken0;
  const pools = {
    "500": "",
    "3000": "",
    "10000": ""
  };

  before(async function () {
    accounts = await ethers.getSigners();
    signer = accounts[0];
    tester1 = accounts[1];
    tester2 = accounts[2];
    const MockERC20 = await ethers.getContractFactory('MockERC20');
    hbtToken = await MockERC20.deploy("Habitat", "HBT", signer.address, ethers.BigNumber.from('1000000000000000000000000'));
    await hbtToken.deployed();
    weth = new ethers.Contract(wETHAddress, wETHABI.abi, signer);
    const MockVotingPowerHolder = await ethers.getContractFactory('MockVotingPowerHolder');
    votingPowerHolder = await MockVotingPowerHolder.deploy();
    await votingPowerHolder.deployed();
    const StakeContractERC20UniV3 = await ethers.getContractFactory('StakeContractERC20UniV3');
    stakeContractERC20UniV3 = await StakeContractERC20UniV3.deploy(votingPowerHolder.address, nfPositionManagerAddress, hbtToken.address, [wETHAddress]);
    await stakeContractERC20UniV3.deployed();
    await votingPowerHolder.setVPM(stakeContractERC20UniV3.address);
    const PositionValueTest = await ethers.getContractFactory('PositionValueTest');
    positionValueTest = await PositionValueTest.deploy();
    await positionValueTest.deployed();
    nfPositionManager = new ethers.Contract(nfPositionManagerAddress, nfPositionManagerABI.abi, signer);

    if (ethers.BigNumber.from(hbtToken.address).lt(ethers.BigNumber.from(wETHAddress))) {
      isHBTToken0 = true;
      const priceOneKHBTForETH = ethers.BigNumber.from("0x81853cdc3fe8b949c55450b");
      for (fee in pools) {
        const poolAddress = await nfPositionManager.callStatic.createAndInitializePoolIfNecessary(hbtToken.address, wETHAddress, ethers.BigNumber.from(fee), priceOneKHBTForETH);
        pools[fee] = poolAddress;
        await nfPositionManager.createAndInitializePoolIfNecessary(hbtToken.address, wETHAddress, ethers.BigNumber.from(fee), priceOneKHBTForETH);
      }
    } else {
      isHBTToken0 = false;
      const priceOneKHBTForETH = ethers.BigNumber.from("0x1f9f6d9a3bc5ab22441f2925e9");
      for (fee in pools) {
        const poolAddress = await nfPositionManager.callStatic.createAndInitializePoolIfNecessary(wETHAddress, hbtToken.address, ethers.BigNumber.from(fee), priceOneKHBTForETH);
        pools[fee] = poolAddress;
        await nfPositionManager.createAndInitializePoolIfNecessary(wETHAddress, hbtToken.address, ethers.BigNumber.from(fee), priceOneKHBTForETH);
      }
    }
  });

  it('positionValueTest should calculate correct', async function () {
    for (fee in pools) {

      const block = await ethers.provider.getBlock();

      const pool = new ethers.Contract(pools[fee], uniswapV3PoolABI.abi, signer);
      await weth.deposit({value: ethers.BigNumber.from("1000000000000000000")});
      await weth.approve(nfPositionManager.address, ethers.BigNumber.from("1000000000000000000"));
      await hbtToken.approve(nfPositionManager.address, ethers.BigNumber.from("1000000000000000000000"));

      const slot0 = await pool.slot0();

      const tickLower = slot0.tick - (slot0.tick % tickSpacing[fee]);
      const tickUpper = tickLower + tickSpacing[fee];
      const mintParams = {
        token0: isHBTToken0 ? hbtToken.address : wETHAddress,
        token1: isHBTToken0 ? wETHAddress : hbtToken.address,
        fee: fee,
        tickUpper: tickUpper,
        tickLower: tickLower,
        amount0Desired: isHBTToken0 ? ethers.BigNumber.from("1000000000000000000000") : ethers.BigNumber.from("1000000000000000000"),
        amount1Desired: isHBTToken0 ? ethers.BigNumber.from("1000000000000000000") : ethers.BigNumber.from("1000000000000000000000"),
        amount0Min: 0,
        amount1Min: 0,
        recipient: signer.address,
        deadline: block.timestamp + 100000
      };

      const [tokenId, liquidity, amount0, amount1] = await nfPositionManager.callStatic.mint(mintParams);

      // check the correctness of calculations
      const sqrtPriceX96 = await positionValueTest.getSqrtRatioAtTick(slot0.tick);
      expect(slot0.sqrtPriceX96).to.eq(sqrtPriceX96)

      const [amount0Principal, amount1Principal] = await positionValueTest.principal(tickLower, tickUpper, liquidity, sqrtPriceX96);
      // here we add 1 to amounts, because pool.mint uses different math then nfPositionManager
      // and roundingUp if liquidity > 0 and don't if liquidity < 0
      // now we don't need exact precision
      expect(amount0Principal.add(1)).to.eq(amount0);
      expect(amount1Principal.add(1)).to.eq(amount1);
    }

  });

  it('Should stake nfPosition correct', async function () {
    this.timeout(0);
    const nftsTester1 = await getNFTs(tester1);
    //const nftsTester2 = await getNFTs(tester2);

    const stakeContractTester1 = stakeContractERC20UniV3.connect(tester1);
    //const stakeContractTester2 = stakeContractERC20UniV3.connect(tester2);
    const nfPositionManagerTester1 = nfPositionManager.connect(tester1);
    //const nfPositionManagerTester2 = nfPositionManager.connect(tester2);

    for (let i = 0; i < nftsTester1.inRange.length; i++) {
      // staking in range
      await nfPositionManagerTester1.approve(stakeContractTester1.address, nftsTester1.inRange[i].tokenId);
      await stakeContractTester1.stakeUniV3NFTPosition(nftsTester1.inRange[i].tokenId);
      // calculate amount of hbt token if position would be hbt token liquidity only
      // change current price to become out of range
      const sqrtPrice = isHBTToken0 ? await positionValueTest.getSqrtRatioAtTick(nftsTester1.inRange[i].tickLower - nftsTester1.inRange[i].tickSpacing) : await positionValueTest.getSqrtRatioAtTick(nftsTester1.inRange[i].tickUpper + nftsTester1.inRange[i].tickSpacing);
      const [amount0Principal, amount1Principal] = await positionValueTest.principal(nftsTester1.inRange[i].tickLower, nftsTester1.inRange[i].tickUpper, nftsTester1.inRange[i].liquidity, sqrtPrice);
      const votingPowerAmountForNFT = await stakeContractTester1.getAmountOfVotingPowerForNFTPosition(nftsTester1.inRange[i].tokenId);

      if (isHBTToken0) {
        expect(amount0Principal).to.eq(votingPowerAmountForNFT);
      } else {
        expect(amount1Principal).to.eq(votingPowerAmountForNFT);
      }

      // trying to stake out of range - should revert if only pair token liquidity and stake if only hbt liquidity
      if (!isHBTToken0) {
        // here is only token pair liquidity - should revert
        await nfPositionManagerTester1.approve(stakeContractTester1.address, nftsTester1.onlyToken0[i].tokenId);
        await expect(stakeContractTester1.stakeUniV3NFTPosition(nftsTester1.onlyToken0[i].tokenId)).to.be.revertedWith('Only pair token liquidity is not accepted yet.');

        // here is only hbt liquidity - should stake
        await nfPositionManagerTester1.approve(stakeContractTester1.address, nftsTester1.onlyToken1[i].tokenId);
        await stakeContractTester1.stakeUniV3NFTPosition(nftsTester1.onlyToken1[i].tokenId);

        const tick = 69081; // little cheating
        const sqrtPrice = await positionValueTest.getSqrtRatioAtTick(tick);
        const [amount0Principal, amount1Principal] = await positionValueTest.principal(nftsTester1.onlyToken1[i].tickLower, nftsTester1.onlyToken1[i].tickUpper, nftsTester1.onlyToken1[i].liquidity, sqrtPrice);
        const votingPowerAmountForNFT = await stakeContractTester1.getAmountOfVotingPowerForNFTPosition(nftsTester1.onlyToken1[i].tokenId);
        expect(votingPowerAmountForNFT).to.eq(amount1Principal);

      } else {
        // here is only token pair liquidity - should revert
        await nfPositionManagerTester1.approve(stakeContractTester1.address, nftsTester1.onlyToken1[i].tokenId);
        await expect(stakeContractTester1.stakeUniV3NFTPosition(nftsTester1.onlyToken1[i].tokenId)).to.be.revertedWith('Only pair token liquidity is not accepted yet.');

        // here is only hbt liquidity - should stake
        await nfPositionManagerTester1.approve(stakeContractTester1.address, nftsTester1.onlyToken0[i].tokenId);
        await stakeContractTester1.stakeUniV3NFTPosition(nftsTester1.onlyToken0[i].tokenId);
        const tick = 69081; // little cheating
        const sqrtPrice = await positionValueTest.getSqrtRatioAtTick(tick);
        const [amount0Principal, amount1Principal] = await positionValueTest.principal(nftsTester1.onlyToken0[i].tickLower, nftsTester1.onlyToken0[i].tickUpper, nftsTester1.onlyToken0[i].liquidity, sqrtPrice);
        const votingPowerAmountForNFT = await stakeContractTester1.getAmountOfVotingPowerForNFTPosition(nftsTester1.onlyToken0[i].tokenId);
        expect(votingPowerAmountForNFT).to.eq(amount0Principal);
      }
    }
  });

  async function getNFTs(beneficiar) {
    await hbtToken.transfer(beneficiar.address, ethers.BigNumber.from("100000000000000000000000"));

    const hbtTokenNS = hbtToken.connect(beneficiar);
    const wethNS = weth.connect(beneficiar);
    const nfPositionManagerNS = nfPositionManager.connect(beneficiar);
    await hbtTokenNS.approve(nfPositionManagerNS.address, ethers.BigNumber.from("100000000000000000000000"));

    await wethNS.deposit({value: ethers.BigNumber.from("50000000000000000000")});
    await wethNS.approve(nfPositionManagerNS.address, ethers.BigNumber.from("50000000000000000000"));
    const block = await ethers.provider.getBlock();

    const mintParams = {
      token0: isHBTToken0 ? hbtToken.address : wethNS.address,
      token1: isHBTToken0 ? wethNS.address : hbtToken.address,
      amount0Min: 0,
      amount1Min: 0,
      recipient: beneficiar.address,
      deadline: block.timestamp + 100000
    };
    const oneETH = ethers.BigNumber.from("1000000000000000000");
    const oneKHBT = ethers.BigNumber.from("1000000000000000000000");

    const nfts = {
      "inRange": [],
      "onlyToken0": [],
      "onlyToken1": []
    };
    for (fee in pools) {
      const pool = new ethers.Contract(pools[fee], uniswapV3PoolABI.abi, beneficiar);
      const slot0 = await pool.slot0();
      const tickLowerClosest = slot0.tick - (slot0.tick % tickSpacing[fee]);
      // in range
      const tickLowerR = tickLowerClosest - (tickSpacing[fee] * Math.floor(Math.random() * 100));
      const tickUpperR = tickLowerClosest + (tickSpacing[fee] * (1 + Math.floor(Math.random() * 100)))
      // onlyToken0
      let r = (1 + Math.floor(Math.random() * 100));
      const tickLower0 = tickLowerClosest + (tickSpacing[fee] * r);
      const tickUpper0 = tickLowerClosest + (tickSpacing[fee] * 2 * r);
      //onlyToken1
      r = (1 + Math.floor(Math.random() * 100));
      const tickLower1 = tickLowerClosest - (tickSpacing[fee] * 2 * r);
      const tickUpper1 = tickLowerClosest - (tickSpacing[fee] * r);
      mintParams.fee = fee;
      mintParams.amount0Desired = isHBTToken0 ? oneKHBT.mul((1 + Math.floor(Math.random() * 10))) : oneETH.mul((1 + Math.floor(Math.random() * 5)));
      mintParams.amount1Desired = isHBTToken0 ? oneETH.mul((1 + Math.floor(Math.random() * 5))) : oneKHBT.mul((1 + Math.floor(Math.random() * 10)));

      // mint in range
      let nfToken = await mintToken(nfPositionManagerNS, mintParams, tickLowerR, tickUpperR, tickSpacing[fee]);
      nfts.inRange.push(nfToken);

      // mint onlyToken0
      nfToken = await mintToken(nfPositionManagerNS, mintParams, tickLower0, tickUpper0, tickSpacing[fee]);
      nfts.onlyToken0.push(nfToken);

      // mint onlyToken1
      nfToken = await mintToken(nfPositionManagerNS, mintParams, tickLower1, tickUpper1, tickSpacing[fee]);
      nfts.onlyToken1.push(nfToken);
    }

    return nfts;
  }

  async function mintToken(nfPositionManager, mintParams, tickLower, tickUpper, tickSpacing) {
    mintParams.tickLower = tickLower;
    mintParams.tickUpper = tickUpper;
    const [tokenId, liquidity, amount0, amount1] = await nfPositionManager.callStatic.mint(mintParams);
    await nfPositionManager.mint(mintParams);

    return {
      tokenId,
      tickSpacing,
      tickLower: tickLower,
      tickUpper: tickUpper,
      liquidity,
      amount0,
      amount1
    }
  }
});
