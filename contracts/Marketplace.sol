// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract  Marketplace is ERC1155Holder {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _nftSold;
    IERC1155 private nftContract;
    address private owner;
    // uint256 private platformFee = 25;
    // uint256 private deno = 1000;

    constructor(address _nftContract) {
        nftContract = IERC1155(_nftContract);
    }


struct ListedToken {
    uint256 tokenId;
    uint256 nftId;
    uint256 amount;
    uint256 price;
    uint256 royalty;
    address payable seller;
    address payable owner;
    bool currentlyListed;
    bool sold;
}

mapping (uint256 => ListedToken) private listedToken;


modifier onlyOwner() {
    require(owner == msg.sender, "Only owner can call this function");
    _;
}

function listNft(uint256 _tokenid, uint256 _amount, uint256 _price, uint256 _royalty, bool _listed) external {
    ListedToken storage _listedToken = listedToken[_tokenid];
    require(_listedToken.tokenId > 0, "Token does not exist");
    // require(_listedToken.nftId > 0, "NFT Id does not exist");
    require(_listedToken.royalty > 0 && _listedToken.royalty < 30, "royalty should be less than 30");
    // require(nftContract.ownerOf(_tokenid) == msg.sender, "You do not own an NFT");

    _listedToken.tokenId =  _tokenid;
    // _listedToken.nftId = _nftId;
    _listedToken.amount = _amount;
    _listedToken.price = _price;
    _listedToken.seller = payable(msg.sender);
    _listedToken.royalty = _royalty;
    _listedToken.currentlyListed = _listed;

    IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), _tokenid, _amount, "");
    }

    function buyNft(uint256 _tokenid, uint256 _amount) external payable {

    }

}
