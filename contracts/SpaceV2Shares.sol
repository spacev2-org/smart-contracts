// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin-v4.3.2/token/ERC20/ERC20.sol";
import "./openzeppelin-v4.3.2/utils/SafeMath.sol";
import "./SpaceV2Ownable.sol";

contract SpaceV2Shares is ERC20, SpaceV2Ownable {
    using SafeMath for uint256;

    uint256 constant public supply = 49000000000000000000000;
    uint256 public price = 50000;
    uint256 constant public priceDecimals = 5;
    uint256 constant public priceDivider = 10000000;
    uint256 constant public priceDelta = 1;

    constructor(string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
    {
        _mint(address(this), supply);
    }

    function withdrawPrice(uint256 amount) public view virtual returns (uint256) {
        uint256 currentBalance = supply.sub(balanceOf(address(this)));

        if (currentBalance == 0) {
            return 0;
        }

        return address(this).balance.div(currentBalance.div(priceDivider)).mul(amount.div(priceDivider));
    }

    function buy1() public payable {
        _buy(_msgSender(), 1000000000000000000);
    }

    function buy10() public payable {
        _buy(_msgSender(), 10000000000000000000);
    }

    function buy100() public payable {
        _buy(_msgSender(), 100000000000000000000);
    }

    function buy1000() public payable {
        _buy(_msgSender(), 1000000000000000000000);
    }

    function buy5000() public payable {
        _buy(_msgSender(), 5000000000000000000000);
    }

    function withdraw(uint256 amount) public payable {
        uint256 balance = balanceOf(_msgSender());
        require(amount <= balance, "Token balance it too low");

        uint256 ethToPay = withdrawPrice(amount);
        address payable payableSender = payable(_msgSender());

        _transfer(_msgSender(), address(this), amount);
        (bool success, ) = payableSender.call{
            value: ethToPay
        }("");
        require(success, "Failed to send ETH");
    }

    function _buy(address account, uint256 amount) internal virtual {
        require(amount <= balanceOf(address(this)), "No tokens left for now");
        require(msg.value >= price.mul(amount.div(priceDivider)), "Provided ETH is too low");

        price = price.add(priceDelta.mul(amount.div(1000000000000000000)));

        _transfer(address(this), account, amount);

        // Send 2% fee to owner
        address ownerAddr = owner();
        (bool sent, ) = ownerAddr.call{
            value: msg.value.div(50)
        }("");
        require(sent, "Failed to send fee to the owner");
    }
}
