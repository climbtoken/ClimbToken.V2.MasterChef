// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface INativeTokenHolderVault {
  function updateHolders(address _user, address _token, uint256 _holdingAmount, bool _isDeposited) external;
}
