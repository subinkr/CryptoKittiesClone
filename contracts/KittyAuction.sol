// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./KittyOwnership.sol";
import "./Auction/ClockAuction.sol";
import "./Auction/SaleClockAuction.sol";

contract KittyAuction is KittyOwnership {
    SaleClockAuction public saleAuction;

    function setSaleAuctionAddress(address _address) public onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(
            payable(_address)
        );

        require(candidateContract.isSaleClockAuction());

        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _kittyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) public whenNotPaused {
        require(_owns(msg.sender, _kittyId));
        _approve(address(saleAuction), _kittyId);

        saleAuction.createAuction(
            _kittyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function withdrawAuctionBalances() external onlyCOO {
        saleAuction.withdrawBalance();
    }
}
