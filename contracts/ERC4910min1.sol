// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.9;
// Apache License  Version 2.0, January 2004  http://www.apache.org/licenses/

////StorageStructure.sol

contract StorageStructure {
    struct RoyaltyAccount {
        //assetId is the tokenId of the NFT the RA belongs to
        uint256 assetId;
        //parentId is the tokenId of the NFT from which this NFT is derived
        uint256 parentId;
        //royaltySplit to be paid to RA from its direct offspring
        uint256 royaltySplitForItsChildren;
        //tokenType of the balance in this RA account
        string tokenType;
        //Account balance is the total RA account balance and must be equal to the sum of the subaccount balances
        uint256 balance;
        //the struct array for sub accounts (Not supported in eth)
        //RASubAccount[] rasubaccount; 
    }

    struct RASubAccount {
        //accounttype is defined as isIndividual, and is a boolean variable, and if set to true, the account is that of an individual, if set to false, the account is an RA account ID
        bool isIndividual;
        // royalty split gives the percentage as a decimal value smaller than 1
        uint256 royaltySplit;
        //balance of the subaccount
        uint256 royaltyBalance;
        //we need the account id which we define as a bytes32 such that it is easy to convert to an address and can also be used to identity an RA acount by a hash value
        address accountId;
    }

    struct Child {
        //link to parent token
        uint256 parentId;
        //maximum number of children
        uint256 maxChildren;
        //ancestry level of NFT used to determine level of children
        uint256 ancestryLevel; //new in v1.3
        //link to children tokens
        uint256[] children;
    }

    struct NFTToken {
        //the parent of the (child) token, if 0 then there is no parent
        uint256 parent;
        //whether the token can be a parent
        bool canBeParent;
        //how many children the token can have
        uint256 maxChildren;
        //what the Royalty Split For Its Child is
        uint256 royaltySplitForItsChildren;
        //token URI
        string uri;
    }

    struct RegisteredPayment {
        //Buyer
        address buyer;
        //tokens bought
        uint256[] boughtTokens;
        //Type of Payment Token
        string tokenType;
        //Payment amount
        uint256 payment;
    }

    struct ListedNFT {
        //Seller
        address seller;
        //tokens listed
        uint256[] listedtokens;
        //Type of Payment Token
        string tokenType;
        //List price
        uint256 price;
    }

    function _isSameString(string memory left, string memory right) internal pure returns (bool) {
        return keccak256(abi.encodePacked(left)) == keccak256(abi.encodePacked(right));
    }
}




// ////RoyaltyModule.sol

import '@openzeppelin/contracts/access/Ownable.sol';
// // import './StorageStructure.sol';
// import 'abdk-libraries-solidity/ABDKMathQuad.sol';

