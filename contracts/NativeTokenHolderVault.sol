// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NativeTokenHolderVault is Ownable {
  using SafeMath for uint256;

  address public climb = 0x2a1d286ed5edad78befd6e0d8beb38791e8cd69d;
  address public mntn = 0xa7fcb2baabda9db593e24b25a1a32bfb5168018b;
  address public mars = 0xf1a71bcce29b598d812a30baedff860a7dce0aff;

  address[] private climbHolders;
  address[] private marsHolders;
  address[] private mntnHolders;

  address private operator;

  modifier isOperator() {
    require(operator == msg.sender, 'NativeTokenHolderVault: wrong operator');
    _;
  }
  
  constructor() public {
    operator = msg.sender;
  }

  function getClimbHolders() public view returns (address[] memory) {
      return climbHolders;
  }

  function getMarsHolders() public view returns (address[] memory) {
      return marsHolders;
  }

  function getMntnHolders() public view returns (address[] memory) {
      return mntnHolders;
  }

  function getIndexInClimbHolders(address _user) public view returns (uint) {
    uint index = 1e27;
    for (uint i = 0; i < climbHolders.length; i++) {
      if (_user == climbHolders[i]) {
        index = i;
      }
    }
    return index;
  }

  function getIndexInMarsHolders(address _user) public view returns (uint) {
    uint index = 1e27;
    for (uint i = 0; i < marsHolders.length; i++) {
      if (_user == marsHolders[i]) {
        index = i;
      }
    }
    return index;
  }

  function getIndexInMntnHolders(address _user) public view returns (uint) {
    uint index = 1e27;
    for (uint i = 0; i < mntnHolders.length; i++) {
      if (_user == mntnHolders[i]) {
        index = i;
      }
    }
    return index;
  }

  // should be called by owner (masterchef)
  function updateHolders(
      address _user,
      address _token,
      uint256 _holdingAmount,
      bool _isDeposited
  ) public isOperator {
    if (_token == climb) {
      if (_holdingAmount == 0) {
        if (_isDeposited) {
          climbHolders.push(_user);
        } else {
          uint256 userIndexInHolders = getIndexInClimbHolders(_user);
          if (userIndexInHolders != 1e27) {
              _removeUserFromClimbHolders(userIndexInHolders);
          }
        }
      }
    }
    if (_token == mntn) {
      if (_holdingAmount == 0) {
        if (_isDeposited) {
          mntnHolders.push(_user);
        } else {
          uint256 userIndexInHolders = getIndexInMntnHolders(_user);
          if (userIndexInHolders != 1e27) {
            _removeUserFromMntnHolders(userIndexInHolders);
          }
        }
    }
    }
    if (_token == mars) {
      if (_holdingAmount == 0) {
        if (_isDeposited) {
          marsHolders.push(_user);
        } else {
          uint256 userIndexInHolders = getIndexInMarsHolders(_user);
          if (userIndexInHolders != 1e27) {
            _removeUserFromMarsHolders(userIndexInHolders);
          }
        }
      }
    }
  }

  function setClimbAddress(address _climb) public onlyOwner {
    climb = _climb;
  }

  function setMarsAddress(address _mars) public onlyOwner {
    mars = _mars;
  }

  function setMntnAddress(address _mntn) public onlyOwner {
    mntn = _mntn;
  }

  function setOperator(address _operator) public isOperator {
    operator = _operator;
  }

  function _removeUserFromClimbHolders(uint _index) internal {
    for (uint i = _index; i < climbHolders.length - 1; i++) {
      climbHolders[i] = climbHolders[i + 1];
    }
    climbHolders.pop();
  }

  function _removeUserFromMarsHolders(uint _index) internal {
    for (uint i = _index; i < marsHolders.length - 1; i++) {
      marsHolders[i] = marsHolders[i + 1];
    }
    marsHolders.pop();
  }

  function _removeUserFromMntnHolders(uint _index) internal {
    for (uint i = _index; i < mntnHolders.length - 1; i++) {
      mntnHolders[i] = mntnHolders[i + 1];
    }
    mntnHolders.pop();
  }
}
