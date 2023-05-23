// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./KittyBase.sol";

contract KittyOwnership is KittyBase {
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return (_claimant == owner);
    }

    function rescueLostKitty(uint256 _kittyId, address _recipient) public onlyCOO whenNotPaused {
        require(_owns(address(this), _kittyId));
        _transfer(address(this), _recipient, _kittyId);
    }
}