contract RoyaltyModule is StorageStructure, Ownable {
    mapping(uint256 => address) private _tokenindextoRA; //Mapping a tokenId to an raAccountID in order to connect a RA raAccountId to a tokenId
    mapping(address => RoyaltyAccount) private _royaltyaccount; //Mapping the raAccountID to a RoyaltyAccount in order to connect the account identifier to the actual account.
    mapping(address => RASubAccount[]) private _royaltysubaccounts; //workaround for array in struct
    mapping(uint256 => Child) private ancestry; //An ancestry mapping of the parent-to-child NFT relationship

//     event RoyalyDistributed(uint256 tokenId, address to, uint256 amount, uint256 assetId);
//     address private _ttAddress;
//     uint256 private _royaltySplitTT;
//     uint256 private _maxSubAccount;
//     uint256 private _minRoyaltySplit;

    constructor(
        address owner,
        address ttAddress,
        uint256 royaltySplitTT,
        uint256 minRoyaltySplit,
        uint256 maxSubAccounts
    ) {
        // transferOwnership(owner);
        // require(royaltySplitTT < 10000, 'Royalty Split to TT is > 100%'); //new v1.3
        // require(royaltySplitTT + minRoyaltySplit < 10000, 'Royalty Split to TT + Minimal Split is > 100%');
        // require(ttAddress != address(0), 'Zero Address cannot be TT royalty account');
        // _ttAddress = ttAddress;
        // _royaltySplitTT = royaltySplitTT;
        // _maxSubAccount = maxSubAccounts;
        // _minRoyaltySplit = minRoyaltySplit;
    }


//     function updateRAccountLimits(uint256 maxSubAccounts, uint256 minRoyaltySplit) public virtual onlyOwner returns (bool) {
//         require(_royaltySplitTT + minRoyaltySplit < 10000, 'Royalty Split to TT + Minimal Split is > 100%');
//         _maxSubAccount = maxSubAccounts;
//         _minRoyaltySplit = minRoyaltySplit;
//         return true;
//     }

//     function getAccount(uint256 tokenId)
//         public
//         view
//         returns (
//             address,
//             RoyaltyAccount memory,
//             RASubAccount[] memory
//         )
//     {
//         address royaltyAccount = _tokenindextoRA[tokenId];
//         return (royaltyAccount, _royaltyaccount[royaltyAccount], _royaltysubaccounts[royaltyAccount]);
//     }

//     // Lib variant
//     // Rules:
//     // Only subaccount owner can decrease splitRoyalty for this subaccount
//     // Only parent token owner can decrease royalty subaccount splitRoyalty
//     function updateRoyaltyAccount(
//         uint256 tokenId,
//         RASubAccount[] memory affectedSubaccounts,
//         address sender,
//         bool isTokenOwner
//     ) public virtual onlyOwner {
//         address royaltyAccount = _tokenindextoRA[tokenId];
//         //Check total sum of royaltySplit was not changed
//         uint256 oldSum;
//         uint256 newSum;
//         for (uint256 i = 0; i < affectedSubaccounts.length; i++) {
//             require(affectedSubaccounts[i].royaltySplit >= _minRoyaltySplit, 'Royalty Split is smaller then set limit');
//             newSum += affectedSubaccounts[i].royaltySplit;
//             (bool found, uint256 indexOld) = _findSubaccountIndex(royaltyAccount, affectedSubaccounts[i].accountId);
//             if (found) {
//                 RASubAccount storage foundAcc = _royaltysubaccounts[royaltyAccount][indexOld];
//                 oldSum += foundAcc.royaltySplit;
//                 //Check rights to decrease royalty split
//                 if (affectedSubaccounts[i].royaltySplit < foundAcc.royaltySplit) {
//                     if (foundAcc.isIndividual) {
//                         require(affectedSubaccounts[i].accountId == sender, 'Only individual subaccount owner can decrease royaltySplit');
//                     } else {
//                         require(isTokenOwner, 'Only parent token owner can decrease royalty subaccount royaltySplit');
//                     }
//                 }
//             }
//             //New subaccounts must be individual
//             else {
//                 require(affectedSubaccounts[i].isIndividual, 'New subaccounts must be individual');
//             }
//         }
//         require(oldSum == newSum, 'Total royaltySplit must be 10000');

//         //Update royalty split for subaccounts and add new subaccounts
//         for (uint256 i = 0; i < affectedSubaccounts.length; i++) {
//             (bool found, uint256 indexOld) = _findSubaccountIndex(royaltyAccount, affectedSubaccounts[i].accountId);
//             if (found) {
//                 _royaltysubaccounts[royaltyAccount][indexOld].royaltySplit = affectedSubaccounts[i].royaltySplit;
//             } else {
//                 require(_royaltysubaccounts[royaltyAccount].length < _maxSubAccount, 'Too many Royalty subaccounts');
//                 _royaltysubaccounts[royaltyAccount].push(RASubAccount(true, affectedSubaccounts[i].royaltySplit, 0, affectedSubaccounts[i].accountId));
//             }
//         }
//     }

//     //Deleting a Royalty Account
//     function deleteRoyaltyAccount(uint256 tokenId) public virtual onlyOwner {
//         address royaltyAccount = _tokenindextoRA[tokenId];
//         for (uint256 i = 0; i < _royaltysubaccounts[royaltyAccount].length; i++) {
//             if (_royaltysubaccounts[royaltyAccount][i].isIndividual) {
//                 require(_royaltysubaccounts[royaltyAccount][i].royaltyBalance == 0, "Can't delete non empty royalty account");
//             }
//         }
//         delete _royaltyaccount[royaltyAccount];
//         delete _royaltysubaccounts[royaltyAccount];
//         delete _tokenindextoRA[tokenId];
//     }

//     //Function for create a new Royalty Account which is meet the basic requirements
//     //1. Have correct royalty split configuration
//     //2. Then generate a RA for the address
//     //3. Add the RA(address) to the whole hierarchy tree.
//     //4. Confirm the subaccount of the RA meet the requirement of the hierarchy machenism.
//     //
//     function createRoyaltyAccount(
//         address to,
//         uint256 parentTokenId,
//         uint256 tokenId,
//         string calldata tokenType,
//         uint256 royaltySplitForItsChildren
//     ) public onlyOwner returns (address) {
//         require(royaltySplitForItsChildren <= 10000, 'Royalty Split to be received from children is > 100%');

//         require(_royaltySplitTT + royaltySplitForItsChildren <= 10000, 'Royalty Splits sum is > 100%');
//         address raAccountId = address(bytes20(keccak256(abi.encodePacked(tokenId, to, block.number))));
//         if (parentTokenId == 0) {
//             //Create Royalty account without parent

//             //create the RA subaccount for the to address
//             _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: 10000 - _royaltySplitTT, royaltyBalance: 0, accountId: to}));

//             //create the RA subaccount for TreeTrunk
//             _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: _royaltySplitTT, royaltyBalance: 0, accountId: _ttAddress}));

//             //now create the Royalty Account
//             //map assetID to RA
//             _royaltyaccount[raAccountId] = RoyaltyAccount({assetId: tokenId, parentId: 0, royaltySplitForItsChildren: royaltySplitForItsChildren, tokenType: tokenType, balance: 0});
//         } else {
//             //Create royalty account with parent

//             address parentRoyaltyAccount = _tokenindextoRA[parentTokenId];
//             //tokenType must be same as in parent
//             require(_isSameString(tokenType, _royaltyaccount[parentRoyaltyAccount].tokenType), 'tokenType must be same as in parent');

//             RoyaltyAccount memory parentRA = _royaltyaccount[parentRoyaltyAccount];
//             //create the RA subaccount for the to address
//             _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: 10000 - parentRA.royaltySplitForItsChildren - _royaltySplitTT, royaltyBalance: 0, accountId: to}));

//             //create the RA subaccount for TreeTrunk
//             _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: _royaltySplitTT, royaltyBalance: 0, accountId: _ttAddress}));

//             //create the RA subaccount for the RA address of the ancestor
//             _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: false, royaltySplit: parentRA.royaltySplitForItsChildren, royaltyBalance: 0, accountId: parentRoyaltyAccount}));

//             //now create the Royalty Account
//             //map assetID to RA
//             _royaltyaccount[raAccountId] = RoyaltyAccount({assetId: tokenId, parentId: parentRA.assetId, royaltySplitForItsChildren: royaltySplitForItsChildren, tokenType: tokenType, balance: 0});
//         }
//         require(_royaltysubaccounts[raAccountId].length <= _maxSubAccount, 'Too many Royalty subaccounts');
//         _tokenindextoRA[tokenId] = raAccountId;
//         return raAccountId;
//     }

    //Function for recursive distribution royalty for RA tree
    function distributePayment(uint256 tokenId, uint256 payment) public virtual onlyOwner returns (bool) {
        address royaltyAccount = _tokenindextoRA[tokenId];
        return _distributePayment(royaltyAccount, payment, tokenId);
    }

    function _distributePayment(
        address royaltyAccount,
        uint256 payment,
        uint256 tokenId
    ) internal virtual returns (bool) {
        uint256 remainsValue = payment;
        uint256 remainsSplit = 10000;
        uint256 assetId = _royaltyaccount[royaltyAccount].assetId;
        for (uint256 i = 0; i < _royaltysubaccounts[royaltyAccount].length; i++) {
        //     //skip calculate for 0% subaccounts
            if (_royaltysubaccounts[royaltyAccount][i].royaltySplit == 0) continue;
        //     //calculate royalty split sum
        //     uint256 paymentSplit = mulDiv(remainsValue, _royaltysubaccounts[royaltyAccount][i].royaltySplit, remainsSplit);
        //     remainsValue -= paymentSplit;
        //     remainsSplit -= _royaltysubaccounts[royaltyAccount][i].royaltySplit;
        //     //distribute if IND subaccount
            if (_royaltysubaccounts[royaltyAccount][i].isIndividual == true) {
        //         _royaltysubaccounts[royaltyAccount][i].royaltyBalance += paymentSplit;
        //         emit RoyalyDistributed(tokenId, _royaltysubaccounts[royaltyAccount][i].accountId, paymentSplit, assetId);
            }
        //     //distribute if RA subaccounts
            else {
        //         _distributePayment(_royaltysubaccounts[royaltyAccount][i].accountId, paymentSplit, tokenId);
            }
        }
        return true;
    }

//     function isSupportedTokenType(uint256 tokenId, string calldata tokenType) public view returns (bool) {
//         return _isSameString(tokenType, _royaltyaccount[_tokenindextoRA[tokenId]].tokenType);
//     }

//     function getTokenType(uint256 tokenId) public view returns (string memory) {
//         return _royaltyaccount[_tokenindextoRA[tokenId]].tokenType;
//     }

//     function findSubaccountIndex(uint256 tokenId, address subaccount) public view virtual returns (bool, uint256) {
//         address royaltyAccount = _tokenindextoRA[tokenId];
//         return _findSubaccountIndex(royaltyAccount, subaccount);
//     }

//     function checkBalanceForPayout(
//         uint256 tokenId,
//         address subaccount,
//         uint256 amount
//     ) public view virtual returns (bool) {
//         (bool subaccountFound, uint256 subaccountIndex) = findSubaccountIndex(tokenId, subaccount);
//         require(subaccountFound, 'Subaccount not found');
//         RASubAccount memory subAccount = getSubaccount(tokenId, subaccountIndex);
//         require(subAccount.isIndividual == true, 'Subaccount must be individual');
//         require(subAccount.royaltyBalance >= amount, 'Insufficient royalty balance');
//         return true;
//     }

//     function getSubaccount(uint256 tokenId, uint256 subaccountIndex) public view virtual returns (RASubAccount memory) {
//         return _royaltysubaccounts[_tokenindextoRA[tokenId]][subaccountIndex];
//     }

//     function getBalance(uint256 tokenId, address subaccount) public view virtual returns (uint256) {
//         (bool found, uint256 subaccountIndex) = findSubaccountIndex(tokenId, subaccount);
//         if (!found) return 0;
//         return getSubaccount(tokenId, subaccountIndex).royaltyBalance;
//     }

//     //Used for reduce royalty balance after payout
//     //Used only in RoyaltyBearingToken._royaltyPayOut(uint256,address,address,uint256)
//     function withdrawBalance(
//         uint256 tokenId,
//         address subaccount,
//         uint256 amount
//     ) public virtual onlyOwner {
//         (bool subaccountFound, uint256 subaccountIndex) = findSubaccountIndex(tokenId, subaccount);
//         require(subaccountFound, 'Subaccount not found');
//         require(_royaltysubaccounts[_tokenindextoRA[tokenId]][subaccountIndex].royaltyBalance >= amount, 'Insufficient royalty balance');
//         _royaltysubaccounts[_tokenindextoRA[tokenId]][subaccountIndex].royaltyBalance -= amount;
//     }

//     //Used in RoyaltyBearingToken._safeTransferFrom(address, address,uint256, bytes)
//     //for transfer royalty account ownership after tranfer token ownership
//     function transferRAOwnership(
//         address seller,
//         uint256 tokenId,
//         address buyer
//     ) public virtual onlyOwner {
//         address royaltyAccount = _tokenindextoRA[tokenId];
//         (bool found, uint256 index) = _findSubaccountIndex(royaltyAccount, seller);
//         require(found, 'Seller subaccount not found');
//         require(_royaltysubaccounts[royaltyAccount][index].royaltyBalance == uint256(0), 'Seller subaccount must have 0 balance');

//         //replace owner of subaccount
//         _royaltysubaccounts[royaltyAccount][index].accountId = buyer;
//     }

//     // Find subaccount index by subaccount address
//     function _findSubaccountIndex(address royaltyAccount, address subaccount) internal view virtual returns (bool, uint256) {
//         //local variable decrease contract code size
//         RASubAccount[] storage subAccounts = _royaltysubaccounts[royaltyAccount];
//         for (uint256 i = 0; i < subAccounts.length; i++) {
//             if (subAccounts[i].accountId == subaccount) {
//                 return (true, i);
//             }
//         }
//         return (false, 0);
//     }

//     //Util function for split royalty payment
//     function mulDiv(
//         uint256 x,
//         uint256 y,
//         uint256 z
//     ) public pure returns (uint256) {
//         return ABDKMathQuad.toUInt(ABDKMathQuad.div(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(x), ABDKMathQuad.fromUInt(y)), ABDKMathQuad.fromUInt(z)));
//     }

//     //Util function for split value by pieces without remains
//     function splitSum(uint256 sum, uint256 pieces) public pure virtual returns (uint256[] memory) {
//         uint256[] memory result = new uint256[](pieces);
//         uint256 remains = sum;
//         for (uint256 i = 0; i < pieces; i++) {
//             result[i] = mulDiv(remains, 1, pieces - i);
//             remains -= result[i];
//         }
//         return result;
//     }
}

