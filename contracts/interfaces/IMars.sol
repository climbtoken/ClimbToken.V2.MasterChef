// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IMars {
  function mint(address _to, uint256 _amount) external;
  function transfer(address _to, uint256 _amount) external;
  function balanceOf(address user) external returns (uint256);
}
