pragma solidity ^0.8.0;

interface INFT {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}