// ////PaymentModel.sol
// // import "@openzeppelin/contracts/access/Ownable.sol";
// // import '@openzeppelin/contracts/access/Ownable.sol';
// // import './StorageStructure.sol';
// // import 'abdk-libraries-solidity/ABDKMathQuad.sol';

// //PaymentModel is mainly about 2 parts
// //1. NFT Listing
// //2. Payment & Transaction Data

// contract PaymentModule is StorageStructure, Ownable {
//     mapping(uint256 => RegisteredPayment) private registeredPayment; //A mapping with a struct for a registered payment
//     mapping(uint256 => ListedNFT) private listedNFT; //A mapping for listing NFTs to be sold
//     mapping(uint256 => bool) private tokenLock; // lock listed token for sure one time list

//     uint256[] private listedNFTList; // List of all listed NFT

//     uint256 private _maxListingNumber; //Max token count int listing

//     constructor(address owner, uint256 maxListingNumber) {
//         transferOwnership(owner);
//         require(maxListingNumber > 0, 'Max number must be > 0');
//         _maxListingNumber = maxListingNumber;
//     }

//     function updatelistinglimit(uint256 maxListingNumber) public onlyOwner returns (bool) {
//         require(maxListingNumber > 0, 'Max number must be > 0');
//         _maxListingNumber = maxListingNumber;
//         return true;
//     }


