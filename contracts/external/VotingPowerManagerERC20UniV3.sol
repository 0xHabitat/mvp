// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {LibUniswapV3Math} from "../libraries/helpers/LibUniswapV3Math.sol";
import {IERC20} from "../libraries/openzeppelin/IERC20.sol";
import {SafeERC20} from "../libraries/openzeppelin/SafeERC20.sol";
import {IVotingPower} from "../interfaces/decisionSystem/IVotingPower.sol";

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
  function slot0() external returns (Slot0 memory);
}

interface INFPositionManager {
  function factory() external returns (address);

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

/**
 * @title StakeContractERC20UniV3 - Contract is a part of Voting Power Decision System.
 *        Voting Power Manager is a second name. Contract based on its own staking/unstaking
 *        logic controls voting power balances inside DeciderVotingPower contract.
 * @dev Contract stores erc20 contract address named governance token. Provides functions to stake/unstake it
 *      and increases/decreases staker voting power (ratio 1:1) inside voting power decider.
 *      Among with governance token staking, contract provides ability to stake the
 *      derivatives - erc721 tokens minted by uniswap v3 nonfungiblePositionManager,
 *      uniV3 position is valid, if it's underlying tokens are governance token and one from legalPairTokens array.
 *      Voting power cost of position is calculated by modifying position into
 *      a state, when it contains 100% governance and 0% pair tokens, the ratio
 *      between amount of govtoken in such state and voting power is also 1:1.
 * @author @roleengineer
 */
contract StakeContractERC20UniV3 {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  IVotingPower votingPowerHolder;
  INFPositionManager nfPositionManager;
  address uniV3Factory;
  address public governanceToken;
  EnumerableSet.AddressSet legalPairTokens;
  // staker => staked amount
  mapping(address => uint256) private _stakedERC20GovToken;
  // Mapping from staker address to their (enumerable) set of staked NFtokens
  mapping(address => EnumerableSet.UintSet) private _stakerNFTPositions;
  // nftPositionTokenID => votingPower
  mapping(uint256 => uint256) private _amountOfVotingPowerForNFTPosition;

  /**
   * @notice Constructor function sets: nfPositionManager, uniV3Factory, governanceToken, legalPairTokens.
   * @dev Prerequisites: all uniV3 pools for each pair token and fee must be initialized.
   * @param _nfPositionManager UniV3 non-fungible position manager address.
   * @param _governanceToken Address of erc20 token, which is an entry point to get voting power.
   * @param _legalPairTokens Array of addresses (erc20 tokens), which are considered to be a valid pair for uniV3 pool.
   *                         UniV3 positions (erc721 tokens), which has as underlying tokens _governanceToken and one of this array
   *                         are considered to be valid for staking and getting voting power.
   */
  constructor(
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) {
    require(_nfPositionManager != address(0));
    nfPositionManager = INFPositionManager(_nfPositionManager);
    uniV3Factory = nfPositionManager.factory();
    governanceToken = _governanceToken;
    uint256 amountOfPairTokens = _legalPairTokens.length;
    require(
      amountOfPairTokens > 0 && amountOfPairTokens < 10,
      "No pair token is set for pool or more than 9."
    );
    for (uint256 i = 0; i < amountOfPairTokens; i++) {
      legalPairTokens.add(_legalPairTokens[i]);
    }
  }

  /**
   * @notice Sets DeciderVotingPower contract address one time.
   * @dev DeciderVotingPower functions increaseVotingPower/decreaseVotingPower have
   *      requirement to be called only by this contract.
   * @param _votingPowerHolder The address of the DeciderVotingPower contract.
   */
  function setVotingPowerHolder(address _votingPowerHolder) external {
    require(address(votingPowerHolder) == address(0), "VotingPowerHolder is set.");
    votingPowerHolder = IVotingPower(_votingPowerHolder);
  }

  /**
   * @notice Before call account has to approve this contract to spend governance token.
   *         Method transfers governance tokens to this contract and increases account
   *         voting power balance inside DeciderVotingPower (ratio 1:1).
   * @param _amount of governance tokens to be staked.
   * @return Returns amount of voting power staker gets for staked tokens.
   */
  function stakeGovToken(uint256 _amount) public returns (uint256) {
    // receive tokens from holder to stake contract
    IERC20(governanceToken).safeTransferFrom(msg.sender, address(this), _amount);
    // account how much holders tokens are staked
    _stakedERC20GovToken[msg.sender] += _amount;
    // give voting power
    votingPowerHolder.increaseVotingPower(msg.sender, _amount);
    return _amount;
  }

  /**
   * @notice Before call account has to approve this contract to spend governance token.
   *         Method transfers governance tokens to this contract and increases `beneficiary`
   *         voting power balance inside DeciderVotingPower (ratio 1:1).
   *         After call governance tokens belongs to `beneficiary`.
   * @param beneficiary Address which amount of voting power will be increased.
   * @param _amount of governance tokens to be staked.
   */
  function stakeGovInFavorOf(address beneficiary, uint256 _amount) external {
    // receive tokens from holder to stake contract
    IERC20(governanceToken).safeTransferFrom(msg.sender, address(this), _amount);
    // account how much holders tokens are staked
    _stakedERC20GovToken[beneficiary] += _amount;
    // give voting power
    votingPowerHolder.increaseVotingPower(beneficiary, _amount);
  }

  /**
   * @notice Method transfers `_amount` governance tokens to the caller
   *         and decreases caller voting power balance inside DeciderVotingPower (ratio 1:1).
   * @param _amount of governance tokens to be unstaked.
   * @return Returns amount of voting power staker loses after unstaking tokens.
   */
  function unstakeGovToken(uint256 _amount) public returns (uint256) {
    require(_stakedERC20GovToken[msg.sender] >= _amount, "Trying to unstake more than have.");
    // reduce token holdings
    _stakedERC20GovToken[msg.sender] -= _amount;
    // take back voting power
    votingPowerHolder.decreaseVotingPower(msg.sender, _amount);
    // transfer tokens from stake contract to holder
    IERC20(governanceToken).safeTransfer(msg.sender, _amount);
    return _amount;
  }

  /**
   * @notice Before call account has to approve this contract to spend uniV3 NFT (make operator = address(this))
   *         Method transfers uniV3 NFT to this contract and increases
   *         voting power balance inside DeciderVotingPower.
   * @dev See the function _convertUNIV3PositionToVotingPower description which
   *      explains, how the voting power is calculated.
   *      Function accounts ownership of erc721 token to be able to return it on request.
   *      Function also accounts the voting power cost of the position to be able to take it back.
   * @param tokenId the id of erc721 token uniV3 non-fungible position manager contract
   * @return Returns amount of voting power staker gets for staked position.
   */
  function stakeUniV3NFTPosition(uint256 tokenId) public returns (uint256) {
    require(nfPositionManager.ownerOf(tokenId) == msg.sender, "Not an owner of NFT position.");

    (address operator, uint256 amountOfVotingPower) = _convertUNIV3PositionToVotingPower(tokenId);
    require(operator == address(this), "No approval to stake.");

    // receive token from holder to stake contract
    nfPositionManager.safeTransferFrom(msg.sender, address(this), tokenId);
    // account ownership of the staked token
    _stakerNFTPositions[msg.sender].add(tokenId);
    // account how much voting power token is cost
    _amountOfVotingPowerForNFTPosition[tokenId] = amountOfVotingPower;

    // give voting power
    votingPowerHolder.increaseVotingPower(msg.sender, amountOfVotingPower);

    return amountOfVotingPower;
  }

  /**
   * @notice Method transfers uniV3 NFT back to the staker and decreases the voting
   *         power balance inside DeciderVotingPower by the cost of position.
   * @param tokenId the id of erc721 token uniV3 non-fungible position manager contract
   * @return Returns amount of voting power staker loses after unstaking position.
   */
  function unstakeUniV3NFTPosition(uint256 tokenId) public returns (uint256) {
    require(
      _stakerNFTPositions[msg.sender].contains(tokenId),
      "tokenId was not staked by msg.sender"
    );

    // remove token from holdings
    _stakerNFTPositions[msg.sender].remove(tokenId);
    // take back voting power
    uint256 amountOfVotingPowerForNFT = _amountOfVotingPowerForNFTPosition[tokenId];
    votingPowerHolder.decreaseVotingPower(msg.sender, amountOfVotingPowerForNFT);
    // no sense to store, because liquidity can be increased and decreased outside
    _amountOfVotingPowerForNFTPosition[tokenId] = 0;

    // transfer tokens from stake contract to holder
    nfPositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
    return amountOfVotingPowerForNFT;
  }

  /**
   * @notice Before call account has to approve this contract to spend all uniV3 NFT (make operator = address(this))
   *         Function is doing the same as function stakeUniV3NFTPosition for an array of positions.
   * @param tokenIds Array contains ids of erc721 tokens uniV3 non-fungible position manager contract
   * @return Returns amount of voting power staker gets for staked positions.
   */
  function stakeMultipleUniV3NFTPositions(uint256[] memory tokenIds) external returns (uint256) {
    require(tokenIds.length < 100);
    uint256 amountOfVotingPower;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      amountOfVotingPower += stakeUniV3NFTPosition(tokenIds[i]);
    }
    return amountOfVotingPower;
  }

