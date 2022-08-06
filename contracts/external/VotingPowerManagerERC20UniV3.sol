// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import {LibUniswapV3Math} from "../libraries/helpers/LibUniswapV3Math.sol";
import {IERC20} from "../libraries/openzeppelin/IERC20.sol";
import {SafeERC20} from "../libraries/openzeppelin/SafeERC20.sol";
import {IVotingPower} from "../interfaces/IVotingPower.sol";

struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the most-recently updated index of the observations array
    uint16 observationIndex;
    // the current maximum number of observations that are being stored
    uint16 observationCardinality;
    // the next maximum number of observations to store, triggered in observations.write
    uint16 observationCardinalityNext;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
    // whether the pool is locked
    bool unlocked;
}

interface IUniV3Pool {
  function slot0() external returns(Slot0 memory);
}

interface INFPositionManager {
  function factory() external returns(address);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

struct PositionData {
  address operator;
  address token0;
  address token1;
  int24 tickLower;
  int24 tickUpper;
  uint24 fee;
  uint128 liquidity;
}

struct PositionReturnedData {
  uint96 nonce;
  address operator;
  address token0;
  address token1;
  uint24 fee;
  int24 tickLower;
  int24 tickUpper;
  uint128 liquidity;
  uint256 feeGrowthInside0LastX128;
  uint256 feeGrowthInside1LastX128;
  uint128 tokensOwed0;
  uint128 tokensOwed;
}

contract StakeContractERC20UniV3 {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  IVotingPower votingPowerHolder;
  INFPositionManager nfPositionManager;
  address uniV3Factory;
  address governanceToken;
  EnumerableSet.AddressSet legalPairTokens;
  // staker => staked amount
  mapping(address => uint256) private _stakedERC20GovToken;
  // Mapping from staker address to their (enumerable) set of staked NFtokens
  mapping (address => EnumerableSet.UintSet) private _stakerNFTPositions;
  // nftPositionTokenID => votingPower
  mapping(uint256 => uint256) private _amountOfVotingPowerForNFTPosition;

  // prerequisites - all uniV3 pools for each pair token and fee must be initialized
  constructor(
    address _votingPowerHolder,
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) {
    require(_votingPowerHolder != address(0)); // diamond address
    require(_nfPositionManager != address(0));
    votingPowerHolder = IVotingPower(_votingPowerHolder);
    nfPositionManager = INFPositionManager(_nfPositionManager);
    uniV3Factory = nfPositionManager.factory();
    governanceToken = _governanceToken;
    uint amountOfPairTokens = _legalPairTokens.length;
    require(amountOfPairTokens > 0 && amountOfPairTokens < 10, "No pair token is set for pool or more than 9.");
    for (uint i = 0; i < amountOfPairTokens; i++) {
      legalPairTokens.add(_legalPairTokens[i]);
    }
  }

  // should give token approval before call
  function stakeGovToken(uint256 _amount) public {
    // receive tokens from holder to stake contract
    IERC20(governanceToken).safeTransferFrom(msg.sender, address(this), _amount); // double check
    // account how much holders tokens are staked
    _stakedERC20GovToken[msg.sender] += _amount;
    // give voting power
    votingPowerHolder.increaseVotingPower(msg.sender, _amount);
  }

  function unstakeGovToken(uint256 _amount) public {
    require(
      _stakedERC20GovToken[msg.sender] >= _amount,
      "Trying to unstake more than have."
    );
    // reduce token holdings
    _stakedERC20GovToken[msg.sender] -= _amount;
    // take back voting power
    votingPowerHolder.decreaseVotingPower(msg.sender, _amount);
    // transfer tokens from stake contract to holder
    IERC20(governanceToken).safeTransfer(msg.sender, _amount);
  }
  // first have to approve (make operator = address(this))

  function stakeUniV3NFTPosition(uint256 tokenId) public {
    require(nfPositionManager.ownerOf(tokenId) == msg.sender, "Not an owner of NFT position.");

    (bool suc, bytes memory data) = address(nfPositionManager).call(abi.encodeWithSelector(0x99fbab88, tokenId));
    require(suc);
    PositionData memory positionData = convertToPositionData(data);

    require(positionData.operator == address(this), "No approval to stake.");
    require(positionData.token0 == governanceToken || positionData.token1 == governanceToken, "No governance token in underlying assets.");
    address pairToken = positionData.token0 == governanceToken ? positionData.token1 : positionData.token0;
    require(legalPairTokens.contains(pairToken), "No legal pair token in underlying assets.");
    address pool = LibUniswapV3Math.computePoolAddress(uniV3Factory, positionData.token0, positionData.token1, positionData.fee);
    Slot0 memory slot0 = IUniV3Pool(pool).slot0();

    uint160 sqrtRatioAX96 = LibUniswapV3Math.getSqrtRatioAtTick(positionData.tickLower);
    uint160 sqrtRatioBX96 = LibUniswapV3Math.getSqrtRatioAtTick(positionData.tickUpper);
    uint256 amountOfVotingPower;
    if (slot0.tick < positionData.tickLower) {
      if (positionData.token0 == governanceToken) {
        // here all position is HBT
        // amount0
        amountOfVotingPower = LibUniswapV3Math.getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, positionData.liquidity);
      } else {
        // now we don't accept only WETH (other pair token) positions
        revert("Only pair token liquidity is not accepted yet.");
      }
    } else if (slot0.tick < positionData.tickUpper) {
      // here in range
      // we don't calcute the amount0 and amount1, instead we calculate amount if position would be out of range and contain only governanceToken
      if (positionData.token0 == governanceToken) {
        amountOfVotingPower = LibUniswapV3Math.getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, positionData.liquidity);
      } else {
        amountOfVotingPower = LibUniswapV3Math.getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, positionData.liquidity);
      }
    } else {
      if (positionData.token0 == governanceToken) {
        // now we don't accept only WETH (other pair token) positions
        revert("Only pair token liquidity is not accepted yet.");
      } else {
        // here all position is HBT
        // amount1
        amountOfVotingPower = LibUniswapV3Math.getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, positionData.liquidity);
      }
    }
    // receive token from holder to stake contract
    nfPositionManager.safeTransferFrom(msg.sender, address(this), tokenId);
    // account ownership of the staked token
    _stakerNFTPositions[msg.sender].add(tokenId);
    // account how much voting power token is cost
    _amountOfVotingPowerForNFTPosition[tokenId] = amountOfVotingPower;

    // give voting power
    votingPowerHolder.increaseVotingPower(msg.sender, amountOfVotingPower);
  }

  function unstakeUniV3NFTPosition(uint256 tokenId) public {
    require(_stakerNFTPositions[msg.sender].contains(tokenId), "tokenId was not staked by msg.sender");

    // remove token from holdings
    _stakerNFTPositions[msg.sender].remove(tokenId);
    // take back voting power
    uint256 amountOfVotingPowerForNFT = _amountOfVotingPowerForNFTPosition[tokenId];
    votingPowerHolder.decreaseVotingPower(msg.sender, amountOfVotingPowerForNFT);
    // no sense to store, because liquidity can be increased and decreased outside
    _amountOfVotingPowerForNFTPosition[tokenId] = 0;

    // transfer tokens from stake contract to holder
    nfPositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  function stakeMultipleUniV3NFTPositions(uint256[] memory tokenIds) external {
    require(tokenIds.length < 100);
    for (uint i = 0; i < tokenIds.length; i++) {
      stakeUniV3NFTPosition(tokenIds[i]);
    }
  }

  function unStakeMultipleUniV3NFTPositions(uint256[] memory tokenIds) external {
    require(tokenIds.length < 100);
    for (uint i = 0; i < tokenIds.length; i++) {
      unstakeUniV3NFTPosition(tokenIds[i]);
    }
  }

  function increaseVotingPowerByIncreasingLiquidityOfNFTPosition(uint256 tokenId) external {
    revert("not implemented yet.");
  }

  function decreaseVotingPowerByDecreasingLiquidityOfNFTPosition(uint256 tokenId) external {
    revert("not implemented yet.");
  }

  function collectFeesFromNFTPosition(uint256 tokenId) external {
    revert("not implemented yet.");
  }

  // Internal functions
  function convertToPositionData(bytes memory data) internal pure returns(PositionData memory) {
    PositionReturnedData memory prd = abi.decode(data, (PositionReturnedData));

    return PositionData({
      operator: prd.operator,
      token0: prd.token0,
      token1: prd.token1,
      tickLower: prd.tickLower,
      tickUpper: prd.tickUpper,
      liquidity: prd.liquidity,
      fee: prd.fee
    });

  }

  // View functions

  function getStakedBalanceOfGovernanceToken(address holder)
    external
    view
    returns (uint256 balance)
  {
    balance = _stakedERC20GovToken[holder];
  }

  function getAmountOfStakedNFTPositions(address holder) public view returns (uint256) {
    require(holder != address(0), "ERC721: balance query for the zero address");
    return _stakerNFTPositions[holder].length();
  }

  function getNFTPositionIdOfHolderByIndex(address holder, uint256 index) public view returns (uint256) {
    return _stakerNFTPositions[holder].at(index);
  }

  function nftPositionIsStakedByHolder(address holder, uint256 tokenId) public view returns(bool) {
    return _stakerNFTPositions[holder].contains(tokenId);
  }

  function getAmountOfVotingPowerForNFTPosition(uint tokenId) external view returns(uint) {
    return _amountOfVotingPowerForNFTPosition[tokenId];
  }

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure returns (bytes4) {
    return 0x150b7a02;
  }
}