//     // NFT Listing
//     // addListNFT requires seller provide their wallet address, tokenId, price of the token, and the type of the token.
//     // existsInListNFT returns true there the address of the seller exist in the list 
//     // removeListNFT 


//     function addListNFT(
//         address seller,
//         uint256[] calldata tokenIds,
//         uint256 price,
//         string calldata tokenType
//     ) public virtual onlyOwner {
//         require(price > 0, 'Zero Price not allowed');
//         require(!existsInListNFT(tokenIds), 'Already exists');
//         require(tokenIds.length <= _maxListingNumber, 'Too many NFTs listed');
//         listedNFT[tokenIds[0]] = ListedNFT({seller: seller, listedtokens: tokenIds, tokenType: tokenType, price: price});
//         //lock tokens
//         for (uint256 i = 0; i < tokenIds.length; i++) {
//             tokenLock[tokenIds[i]] = true;
//         }
//         //add to list index
//         listedNFTList.push(tokenIds[0]);
//     }

//     function existsInListNFT(uint256[] memory tokenIds) public view virtual returns (bool) {
//         if (listedNFT[tokenIds[0]].seller != address(0)) return true;

//         for (uint256 i = 0; i < tokenIds.length; i++) {
//             if (tokenLock[tokenIds[i]]) return true;
//         }
//         return false;
//     }

//     function removeListNFT(uint256 tokenId) public virtual onlyOwner {
//         require(registeredPayment[tokenId].buyer == address(0), 'RegisterPayment exists for NFT');
//         //unlock token
//         for (uint256 i = 0; i < listedNFT[tokenId].listedtokens.length; i++) {
//             tokenLock[listedNFT[tokenId].listedtokens[i]] = false;
//         }
//         //delete from index
//         for (uint256 i = 0; i < listedNFTList.length; i++) {
//             if (listedNFTList[i] == tokenId) {
//                 listedNFTList[i] = listedNFTList[listedNFTList.length - 1];
//                 listedNFTList.pop();
//                 break;
//             }
//         }

//         delete listedNFT[tokenId];
//     }

//     function getListNFT(uint256 tokenId) public view returns (ListedNFT memory) {
//         require(listedNFT[tokenId].seller != address(0), 'Listing not exist');
//         return listedNFT[tokenId];
//     }

//     function getAllListNFT() public view returns (uint256[] memory) {
//         return listedNFTList;
//     }

//     function isValidPaymentMetadata(
//         address seller,
//         uint256[] calldata tokenIds,
//         uint256 payment,
//         string calldata tokenType
//     ) public view virtual returns (bool) {
//         //check if NFT(s) are even listed
//         require(listedNFT[tokenIds[0]].seller != address(0), 'NFT(s) not listed');
//         //check if seller is really a seller
//         require(listedNFT[tokenIds[0]].seller == seller, 'Submitted Seller is not Seller');
//         //check if payment is sufficient
//         require(listedNFT[tokenIds[0]].price <= payment, 'Payment is too low');
//         //check if token type supported
//         require(_isSameString(listedNFT[tokenIds[0]].tokenType, tokenType), 'Payment token does not match list token type');
//         //check if listed NFT(s) match NFT(s) in the payment and are controlled by seller
//         uint256[] memory listedTokens = listedNFT[tokenIds[0]].listedtokens;
//         for (uint256 i = 0; i < listedTokens.length; i++) {
//             require(tokenIds[i] == listedTokens[i], 'One or more tokens are not listed');
//         }
//         return true;
//     }

//     function addRegisterPayment(
//         address buyer,
//         uint256[] calldata tokenIds,
//         uint256 payment,
//         string calldata tokenType
//     ) public virtual onlyOwner {
//         require(registeredPayment[tokenIds[0]].buyer == address(0), 'RegisterPayment already exists');
//         registeredPayment[tokenIds[0]] = RegisteredPayment({buyer: buyer, boughtTokens: tokenIds, tokenType: tokenType, payment: payment});
//     }

//     function getRegisterPayment(uint256 tokenId) public view virtual returns (RegisteredPayment memory) {
//         return registeredPayment[tokenId];
//     }

//     function checkRegisterPayment(uint256 tokenId, address buyer) public view virtual returns (uint256) {
//         if (registeredPayment[tokenId].buyer == buyer) return registeredPayment[tokenId].payment;
//         else return 0;
//     }

//     function checkRegisterPayment(
//         uint256 tokenId,
//         address buyer,
//         string memory tokenType
//     ) public view virtual returns (uint256) {
//         if (registeredPayment[tokenId].buyer == buyer) {
//             require(_isSameString(tokenType, registeredPayment[tokenId].tokenType), 'TokenType mismatch');
//             return registeredPayment[tokenId].payment;
//         } else return 0;
//     }

//     function checkRegisteredPayment(
//         address buyer,
//         uint256 tokenId,
//         uint256 _payment,
//         string memory tokenType
//     ) public view virtual returns (bool) {
//         if((registeredPayment[tokenId].buyer == buyer) && (_isSameString(tokenType, registeredPayment[tokenId].tokenType))) {
//             require(registeredPayment[tokenId].payment == _payment);
//             return true;
//         } else return false;
//     }

//     function removeRegisterPayment(address buyer, uint256 tokenId) public virtual onlyOwner {
//         require(registeredPayment[tokenId].buyer == buyer, 'RegisterPayment not found');
//         delete registeredPayment[tokenId];
//     }
// }


// ////RoyaltyBearingTokenStorage.sol

// // import './StorageStructure.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
// // import './RoyaltyModule.sol';
// // import './PaymentModule.sol';