  /**
   * @notice Function is doing the same as function unstakeUniV3NFTPosition for an array of positions.
   * @param tokenIds Array contains ids of erc721 tokens uniV3 non-fungible position manager contract
   * @return Returns amount of voting power staker loses after unstaking positions.
   */
  function unStakeMultipleUniV3NFTPositions(uint256[] memory tokenIds) external returns (uint256) {
    require(tokenIds.length < 100);
    uint256 amountOfVotingPower;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      amountOfVotingPower += unstakeUniV3NFTPosition(tokenIds[i]);
    }
    return amountOfVotingPower;
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

  /**
  * @notice Helper functions to receive uniV3 position data
  * @dev Call function positions(uint256) of uniV3 non-fungible position manager
  *      ends up into stack too deep error, because it returns too many values.
  *      Workaround is to make a raw call.
  *      This function helps to convert raw returned data into workable struct.
  * @param data raw bytes returned by call nfPositionManager positions function
  * @return Struct containing all neccessary data related to uniV3 position
  */
  function convertToPositionData(bytes memory data) internal pure returns (PositionData memory) {
    PositionReturnedData memory prd = abi.decode(data, (PositionReturnedData));

    return
      PositionData({
        operator: prd.operator,
        token0: prd.token0,
        token1: prd.token1,
        tickLower: prd.tickLower,
        tickUpper: prd.tickUpper,
        liquidity: prd.liquidity,
        fee: prd.fee
      });
  }

