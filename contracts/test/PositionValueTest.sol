// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibUniswapV3Math} from "../libraries/helpers/LibUniswapV3Math.sol";

contract PositionValueTest {

  function getSqrtRatioAtTick(int24 tick) external pure returns(uint160 sqrtPriceX96) {
    return LibUniswapV3Math.getSqrtRatioAtTick(tick);
  }

  function principal(
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint160 sqrtRatioX96
  ) external pure returns (uint256 amount0, uint256 amount1) {
      return
          LibUniswapV3Math.getAmountsForLiquidity(
              sqrtRatioX96,
              LibUniswapV3Math.getSqrtRatioAtTick(tickLower),
              LibUniswapV3Math.getSqrtRatioAtTick(tickUpper),
              liquidity
      );
  }

}
