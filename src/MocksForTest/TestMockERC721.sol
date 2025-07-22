// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.29;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is ERC721, Ownable {
    uint256 private _nextTokenId = 1;

    constructor(address _initialOwner) ERC721("MockToken", "MTTK") Ownable(_initialOwner) {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/1708";
    }

    function safeMint(address to, uint256 quantity) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
        }
    }
}
