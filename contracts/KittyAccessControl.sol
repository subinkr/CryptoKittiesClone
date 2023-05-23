// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";

contract KittyAccessControl is Pausable {
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function withdrawBalance() external onlyCFO {
        (bool success, ) = payable(cfoAddress).call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function pause() public onlyCLevel {
        _pause();
    }

    function unpause() public virtual onlyCEO {
        _unpause();
    }
}