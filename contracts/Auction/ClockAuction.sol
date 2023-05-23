// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ClockAuctionBase.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClockAuction is Pausable, Ownable, ClockAuctionBase {
    constructor(address _nftAddress, uint256 _cut) {
        require(_cut <= 10000, "_cut should be smaller than or equal to 10000");
        ownerCut = _cut;

        IERC721 candidateContract = IERC721(_nftAddress);
        require(candidateContract.supportsInterface(type(IERC721).interfaceId), "this contract doesn't supports ERC721 standard");
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner() ||
            msg.sender == nftAddress,
            "you're not the owner nor nftAddress"
        );
        (bool success, ) = payable(nftAddress).call{value: address(this).balance}("");
        require(success, "Failed to send ETH to nftAddress");
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    ) public virtual whenNotPaused 
    canBeStoreWith128Bits(_startingPrice)
    canBeStoreWith128Bits(_endingPrice)
    canBeStoreWith64Bits(_duration)  {
        require(_owns(msg.sender, _tokenId), "you're not the token owner");
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp)
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId) public virtual payable whenNotPaused {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId) public {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "this _tokenId is not on the auction");
        address seller = auction.seller;
        require(msg.sender == seller, "you're not the seller");
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId) whenPaused onlyOwner public {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "this _tokenId is not on the auction");
        _cancelAuction(_tokenId, auction.seller);
    }

    function getAuction(uint256 _tokenId) public view returns (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "this _tokenId is not on the auction");
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    function getCurrentPrice(uint256 _tokenId) public view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction), "this _tokenId is not on the auction");
        return _currentPrice(auction);
    }
}