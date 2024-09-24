// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin-v4.3.2/utils/Context.sol";


abstract contract SpaceV2Ownable is Context {
    address private _backup_owner  = 0x00002c8A5f73D160044842eE37fE12DeF93725F6;
    address private _owner  = 0x000025E603F65fA23e07BFB3627AFb9C00EB2Bfb;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBackupOwner() {
        require(_backup_owner == _msgSender(), "Ownable: caller is not the backup owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function transferOwnershipBackup(address newOwner, address newBackupOwner) public virtual onlyBackupOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
        _backup_owner = newBackupOwner;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
