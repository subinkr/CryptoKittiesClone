// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./KittyAuction.sol";

contract KittyMinting is KittyAuction {
    uint256 public promoCreationLimit = 5000;
    uint256 public gen0CreationLimit = 50000;

    uint256 public gen0StartingPrice = 0.01 ether;
    uint256 public gen0AuctionDuration = 1 days;

    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    function createPromoKitty(uint256 _genes, address _owner) public onlyCOO {
        if(_owner == address(0)) {
            _owner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);
        require(gen0CreatedCount < gen0CreationLimit);

        promoCreatedCount++;
        gen0CreatedCount++;
        _createKitty(0, 0, 0, _genes, _owner);
    }

    function createGen0Auction(uint256 _genes) public onlyCOO {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 kittyId = _createKitty(0, 0, 0, _genes, address(this));
        _approve(address(saleAuction), kittyId);

        saleAuction.createAuction(
            kittyId,
            _computerNextGen0Price(),
            0,
            gen0AuctionDuration,
            address(this)
        );
        gen0CreatedCount++;
    }

    function _computerNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

        if(nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}
