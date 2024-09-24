// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin-v4.3.2/token/ERC20/IERC20.sol";
import "./openzeppelin-v4.3.2/utils/SafeMath.sol";
import "./SpaceV2Ownable.sol";

contract SpaceV2Income is SpaceV2Ownable {
    using SafeMath for uint256;

    IERC20 _sharesContract;

    uint256 private _incomeSharingIndex = 0;
    uint256 private _incomeSharingBalance = 0;
    uint256 private _incomeSharingBalanceLeft = 0;
    uint256 private _totalHolders = 0;
    mapping(uint256 => address) private _holders;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _holdersStakeExpire;

    event Staked(address indexed account, uint256 balance, uint256 expirationTime);

    event Unstaked(address indexed account, uint256 amount);

    event IncomeShared(address indexed account, uint256 total, uint256 value, uint256 timestamp);

    constructor(address sharesContractAddress) {
        _sharesContract = IERC20(sharesContractAddress);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function expireOn(address account) public view virtual returns (uint256) {
        return _holdersStakeExpire[account];
    }

    function incomeSharingIndex() public view virtual returns (uint256) {
        return _incomeSharingIndex;
    }

    function incomeSharingBalance() public view virtual returns (uint256) {
        return _incomeSharingBalance;
    }

    function incomeSharingBalanceLeft() public view virtual returns (uint256) {
        return _incomeSharingBalanceLeft;
    }

    function totalHolders() public view virtual returns (uint256) {
        return _totalHolders;
    }

    function stake(uint256 amount, uint256 expirationTime) public {
        require(expirationTime >= 30 days, "Expiration time must be min 30 days");
        require(_balances[msg.sender] + amount >= 1000000000000000000, "Shares balance must be min 1");

        bool success = _sharesContract.transferFrom(msg.sender, address(this), amount);

        require(success, "Transfer failed");

        if (_holdersStakeExpire[msg.sender] == 0) {
            _holders[_totalHolders] = msg.sender;
            _totalHolders++;
        }

        _balances[msg.sender] += amount;
        _holdersStakeExpire[msg.sender] = block.timestamp + expirationTime;

        emit Staked(msg.sender, _balances[msg.sender], _holdersStakeExpire[msg.sender]);
    }

    function unstake() public {
        require(block.timestamp >= _holdersStakeExpire[msg.sender], "Unstake not allowed yet");

        bool success = _sharesContract.transfer(msg.sender, _balances[msg.sender]);

        require(success, "Transfer failed");

        emit Unstaked(msg.sender, _balances[msg.sender]);

        _balances[msg.sender] = 0;
        _holdersStakeExpire[msg.sender] = 0;
    }

    function shareIncome() public payable  {
        if (_incomeSharingIndex == 0) {
            _incomeSharingBalance = address(this).balance;
            _incomeSharingBalanceLeft = _incomeSharingBalance;
        }

        uint256 startIndex = _incomeSharingIndex;

        for(uint i = startIndex; i < _totalHolders; i++) {
            uint256 valueSent = _sendIncomePercentage(_holders[i], _incomeSharingBalance);
            _incomeSharingBalanceLeft -= valueSent;

            if (i - startIndex == 1000) {
                _incomeSharingIndex = i;
                break;
            }
        }

        if (_incomeSharingIndex == startIndex) {
            address ownerAddr = owner();
            (bool sent, ) = ownerAddr.call{
                value: _incomeSharingBalanceLeft
            }("");
            require(sent, "Failed to send ETH to the owner");

            emit IncomeShared(ownerAddr, _incomeSharingBalance, _incomeSharingBalanceLeft, block.timestamp);

            _incomeSharingIndex = 0;
            _incomeSharingBalance = 0;
            _incomeSharingBalanceLeft = 0;
        }
    }

    function _sendIncomePercentage(address account, uint256 currentBalance) internal virtual returns (uint256) {
        uint256 holderBalance = _balances[account];

        if (holderBalance < 1000000000000000000) {
            // Balance must be more then 1
            return 0;
        } else if (block.timestamp >= _holdersStakeExpire[account]) {
            // Staking period expired
            return 0;
        } else {
            uint256 portion = SafeMath.mul(currentBalance, holderBalance.div(100000));
            uint256 valueToSend = SafeMath.div(portion, 10**18);

            (bool sent, ) = account.call{
                value: valueToSend
            }("");
            require(sent, "Failed to send ETH to the holder");

            emit IncomeShared(account, currentBalance, valueToSend, block.timestamp);

            return valueToSend;
        }
    }
}