contract RoyaltyBearingTokenStorage is StorageStructure, AccessControlEnumerable {
    using Address for address;
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR_ROLE');
    string internal _baseTokenURI;
    Counters.Counter internal _tokenIdTracker;

    mapping(uint256 => Child) internal ancestry; //An ancestry mapping of the parent-to-child NFT relationship
    mapping(string => address) internal allowedToken; //A mapping of supported token types to their origin contracts
    mapping(address => uint256) internal allowedTokenContract; //A mapping of supported token types to their origin contracts
    address[] internal allowedTokenList;
    mapping(bytes4 => bool) internal functionSigMap; //functionSig mapping

    RoyaltyModule internal royaltyModule;
  
    //PaymentModule internal paymentModule;
    //address internal logicModule;

    uint256 internal _numGenerations;
    address internal _ttAddress;
    uint256 internal _royaltySplitTT;

    event Received(address sender, uint256 amount, uint256 tokenId);
}


// ////RoyaltyBearingToken.sol

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
// import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
//  import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
// import '@openzeppelin/contracts/utils/Address.sol';
// import '@openzeppelin/contracts/utils/Counters.sol';

// // import './RoyaltyBearingTokenStorage.sol';
// // import './RoyaltyModule.sol';
// // import './PaymentModule.sol';


// contract RoyaltyBearingToken is ERC721Burnable, ERC721Pausable, ERC721URIStorage, AccessControlEnumerable, RoyaltyBearingTokenStorage, IERC721Receiver, ReentrancyGuard {
contract RoyaltyBearingToken is ERC721Burnable, ERC721Pausable, ERC721URIStorage, RoyaltyBearingTokenStorage {
    using Address for address;
    using Counters for Counters.Counter;
    bool private onlyOnce = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        //string[] memory allowedTokenTypes,
        //address[] memory allowedTokenAddresses,
        address creatorAddress,
        uint256 numGenerations
    ) ERC721(name, symbol) {
        require(_msgSender() == tx.origin, 'Caller must not be a contract'); //ERROR: contract caller
        require(!creatorAddress.isContract(), 'Creator must not be a contract'); //ERROR: creator contract
        //require(allowedTokenTypes.length == allowedTokenAddresses.length, 'Numbers of allowed tokens'); //ERROR:token limit 
        _baseTokenURI = baseTokenURI;

        //setupRole from open zeppelin accesscontrol: https://docs.openzeppelin.com/contracts/3.x/access-control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, creatorAddress); //4 ROLES: ADMIN, MINTER, PAUSER, CREATOR.

        _numGenerations = numGenerations;

        // for (uint256 i = 0; i < allowedTokenTypes.length; i++) {
        //     addAllowedTokenType(allowedTokenTypes[i], allowedTokenAddresses[i]);
        // }

        //ETH only
        // addAllowedTokenType( 'ETH' , address(0x0) );
            string memory tokenName = 'ETH';
            address tokenAddress = address(0x0);
            require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Admin role required'); //ERROR: onlyAdmin
            if (_isEthToken(tokenName)) {
                tokenAddress = address(this);
            } 
            // else {
            //     require(tokenAddress != address(0x0) && tokenAddress.isContract(), 'Token must be contact'); //ERROR: token
            // }
            require(allowedTokenContract[tokenAddress] == 0, 'Token is duplicate'); //ERROR: duplicate

            allowedToken[string(tokenName)] = tokenAddress;
            allowedTokenList.push(tokenAddress);
            allowedTokenContract[tokenAddress] = allowedTokenList.length;

        //For tree logic we need start id from 1 not 0;
        _tokenIdTracker.increment();
    }

//     function init(address royaltyModuleAddress, address paymentModuleAddress) public virtual {
//         require(!onlyOnce, 'Init was called before');
//         require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Admin role required');
//         royaltyModule = RoyaltyModule(royaltyModuleAddress);
//         paymentModule = PaymentModule(paymentModuleAddress);
//         onlyOnce = true;
//     }

//     function updatelistinglimit(uint256 maxListingNumber) public virtual returns (bool) {
//         //ensure that msg.sender has the creater role or internal call
//         require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
//         return paymentModule.updatelistinglimit(maxListingNumber);
//     }

//     function updateRAccountLimits(uint256 maxSubAccounts, uint256 minRoyaltySplit) public virtual returns (bool) {
//         //ensure that msg.sender has the creater role or internal call
//         require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
//         return royaltyModule.updateRAccountLimits(maxSubAccounts, minRoyaltySplit);
//     }

//     function updateMaxGenerations(uint256 newMaxNumber) public virtual returns (bool) {
//         //ensure that msg.sender has the creater role or internal call
//         require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
//         _numGenerations = newMaxNumber;
//         return true;
//     }

//     function getModules() public view returns (address, address) {
//         return (address(royaltyModule), address(paymentModule));
//     }

//     function delegateAuthority(
//         bytes4 functionSig,
//         bytes calldata _functionData,
//         bytes32 documentHash,
//         uint8[] memory sigV,
//         bytes32[] memory sigR,
//         bytes32[] memory sigS,
//         uint256 chainid
//     ) public virtual returns (bool) {
//         require(chainid == block.chainid, 'Wrong blockchain');
//         require(functionSigMap[functionSig], 'Not a valid function');

//         bytes32 prefixedProof = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', documentHash));
//         address recovered = ecrecover(prefixedProof, sigV[0], sigR[0], sigS[0]);

//         require(hasRole(CREATOR_ROLE, recovered), 'Signature'); //Signature was not from creator

//         (bool success, ) = address(this).call(_functionData);
//         require(success);
//         return true;
//     }

//     //Note that functionSig must be calculated as follows
//     //bytes4(keccak256("updateMaxGenerations(uint256)")
//     function setFunctionSignature(bytes4 functionSig) public virtual returns (bool) {
//         require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(CREATOR_ROLE, _msgSender()), 'Admin or Creator role required');
//         functionSigMap[functionSig] = true;
//         return true;
//     }