  /**
   * @notice Function makes the request to nonfungiblePositionManager to get the position data.
   *         Analizing the data: checks the position underlying tokens (must be governance token and one of legalPairTokens).
   *         Getting position pool and current pool tick. Analizing the current position state:
   *         position considered to be valid, if it is in range or out of range containing governance token.
   * @dev Voting power cost of position is calculated by modifying position into
   *      a state, when it contains 100% governance and 0% pair tokens, the ratio
   *      between amount of govtoken in such state and voting power is 1:1.
   * @param tokenId The id of nonfungiblePositionManager erc721 token
   * @return operator Address, which got approval for position
   * @return amountOfVotingPower position current cost in voting power
   */
  function _convertUNIV3PositionToVotingPower(
    uint256 tokenId
  ) internal returns (address operator, uint256 amountOfVotingPower) {
    bytes4 positionsSelector = bytes4(keccak256(bytes("positions(uint256)")));
    (bool suc, bytes memory data) = address(nfPositionManager).call(
      abi.encodeWithSelector(positionsSelector, tokenId)
    );
    require(suc);
    PositionData memory positionData = convertToPositionData(data);

    operator = positionData.operator;

    require(
      positionData.token0 == governanceToken || positionData.token1 == governanceToken,
      "No governance token in underlying assets."
    );
    address pairToken = positionData.token0 == governanceToken
      ? positionData.token1
      : positionData.token0;
    require(legalPairTokens.contains(pairToken), "No legal pair token in underlying assets.");
    address pool = LibUniswapV3Math.computePoolAddress(
      uniV3Factory,
      positionData.token0,
      positionData.token1,
      positionData.fee
    );
    Slot0 memory slot0 = IUniV3Pool(pool).slot0();

    uint160 sqrtRatioAX96 = LibUniswapV3Math.getSqrtRatioAtTick(positionData.tickLower);
    uint160 sqrtRatioBX96 = LibUniswapV3Math.getSqrtRatioAtTick(positionData.tickUpper);

    if (slot0.tick < positionData.tickLower) {
      if (positionData.token0 == governanceToken) {
        // here all position is HBT
        // amount0
        amountOfVotingPower = LibUniswapV3Math.getAmount0ForLiquidity(
          sqrtRatioAX96,
          sqrtRatioBX96,
          positionData.liquidity
        );
      } else {
        // now we don't accept only WETH (other pair token) positions
        revert("Only pair token liquidity is not accepted yet.");
      }
    } else if (slot0.tick < positionData.tickUpper) {
      // here in range
      // calculate the amount0 and amount1
      (uint256 amount0, uint256 amount1) = LibUniswapV3Math.getAmountsForLiquidity(
        slot0.sqrtPriceX96,
        sqrtRatioAX96,
        sqrtRatioBX96,
        positionData.liquidity
      );
      if (positionData.token0 == governanceToken) {
        // amount0 - HBT, amount1 - ETH
        uint256 convertedAmount = LibUniswapV3Math.getAmount0ForAmount1(
          slot0.sqrtPriceX96,
          amount1
        );
        amountOfVotingPower = amount0 + convertedAmount;
      } else {
        // amount0 - eth, amount1 = HBT
        uint256 convertedAmount = LibUniswapV3Math.getAmount1ForAmount0(
          slot0.sqrtPriceX96,
          amount0
        );
        amountOfVotingPower = amount1 + convertedAmount;
      }
    } else {
      if (positionData.token0 == governanceToken) {
        // now we don't accept only WETH (other pair token) positions
        revert("Only pair token liquidity is not accepted yet.");
      } else {
        // here all position is HBT
        // amount1
        amountOfVotingPower = LibUniswapV3Math.getAmount1ForLiquidity(
          sqrtRatioAX96,
          sqrtRatioBX96,
          positionData.liquidity
        );
      }
    }
  }

