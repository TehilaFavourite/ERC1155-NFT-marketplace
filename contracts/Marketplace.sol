// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IERC2981.sol";

// uint256[] calldata _tokenIds shadows Counters.Counter private _tokenIds;
contract  Marketplace is ERC1155Holder {

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds;
    Counters.Counter private _nftSold;
    IERC1155 private nftContract;
    address private owner;

    event ListedProperty
        (
        address indexed _seller, 
        uint256 _tokenId, 
        uint256 _price, 
        uint256 _time, 
        bool _forSale,
        bool _currentlyListed,
        bool sold
        );

    event BuyEvent 
        (
        address _buyer,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _price, 
        uint256 _time
    );

    event CancelSale 
        (
        address _seller,
        uint256 _tokenId,
        bool _isCanceled,
        uint256 _time
    );


    constructor(address _nftContract) {
        nftContract = IERC1155(_nftContract);
    }

    // a struct for the tokens listed in the market. 
    // It has the token ID, amount, address of seller, buyer and owner
    struct ListedToken {
        uint256 tokenId;
        // uint256 nftId;
        uint256 amount;
        // uint256 price;
        // uint256 royalty;
        address payable seller;
        address payable buyer;
        address payable owner;
        uint256 buyerFee;
        uint256 sellerFee;
    }

    // this check runs thriugh all checks
    struct Check {
        bool currentlyListed;
        bool sold;
        bool isForSale;
        bool withdrawOffer;
    }

    struct SellOffer {
        address seller;
        uint256 minPrice;
    }

    struct BuyOffer {
        address buyer;
        uint256 price;
        uint256 createTime;
    }

    mapping (uint256 => ListedToken) private listedToken;
    mapping (uint256 => Check) private check;
    mapping(uint256 => SellOffer) public activeSellOffers;
    mapping(uint256 => BuyOffer) public activeBuyOffers;

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }

    modifier tokenOwnerOnly(uint256 tokenId) {
        require(nftContract.balanceOf(msg.sender, tokenId) != 0, "you do not own this NFT");
        _;
    }

    /// @notice Checks if NFT contract implements the ERC-2981 interface
    /// @param _contract - the address of the NFT contract to query
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC2981(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    function listNft(uint256 _tokenid, uint256 _amount, uint256 _price, bool _listed, bool forSale, bool _sold) external {
        listedToken[_tokenid].seller = payable(msg.sender);
        require(nftContract.balanceOf(msg.sender, _tokenid) != 0, "you do not own this NFT");
        require(!check[_tokenid].isForSale, "This token Id has been sold"); 
        // require(_listedToken.tokenId > 0, "Token does not exist");
        // require(_listedToken.royalty > 0 && _listedToken.royalty < 30, "royalty should be less than 30");
        // require(nftContract.ownerOf(_tokenid) == msg.sender, "You do not own an NFT");

        listedToken[_tokenid].tokenId =  _tokenid;
        check[_tokenid].isForSale = forSale;
        check[_tokenid].sold = _sold;
        listedToken[_tokenid].amount = _amount;
        // _listedToken.price = _price;
        // _listedToken.royalty = _royalty;
        check[_tokenid].currentlyListed = _listed;

        // IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), _tokenid, _amount, "");

        emit ListedProperty(msg.sender, _tokenid, _price, block.timestamp, _listed, forSale, _sold);
        }

        function userNFTBal(address _addr, uint256 _tokenid) external view returns (uint256) {
            return nftContract.balanceOf(_addr, _tokenid);
            }

        function batchUserNftBal(address[] calldata _addr, uint256[] calldata _tokenIds) 
            external view returns (uint256[] memory) {
                return nftContract.balanceOfBatch(_addr, _tokenIds);
            }


    function makeSellOffer(uint256 _tokenId, uint256 _minPrice) external tokenOwnerOnly(_tokenId) {
        require(check[_tokenId].currentlyListed, "this token is not listed");
        require(!check[_tokenId].sold, "this token is sold");
        require(listedToken[_tokenId].tokenId ==  _tokenId, "wrong token Id");
        require(check[_tokenId].isForSale, "Id is not for sale");
        activeSellOffers[_tokenId].minPrice = _minPrice;
        listedToken[_tokenId].seller =  payable(msg.sender);
        // event
    }

    function withdrawSellOffer(uint256 _tokenId, bool _withdrawOffer) external tokenOwnerOnly(_tokenId) {
        require(check[_tokenId].currentlyListed, "this token is not listed");
        require(listedToken[_tokenId].tokenId ==  _tokenId, "wrong token Id");
        require(check[_tokenId].isForSale, "Id is not for sale");
        require(!check[_tokenId].sold, "this token is sold");
        require(activeSellOffers[_tokenId].seller != address(0), "no sale offer");
        require(activeSellOffers[_tokenId].seller == msg.sender, "Not seller");

        check[_tokenId].withdrawOffer = _withdrawOffer;
        }

    function calBuyerfee(uint256 fee) internal pure returns(uint256) {
            return fee * 10 / 100;
        }

        // function calSellerfee(uint256 fee) internal pure returns(uint256) {
        //     return fee * 5 / 100;
        // }

        // function calRoyaltyfee(uint256 fee) internal pure returns(uint256) {
        //     return fee * 3 / 100;
        // }

    function buyNft(uint256 _tokenid, uint256 _amount) external payable {
        ListedToken storage _listedToken = listedToken[_tokenid];

        // uint256 price = listedToken[_tokenid].price;
        _listedToken.buyer = payable(msg.sender);
        require(check[_tokenid].isForSale, "Id is not for sale");
        // require(msg.value >= price, "Price is not complete");
        require(check[_tokenid].currentlyListed, "Id is not for currently listed");
        require(!check[_tokenid].sold, "This token id has been sold");
        // require(!check[_tokenid].isCancelled, "this sales has been canceled");

        // uint256 buyerFee = calBuyerfee(listedToken[_tokenid].price);
        // uint256 finalFee = price - buyerFee;

        // payable(listedToken[_tokenid].seller).transfer(finalFee);
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, _tokenid, _amount, "");

        // emit BuyEvent(msg.sender, _tokenid, _amount, finalFee, block.timestamp);

    }

    function cancelSale(uint256 _tokenid, bool _isCancelled) external {
        require(listedToken[_tokenid].seller == msg.sender, "you are not the owner");
        require(check[_tokenid].isForSale, "this token is not listed for sale");
        require(!check[_tokenid].sold, "this token Id has been sold");

        // check[_tokenid].isCancelled = _isCancelled;

        emit CancelSale(msg.sender, _tokenid, _isCancelled, block.timestamp);
    }

    function getMarketplaceBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return address(_user).balance;
    }


    }


