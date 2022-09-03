//SPDX-License-Identifier: MIT
//interface in charge of testing if an address destination is compatible with NFT ERC721
pragma solidity ^0.8.0;

interface ERC721Receiver{
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) 
                external returns(bytes4);
}