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
    bool isForSale;
}

struct Fee {
    uint256 buyerFee;
    uint256 sellerFee;
}

mapping (uint256 => ListedToken) public listedToken;
mapping (uint256 => Fee) public fees;


modifier onlyOwner() {
    require(owner == msg.sender, "Only owner can call this function");
    _;
}

function listNft(uint256 _tokenid, uint256 _amount, uint256 _price, bool _listed, bool forSale) external {
    ListedToken storage _listedToken = listedToken[_tokenid];
    _listedToken.seller = payable(msg.sender);
    require(nftContract.balanceOf(msg.sender, _tokenid) != 0, "you do not own this NFT"); 
    // require(_listedToken.tokenId > 0, "Token does not exist");
    // require(_listedToken.royalty > 0 && _listedToken.royalty < 30, "royalty should be less than 30");
    // require(nftContract.ownerOf(_tokenid) == msg.sender, "You do not own an NFT");

    _listedToken.tokenId =  _tokenid;
    _listedToken.isForSale = forSale;
    _listedToken.amount = _amount;
    _listedToken.price = _price;
    // _listedToken.royalty = _royalty;
    _listedToken.currentlyListed = _listed;

    IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), _tokenid, _amount, "");
    }

    function calBuyerfee(uint256 fee) internal pure returns(uint256) {
        return fee * 5 / 100;
    }

    function calSellerfee(uint256 fee) internal pure returns(uint256) {
        return fee * 5 / 100;
    }

    function calRoyaltyfee(uint256 fee) internal pure returns(uint256) {
        return fee * 3 / 100;
    }

    function buyNft(uint256 _tokenid, uint256 _amount) external payable {

        uint256 price = listedToken[_tokenid].price;
        uint256 buyerFee = calBuyerfee(fees[_tokenid].buyerFee) * price;
        uint256 royaltyFee = calRoyaltyfee(listedToken[_tokenid].royalty) * price;
        uint256 totalFeePaid = buyerFee + royaltyFee;
        uint256 finalPrice = price - totalFeePaid;

        payable(listedToken[_tokenid].seller).transfer(finalPrice);
        payable(listedToken[_tokenid].owner).transfer(buyerFee);
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, _tokenid, _amount, "");
    }

}