//     function onERC721Received(
//         address, /*operator*/
//         address from,
//         uint256, /*tokenId*/
//         bytes calldata /*data*/
//     ) external pure returns (bytes4) {
//         require(from == address(0), 'Only minted');
//         //required to allow transfer mined token to this contract
//         return bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'));
//     }

    // function addAllowedTokenType(string memory tokenName, address tokenAddress) public {
    //     require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Admin role required'); //ERROR: onlyAdmin
    //     if (_isEthToken(tokenName)) {
    //         tokenAddress = address(this);
    //     } 
    //     // else {
    //     //     require(tokenAddress != address(0x0) && tokenAddress.isContract(), 'Token must be contact'); //ERROR: token
    //     // }
    //     require(allowedTokenContract[tokenAddress] == 0, 'Token is duplicate'); //ERROR: duplicate

    //     allowedToken[string(tokenName)] = tokenAddress;
    //     allowedTokenList.push(tokenAddress);
    //     allowedTokenContract[tokenAddress] = allowedTokenList.length;
    // }

//     function getAllowedTokens() public view returns (address[] memory) {
//         return (allowedTokenList);
//     }

//     //Royalty module functions
//     //Get a Royalty Account through the NFT token index
//     function getRoyaltyAccount(uint256 tokenId)
//         public
//         view
//         virtual
//         returns (
//             address accountId,
//             RoyaltyAccount memory account,
//             RASubAccount[] memory subaccounts
//         )
//     {
//         require(_exists(tokenId), 'NFT does not exist');
//         return royaltyModule.getAccount(tokenId);
//     }

//     // Rules:
//     // Only subaccount owner can decrease splitRoyalty for this subaccount
//     // Only parent token owner can decrease royalty subaccount splitRoyalty
//     function updateRoyaltyAccount(uint256 tokenId, RASubAccount[] memory affectedSubaccounts) public virtual {
//         uint256 parentId = ancestry[tokenId].parentId;
//         bool isTokenOwner = getApproved(parentId) == _msgSender();

//         royaltyModule.updateRoyaltyAccount(tokenId, affectedSubaccounts, _msgSender(), isTokenOwner);
//     }

//     /**
//      * @dev Creates a new token for `to`. Its token ID will be automatically
//      * assigned (and available on the emitted {IERC721-Transfer} event), and the token
//      * URI autogenerated based on the base URI passed at construction.
//      *
//      * See {ERC721-_mint}.
//      *
//      * Requirements:
//      *
//      * - the caller must have the `MINTER_ROLE`.
//      */
//     function mint(
//         address to,
//         NFTToken[] memory nfttokens,
//         string memory tokenType
//     ) public virtual {
//         require(nfttokens.length > 0, 'nfttokens has no value');
//         require(hasRole(MINTER_ROLE, _msgSender()) || hasRole(CREATOR_ROLE, _msgSender()), 'Minter or Creator role required');
//         //ensure to address is not a contract
//         require(to != address(0x0), 'Zero Address cannot have active NFTs!');
//         //require(!to.isContract(), 'Cannot be minted to contracts');
//         if (to == _msgSender()) {
//             require(tx.origin == to, 'To must not be contracts');
//         } else {
//             require(!to.isContract(), 'To must not be contracts');
//         }

//         //token type must exist
//         require(allowedToken[tokenType] != address(0x0), 'Token Type not supported!');

//         //Loop through the array of tokens to be minted
//         for (uint256 i = 0; i < nfttokens.length; i++) {
//             NFTToken memory token = nfttokens[i];

//             //royaltySplitForItsChildren must be less or equal to 100%
//             require(token.royaltySplitForItsChildren <= 10000, 'Royalty Split is > 100%');

//             //If the token cannot have offspring royaltySplitForItsChildren must be zero
//             if (!token.canBeParent) {
//                 token.royaltySplitForItsChildren = 0;
//             }

//             //create RA account identifier
//             uint256 tokenId = _tokenIdTracker.current();

//             //enforce business rules
//             if (token.parent > 0) {
//                 require(_exists(token.parent), 'Parent NFT does not exist');

//                 //update ancestry struct and mapping
//                 require(ancestry[token.parent].ancestryLevel < _numGenerations, 'Generation limit');
//                 require(ancestry[token.parent].children.length < ancestry[token.parent].maxChildren, 'Offspring limit');
//                 ancestry[token.parent].children.push(tokenId);
//                 // store link to parent
//                 ancestry[tokenId].parentId = token.parent;
//                 ancestry[tokenId].ancestryLevel = ancestry[token.parent].ancestryLevel + 1;
//             }

//             // We cannot just use balanceOf to create the new tokenId because tokens
//             // can be burned (destroyed), so we need a separate counter.
//             // The NFT contract address(this) must be the owner
//             _safeMint(address(this), tokenId);

//             //give to address minter role unless it has it already
//             _grantRole(MINTER_ROLE, to);

//             // after successful minting, the to address will be approved as an NFT controller.
//             _approve(to, tokenId);

//             //Create and link royalty account
//             royaltyModule.createRoyaltyAccount(to, token.parent, tokenId, tokenType, token.royaltySplitForItsChildren);

//             //set token URI
//             _setTokenURI(tokenId, token.uri);

//             //if new token can have children instantiate struct and add to mapping
//             if (token.canBeParent) {
//                 ancestry[tokenId].maxChildren = token.maxChildren;
//             }

//             //increment token counter to know which is the next token index that can be minted
//             _tokenIdTracker.increment();
//         }
//     }

//     function updateMaxChildren(uint256 tokenId, uint256 newMaxChildren) public virtual returns (bool) {
//         //ensure that msg.sender has the role minter
//         require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
//         require(newMaxChildren > ancestry[tokenId].children.length, 'Max < Actual');
//         ancestry[tokenId].maxChildren = newMaxChildren;

