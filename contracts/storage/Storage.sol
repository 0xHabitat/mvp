// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Storage {

  struct Repo {
    address[] commits;
  }

  struct Account {
    // upgrade names => repo (upgrade contracts / commit addresses);
    mapping(string => Repo) repo;
  }
  
  struct Layout {
    //owner => registration info
    mapping(address => Account) account;
  }

  bytes32 internal constant STORAGE_SLOT =
      keccak256('ontap.git.storage');

  event Commit (
    address owner,
    string name,
    address upgrade
  );

  function layout() internal pure returns (Layout storage l) {
      bytes32 slot = STORAGE_SLOT;
      assembly {
          l.slot := slot
      }
  }

  function commit(
    Layout storage l,
    address owner,
    string memory name,
    address upgrade
  ) internal {
    address[] storage c = l.account[owner].repo[name].commits;
    c.push(upgrade);
    emit Commit(owner, name, upgrade);
  }

  function latest(
    Layout storage l,
    address owner, 
    string memory name
  ) internal view returns (address) {
    address[] storage c = l.account[owner].repo[name].commits;
    require(c.length > 0, 'Ontap: no upgrades available.');
    uint256 i = c.length - 1;
    return c[i];
  }
}
