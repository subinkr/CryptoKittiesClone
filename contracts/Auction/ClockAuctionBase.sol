// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract ClockAuctionBase is ERC721Holder {
    struct Auction {
        address seller;

        uint128 startingPrice;
        uint128 endingPrice;

        uint64 duration;
        uint64 startedAt;
    }

    IERC721 public nonFungibleContract;

    uint256 public ownerCut;
    mapping(uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    fallback() external {}

    modifier canBeStoreWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615, "_value exceeds 64 bits limit");
        _;
    }

    modifier canBeStoreWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455, "_value exceeds 128 bits limit");
        _;
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(_owner, address(this), _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction memory _auction) internal {
        require(_auction.duration >= 1 minutes, "auction duration should be greater than or equal to 1 minutes");

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount) internal returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction), "this _tokenId is not on the auction");

        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price, "_bidAmount should be greater than or equal to auction's current price");

        address seller = auction.seller;

        _removeAuction(_tokenId);

        if(price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

            (bool success, ) = payable(seller).call{ value: sellerProceeds }("");
            require(success, "Failed to send sellerProceeds to seller");
        }

        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        uint256 secondsPassed = 0;

        if(block.timestamp > _auction.startedAt) {
            secondsPassed = block.timestamp - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    ) internal pure returns (uint256) {
        if(_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            int256 currentPrice = int(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}