//         return true;
//     } 


    //Must override for 720behavior
    //Functions for support ERC721 extensions
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'Pauser role required');
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'Pauser role required');
        _unpause();
    }

    //Must override for 720behavior
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override (ERC721,ERC721Pausable){
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    //Must override for 720behavior
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //Must override for 720behavior
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    //Must override for 720behavior
    function burn(uint256 tokenId) public virtual override {
        require(getApproved(tokenId) == _msgSender(), 'Sender not authorized to burn');
        require(ancestry[tokenId].children.length == 0, 'NFT must not have children');
        //delete token from royalty (check for 0 balance included)
        // royaltyModule.deleteRoyaltyAccount(tokenId);

        // _burn(tokenId);

        // uint256 parentId = ancestry[tokenId].parentId;
        // uint256 length = ancestry[parentId].children.length;
        // //delete burned token from ancestry
        // for (uint256 i = 0; i < length; i++) {
        //     if (ancestry[parentId].children[i] == tokenId) {
        //         //swap with last and delete last element for less gas
        //         ancestry[parentId].children[i] = ancestry[parentId].children[length - 1];
        //         delete ancestry[parentId].children[length - 1];
        //         break;
        //     }
        // }
    }

//     function transferFrom(
//         address,
//         address,
//         uint256
//     ) public pure override {
//         revert('Function not allowed');
//     }

//     function safeTransferFrom(
//         address,
//         address,
//         uint256
//     ) public virtual override {
//         revert('Function not allowed');
//     }

//     function _getTokenBalance(address tokenAddress) private view returns (uint256) {
//         return IERC20(tokenAddress).balanceOf(address(this));
//     }

    //TODO 
    function _isEthToken(string memory tokenType) internal pure returns (bool) {
        return keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked('ETH'));
    }

//     function listNFT(
//         uint256[] calldata tokenIds,
//         uint256 price,
//         string calldata tokenType
//     ) public virtual returns (bool) {

//         for (uint256 i = 0; i < tokenIds.length; i++) {
//             require(getApproved(tokenIds[i]) == _msgSender(), 'Must be token owner');
//             require(royaltyModule.isSupportedTokenType(tokenIds[i], tokenType), 'Unsupported token type');
//         }
//         //Put tokens to listed
//         paymentModule.addListNFT(_msgSender(), tokenIds, price, tokenType);
//         return true;
//     }

//     function removeNFTListing(uint256 tokenId) public virtual returns (bool) {
//         require(_msgSender() == getApproved(tokenId), 'Must be token owner');
//         paymentModule.removeListNFT(tokenId);
//         return true;
//     }

//     function _requireExistsAndOwned(uint256[] memory tokenIds, address seller) internal view {
//         for (uint256 i = 0; i < tokenIds.length; i++) {
//             require(_exists(tokenIds[i]), 'Token does not exist');
//             require(seller == getApproved(tokenIds[i]), 'Seller is not owner');
//         }
//     }

    // ERC20 royalty payment
    function executePayment(
        address receiver,
        address seller,
        uint256[] calldata tokenIds,
        uint256 payment,
        string calldata tokenType,
        int256 trxntype
    ) public virtual returns (bool) {
    // ) public virtual nonReentrant returns (bool) {
        
//         require(payment > 0, 'Payments cannot be 0!');
//         require(trxntype == 0 || trxntype == 1, 'Trxn type not supported');
//         require(receiver != address(0), 'Receiver must not be zero');
//         _requireExistsAndOwned(tokenIds, seller);
        
//             paymentModule.isValidPaymentMetadata(seller, tokenIds, payment, tokenType);
            
//         //Execute ERC20 payment
//         address payToken = allowedToken[tokenType];
//         {
//             require(payToken != address(0x0), 'Unsupported token type');
//             //Check for ERC20 approval
//             uint256 allowed = IERC20(payToken).allowance(_msgSender(), address(this));
//             require(allowed >= payment, 'Insufficient token allowance');

//             uint256 balanceBefore = _getTokenBalance(payToken);

//             //Transfer ERC20 token to contact
//             bool success = IERC20(payToken).transferFrom(_msgSender(), address(this), payment);
//             require(success && payment == _getTokenBalance(payToken) - balanceBefore, 'ERC20 transfer failed');
//         }

//         //If the transfer is successful, the registeredPayment mapping is updated if trxntype = 1
//         if (trxntype == 1) {
//             paymentModule.addRegisterPayment(_msgSender(), tokenIds, payment, tokenType);
//         }
//         //if trxntype = 0, an internal version of the safeTransferFrom function must be called to transfer the NFTs to the buyer
//         else if (trxntype == 0) {
//             //encode payment data for transfer(s)
//             bytes memory data = abi.encode(seller, _msgSender(), receiver, tokenIds, tokenType, payment, payToken, block.chainid);

//             //transfer NFT(s)
                //ERROR cannot find? //FIX.
            // _safeTransferFrom(seller, _msgSender(), tokenIds[0], data);
//         }

        return true;
    }

//     function checkPayment(
//         uint256 tokenId,
//         string memory tokenType,
//         address buyer
//     ) public view virtual returns (uint256) {
//         return paymentModule.checkRegisterPayment(tokenId, buyer, tokenType);
//     }

//     function reversePayment(uint256 tokenId, string memory tokenType) public virtual nonReentrant returns (bool) {
//         uint256 payment = checkPayment(tokenId, tokenType, _msgSender());
//         require(payment > 0, 'No payment registered');

//         bool success;
//         if (_isEthToken(tokenType)) {
//             //ETH reverse payment
//             (success, ) = _msgSender().call{value: payment}('');
//             require(success, 'Ether payout issue');
//         } else {
//             //ERC20 reverse payment
//             success = IERC20(allowedToken[tokenType]).transfer(_msgSender(), payment);
//             require(success, 'ERC20 transfer failed');
//         }
//         paymentModule.removeRegisterPayment(_msgSender(), tokenId);

//         return success;
//     }

//     //COMPARE safeTransferFrom to executePayment //TODO
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes memory data
//     ) public override {
//         (
//             address _seller,
//             address _buyer,
//             address _receiver,
//             uint256[] memory _tokenIds,
//             string memory _tokenType,
//             uint256 _payment, /*address _tokenTypeAddress*/
//             ,
//             uint256 _chainId
//         ) = abi.decode(data, (address, address, address, uint256[], string, uint256, address, uint256));

//         require(_seller == from, 'Seller not From address');
//         require(_receiver == to, 'Receiver not To address');
//         require(_tokenIds[0] == tokenId, 'Wrong NFT listing');
//         require(_chainId == block.chainid, 'Transfer on wrong Blockchain');

//         //check register payment
//         //FIX??? //TODO
//         require(false,"fixthis");
//         // require(paymentModule.checkRegisterPayment(_buyer, _tokenIds, _payment, _tokenType));

//         _requireExistsAndOwned(_tokenIds, _seller);