  // View functions

  /**
   * @notice Function returns the amount of governance tokens staked by `holder`.
   * @param holder Address
   * @return balance Amount of staked governance tokens
   */
  function getStakedBalanceOfGovernanceToken(
    address holder
  ) external view returns (uint256 balance) {
    balance = _stakedERC20GovToken[holder];
  }

  /**
   * @notice Function returns the amount of uniV3 erc721 tokens staked by `holder`.
   * @param holder Address
   * @return Amount of staked uniV3 erc721 tokens
   */
  function getAmountOfStakedNFTPositions(address holder) public view returns (uint256) {
    require(holder != address(0), "ERC721: balance query for the zero address");
    return _stakerNFTPositions[holder].length();
  }

  /**
   * @notice Function returns an uniV3 erc721 token ID staked by `holder`
   *         at a given `index` of its staked token list.
   * @param holder Address
   * @param index The index in staked token list.
   * @return The id of uniV3 erc721 token.
   */
  function getNFTPositionIdOfHolderByIndex(
    address holder,
    uint256 index
  ) public view returns (uint256) {
    return _stakerNFTPositions[holder].at(index);
  }

  /**
   * @notice Function returns an array of uniV3 erc721 token IDs staked by `holder`.
   * @param holder Address
   * @return An array containing uniV3 erc721 token IDs.
   */
  function getAllNFTPositionIdsOfHolder(address holder) public view returns (uint256[] memory) {
    return _stakerNFTPositions[holder].values();
  }

  /**
   * @notice Function Returns true if `holder` staked `tokenId`.
   * @param holder Address
   * @param tokenId The id of uniV3 erc721 token.
   * @return True if `holder` staked `tokenId`.
   */
  function nftPositionIsStakedByHolder(address holder, uint256 tokenId) public view returns (bool) {
    return _stakerNFTPositions[holder].contains(tokenId);
  }

  /**
   * @notice Function Returns the staked position cost in voting power.
   * @dev If erc721 token is not staked returns 0.
   * @param tokenId The id of uniV3 erc721 token.
   * @return The staked position cost in voting power.
   */
  function getAmountOfVotingPowerForNFTPosition(uint256 tokenId) external view returns (uint256) {
    return _amountOfVotingPowerForNFTPosition[tokenId];
  }

  /**
   * @dev Support safeTransfers from ERC721 asset contract (nonfungiblePositionManager).
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure returns (bytes4) {
    return 0x150b7a02;
  }

  /**
   * @notice View function for multicall contract.
   * @dev Do not make tx calling the function
   * @param tokenId The id of nonfungiblePositionManager token
   * @return Returns position operator
   * @return Returns amount of voting power staker gets for staked position
   */
  function isUniV3NFTValidView(uint256 tokenId) external returns (address, uint256) {
    return _convertUNIV3PositionToVotingPower(tokenId);
  }
}