//         //remove register payment
//         paymentModule.removeRegisterPayment(to, tokenId);

//         //Transfer token
//         _safeTransferFrom(from, to, tokenId, data);
//     }

    function _safeTransferFrom(
        address from,
        address to,
        uint256, /*tokenId*/
        bytes memory data
    ) internal virtual {
        (, , , uint256[] memory _tokenIds, string memory tokenType, uint256 payment, address _tokenTypeAddress, ) = abi.decode(
            data,
            (address, address, address, uint256[], string, uint256, address, uint256)
        );

        require(allowedToken[tokenType] != address(0x0), 'Unsupported token type');

        if (_isEthToken(tokenType)) {
            //Royalty pay in ether
            require(_tokenTypeAddress == address(this), 'token address must be contract');
        }

        //Get payments split
        // uint256[] memory _payments = royaltyModule.splitSum(payment, _tokenIds.length);

        // for (uint256 i = 0; i < _tokenIds.length; i++) {
        //     //Distribute royalty payment
        //     royaltyModule.distributePayment(_tokenIds[i], _payments[i]);

        //     //base transfer after royalty pay
        //     _approve(to, _tokenIds[i]);
        //     //super.safeTransferFrom(from, to, _tokenId, data);

        //     //give to address minter role unless it has it already -- new in ver 1.3
        //     _grantRole(MINTER_ROLE, to);

        //     //Force royalty payout for old account
        //     uint256 balance = royaltyModule.getBalance(_tokenIds[i], payable(from));
        //     if (balance > 0) _royaltyPayOut(_tokenIds[i], payable(from), payable(from), balance);

        //     //Transfer RA ownership
        //     royaltyModule.transferRAOwnership(from, _tokenIds[i], to);
        // }

        // paymentModule.removeListNFT(_tokenIds[0]);
    }

//     receive() external payable {}

//     fallback() external payable {
//         // decode msg.data to decide which transfer route to take
//         (address seller, uint256[] memory tokenIds, address receiver, int256 trxntype) = abi.decode(msg.data, (address, uint256[], address, int256));

//         _requireExistsAndOwned(tokenIds, seller);

//         paymentModule.isValidPaymentMetadata(seller, tokenIds, msg.value, 'ETH');
//         //decide which transfer path to go based on trxntype (0 = direct purchase, 1 = exchange purchase)
//         if (trxntype == 1) {
//             //register payment for exchange based purchases which require a separate, external call to safeTransferFrom function
//             paymentModule.addRegisterPayment(_msgSender(), tokenIds, msg.value, 'ETH');
//         } else if (trxntype == 0) {
//             //encode payment data for transfer(s)
//             bytes memory data = abi.encode(seller, _msgSender(), receiver, tokenIds, 'ETH', msg.value, address(this), block.chainid);

//             //transfer NFT(s)
//             _safeTransferFrom(seller, _msgSender(), tokenIds[0], data);
//         } else {
//             //if the trxn type is not supported then we need to revert the entire transaction.
//             revert('Trxn type not supported');
//         }
//     }

    function royaltyPayOut(
        uint256 tokenId,
        address RAsubaccount,
        address payable payoutAccount,
        uint256 amount
    ) public virtual returns (bool) {
        require(_msgSender() == RAsubaccount, 'Sender must be subaccount owner');
        return _royaltyPayOut(tokenId, RAsubaccount, payoutAccount, amount);
    }

    function _royaltyPayOut(
        uint256 tokenId,
        address RAsubaccount,
        address payable payoutAccount,
        uint256 amount
    ) internal virtual returns (bool) {
        // royaltyModule.checkBalanceForPayout(tokenId, RAsubaccount, amount);
        // string memory tokenType = royaltyModule.getTokenType(tokenId);
        // //Reentrancy defence
        // royaltyModule.withdrawBalance(tokenId, RAsubaccount, amount);

        // //payout in Ether
        // if (_isEthToken(tokenType)) {
            (bool success, ) = payoutAccount.call{value: amount}('');
            require(success, 'Ether payout issue');
        // }
        // //payout in tokens
        // else {
        //     bool success = IERC20(allowedToken[tokenType]).transfer(payoutAccount, amount);
        //     require(success, 'ERC20 transfer failed');
        // }

        return true;
    }
}


//METHODOLOGY: RUNTIME TEST MATRIX and DEBUGGING:
// - CALL DISTRIBUTE PAYMENT TESTS via executePayment USER-INTERFACE.
//Avoids: RBT.safeTransferFrom and RBT.TransferFrom
// CALLSTACK: RBT.executePayment() > RBT._safeTransferFrom()  

//MOCK DATA to executePayment(
        // address receiver,
        // address seller,
        // uint256[] calldata tokenIds,
        // uint256 payment,
        // string calldata tokenType,
        // int256 trxntype
        //)


//ENTRY POINT: royaltyPayOut()
        // uint256 tokenId,
        // address RAsubaccount,
        // address payable payoutAccount,
        // uint256 amount

//END METHODLOGY

//BACKUP- algorithm 
        // for (uint256 i = 0; i < _royaltysubaccounts[royaltyAccount].length; i++) {
        //     //skip calculate for 0% subaccounts
        //     if (_royaltysubaccounts[royaltyAccount][i].royaltySplit == 0) continue;
        //     //calculate royalty split sum
        //     uint256 paymentSplit = mulDiv(remainsValue, _royaltysubaccounts[royaltyAccount][i].royaltySplit, remainsSplit);
        //     remainsValue -= paymentSplit;
        //     remainsSplit -= _royaltysubaccounts[royaltyAccount][i].royaltySplit;
        //     //distribute if IND subaccount
        //     if (_royaltysubaccounts[royaltyAccount][i].isIndividual == true) {
        //         _royaltysubaccounts[royaltyAccount][i].royaltyBalance += paymentSplit;
        //         emit RoyalyDistributed(tokenId, _royaltysubaccounts[royaltyAccount][i].accountId, paymentSplit, assetId);
        //     }
        //     //distribute if RA subaccounts
        //     else {
        //         _distributePayment(_royaltysubaccounts[royaltyAccount][i].accountId, paymentSplit, tokenId);
        //     }
        // }
//ENDBACKUP