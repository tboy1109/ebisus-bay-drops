// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: Querty

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                       @@.                              //       
//                                       @@@@@@@@@@                       //       
//                                       @@@@@@@@@@@@@                    //       
//                            @@@@@@@@@  @@@@@@@@@@@@@@                   //       
//                         @@@@@@@@@@@@  @@@@@@@@@@@@@@@@                 //       
//                       @@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@                //       
//                      @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@                //       
//                     @@@@@@@       @@  @@@@@  @@@@@@@@@@                //       
//              @@@@@  @@@@                          @@@@@                //       
//             @@@@@@@@@@    *@@@@           @@@@@     @@@@               //       
//             @@@@@@@@@@      @@@  @      @  @@@      @@@@@@             //       
//             @@@@@@@@@@                              @@@@@@@            //       
//              @@@@@@@@@@@                           @@@@@@@@            //       
//               @@@@@@@@@@@@@ @@@ @@@@      @@@    @@@@@@@               //       
//                    @@@@@@@@@@   /@    @@@  @@@@@@@@@@@@@@              //       
//                      @@@@@@@              @@  @@@@@@@@@@@@             //       
//                        @@@@@                   @@@@@@@@@@@             //       
//                          @@                    @@@@@@@@@@@             //       
//                          @@                    (@@@@@@@@@@             //       
//                          @@@ @@@@@@@@@@@@@@@%  @@@@@@@@@@              //       
//                           @@@                 @@@@@@@@@@               //       
//                             @@@@             @@@@@@@                   //       
//                                 @@@@    @@@@@@@@@                      //       
//                                       @@@@@@@                          //
//                                                                        //
////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./Withdraw.sol";
import "./IDrop.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";


contract CronosGorillaBusiness is ERC721Enumerable, Ownable, Withdraw, IDrop, PullPayment {
    using Strings for uint256;
    using SafePct for uint256;
    

    uint256 public supplyRemaining;
    uint128 constant MAX_SUPPLY = 6100;
    uint128 constant internal SCALE = 10000;
    uint128 constant internal FEE = 1000;
    int8 public constant MAX_PER_FACTION = 5;
    int8 public constant MAX_WL = 5;
    int8 public constant MAX_PUBLIC = 15;

    uint256 public FOUNDING_MEMBERS_PRICE = 350 ether;

    string public baseURI;

    address[] public eligibleAddresses;

    struct Sale {
        uint64 start;
        uint64 end;
        int16 maxPerWallet;
        uint8 maxPerTx;
        uint256 price;
        bool paused;
    }

    struct Faction {
        uint256 supply;
        uint256 supplyRemaining;
        uint256 firstTokenID;
        uint16 maxPerFaction;
    }

    ERC1155 memberships;

    mapping(string => Sale) public sales;
    mapping(bytes32 => Faction) public factions;
    mapping(address => bool) whitelistedAddresses;
    mapping(string => mapping(address => uint16)) balanceSale;
    mapping(bytes32 => mapping(address => uint16)) balanceFaction;
    mapping(uint256 => uint256) private assignOrders;

    event EventSaleChange(string _name, Sale _sale);
    event EventCGBMinted(uint[] tokenIds, address buyer);

    constructor(string memory _initBaseURI, ERC1155 _contract) ERC721 ("Cronos Gorilla Business", "CGB") {
        setBaseURI(_initBaseURI);
        supplyRemaining = MAX_SUPPLY;
        setFoundingMemberContract(_contract);
        setSale("PRESALES", Sale(1646406830, 1646407250, MAX_WL, 5, 325 ether, false));
        setSale("PUBLIC", Sale(1646409650, 1956776400, MAX_PUBLIC, 5, 390 ether, false));
        setFaction("MAFIA", Faction(1000, 1000, 1, 1));
        setFaction("AQUA", Faction(1700, 1700, 1001, 5));
        setFaction("IGNIS", Faction(1700, 1700, 2701, 5));
        setFaction("TERRA", Faction(1700, 1700, 4401, 5));
    }

    //**************************//
    //          MODIFIER        //
    //**************************//
    modifier isOpen(string memory _name, uint256 _count) {
        require(saleIsOpen(_name), "Sales not open");
        require(_count > 0, "Can not mint 0 NFT");
        require(_count <= supplyRemaining, "Exceeds maximum supply. Try to mint less NFTs");
        require(supplyRemaining > 0, "Collection is Sold Out");
        require(_count <= sales[_name].maxPerTx, "Max per tx limit");
        require(int16(balanceSale[_name][_msgSender()] + uint16(_count)) <= int16(sales[_name].maxPerWallet), "Max per wallet limit");
        if (block.timestamp > sales["PRESALES"].end && isMember(_msgSender())) {
            require(msg.value >= FOUNDING_MEMBERS_PRICE * _count, "Insuficient funds");
        } else {
            require(msg.value >= sales[_name].price * _count, "Insuficient funds");
        }
        balanceSale[_name][_msgSender()] += uint16(_count);
        _;
    }

    modifier isNotSoldOut(bytes32 _name, uint256 _count) {
        require(keccak256(abi.encodePacked((_name))) != keccak256(abi.encodePacked(bytes32(("MAFIA")))), "Can not mint Mafia Faction");
        require(_count > 0, "Can not mint 0 NFT");
        require(_count <= uint256(factions[_name].maxPerFaction), "Max per faction limit");
        require(factions[_name].supplyRemaining > 0, "Faction supply is Sold Out");
        require(factions[_name].supplyRemaining >= _count, "Exceeds maximum faction supply. Try to mint less NFTs");
        require(int16(balanceFaction[_name][_msgSender()] + uint16(_count)) <= int16(factions[_name].maxPerFaction), "Max per wallet limit (Faction)");
        balanceFaction[_name][_msgSender()] += uint16(_count);
        _;
    }

    //**************************//
    //          SALES           //
    //**************************//
    function setSale(string memory _name, Sale memory _sale) public onlyOwner {
        sales[_name] = _sale;
        emit EventSaleChange(_name, _sale);
    }

    function pauseSale(string memory _name, bool _pause) public onlyOwner {
        sales[_name].paused = _pause;
    }

    function saleIsOpen(string memory _name) public view returns (bool) {
        return sales[_name].start > 0 && block.timestamp >= sales[_name].start && block.timestamp <= sales[_name].end && !sales[_name].paused;
    }

    function setFoundingMemberContract(ERC1155 _contract) public onlyOwner {
        memberships = _contract;
    }

    //*****************************//
    //          FACTIONS           //
    //*****************************//
    function setFaction(bytes32 _name, Faction memory _factionName) public onlyOwner {
        factions[_name] = _factionName;
    }

    //**************************//
    //          GETTERS         //
    //**************************//
    function isWhitelisted(address _user) public view returns (bool) {
        bool userIsWhitelisted = whitelistedAddresses[_user];
        return userIsWhitelisted;
    }

    function isMember(address _address) public view returns (bool) {
        return memberships.balanceOf(_address, 1) > 0 || memberships.balanceOf(_address, 2) > 0;
    }

    function isEligibleAirdrop(address _user) public view returns (bool) {
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            if (eligibleAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function getWalletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function getBalanceOfOwner(address _owner) public view returns (uint256) {
        uint256[] memory tokenIds = getWalletOfOwner(_owner);
        uint256 numberOfGorillas = tokenIds.length;
        return numberOfGorillas;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function minted(string memory _name, address _wallet) public view returns (uint16) {
        return balanceSale[_name][_wallet];
    }

    function mintedFaction(bytes32 _factionName, address _wallet) public view returns (uint16) {
        return balanceFaction[_factionName][_wallet];
    }

    function getMafiaSupplyRemaining() public view returns (uint256) {
        return factions["MAFIA"].supplyRemaining;
    }

    function getAquaSupplyRemaining() public view returns (uint256) {
        return factions["AQUA"].supplyRemaining;
    }

    function getIgnisSupplyRemaining() public view returns (uint256) {
        return factions["IGNIS"].supplyRemaining;
    }

    function getTerraSupplyRemaining() public view returns (uint256) {
        return factions["TERRA"].supplyRemaining;
    }

    //**************************//
    //          SETTERS         //
    //**************************//
    function batchWhitelist(address[] memory _users) public onlyOwner {
        for(uint256 i=0; i < _users.length; i++){
            address user = _users[i];
            whitelistedAddresses[user] = true;
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function setEligibleAirdrop(address[] calldata _users) public onlyOwner {
        delete eligibleAddresses;
        eligibleAddresses = _users;
    }

    //**************************//
    //          MINT            //
    //**************************//

    function preSalesMint(uint256 _count, bytes32 _factionName) internal isOpen("PRESALES", _count) isNotSoldOut(_factionName, _count) {
        require(isWhitelisted(_msgSender()), "User not whitelisted");
        require(int16(balanceSale["PRESALES"][_msgSender()]) <= MAX_WL, "Max per wallet limit (PRESALES)");
        require(int16(balanceFaction[_factionName][_msgSender()]) <= MAX_PER_FACTION, "Max per faction limit");
        _mintCMB(_count, _factionName);
    }

    function publicSalesMint(uint256 _count, bytes32 _factionName) internal isOpen("PUBLIC", _count) isNotSoldOut(_factionName, _count) {
        if(isWhitelisted(_msgSender())) {
            require(int16(balanceSale["PRESALES"][_msgSender()] + balanceSale["PUBLIC"][_msgSender()]) <= MAX_PUBLIC, "Max per wallet limit");
        }
        _mintCMB(_count, _factionName);
    }

    function teamMint(uint256 _amount, bytes32 _factionName) public onlyOwner {
        uint[] memory tokenIdsBought = new uint[](_amount);
        uint256 gorillaIndex = factions[_factionName].firstTokenID;
        for (uint i = 0; i < _amount; i++) {
            _safeMint(_msgSender(), gorillaIndex);
            tokenIdsBought[i] = gorillaIndex;
            factions[_factionName].firstTokenID++;
            factions[_factionName].supplyRemaining--;
            supplyRemaining--;
            gorillaIndex++;
        }

        emit EventCGBMinted(tokenIdsBought, _msgSender());
    }

    function _mintCMB(uint256 _amount, bytes32 _factionName) private {
        uint[] memory tokenIdsBought = new uint[](_amount);
        uint256 gorillaIndex = factions[_factionName].firstTokenID;
        uint totalCost;
        if(saleIsOpen("PUBLIC") && isMember(_msgSender())) {
            totalCost = _amount * FOUNDING_MEMBERS_PRICE;
        } else if (saleIsOpen("PUBLIC") && !isMember(_msgSender())) {
            totalCost = _amount * sales["PUBLIC"].price;
        } else {
            totalCost = _amount * sales["PRESALES"].price;
        }
        uint mintFee = totalCost.mulDiv(FEE, SCALE);
        _asyncTransfer(0x454cfAa623A629CC0b4017aEb85d54C42e91479d, mintFee);

        for (uint i = 0; i < _amount; i++) {
            _safeMint(_msgSender(), gorillaIndex);
            tokenIdsBought[i] = gorillaIndex;
            factions[_factionName].firstTokenID++;
            factions[_factionName].supplyRemaining--;
            supplyRemaining--;
            gorillaIndex++;
        }

        emit EventCGBMinted(tokenIdsBought, _msgSender());
    }

    //*******************************//
    //          INTERFACE            //
    //*******************************//
    function mintCost(address _minter) external override view returns(uint256) {
        if(saleIsOpen("PRESALES") && isWhitelisted(_minter)) {
            return sales["PRESALES"].price;
        } else if (saleIsOpen("PUBLIC") && !isMember(_minter)) {
            return sales["PUBLIC"].price;
        } else if (saleIsOpen("PUBLIC") && isMember(_minter)) {
            return FOUNDING_MEMBERS_PRICE;
        }
    }

    function maxSupply() external override pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function canMint(address _minter) external override view returns (uint256, uint256, uint256) {
        if(saleIsOpen("PRESALES") && isWhitelisted(_minter)) {
            return(factions["AQUA"].maxPerFaction - balanceFaction["AQUA"][_minter], factions["IGNIS"].maxPerFaction - balanceFaction["IGNIS"][_minter], factions["TERRA"].maxPerFaction - balanceFaction["TERRA"][_minter]);
        } else if (saleIsOpen("PRESALES") && !isWhitelisted(_minter)) {
            return (0, 0, 0);
        } else if (saleIsOpen("PUBLIC")) {
            return(factions["AQUA"].maxPerFaction - balanceFaction["AQUA"][_minter], factions["IGNIS"].maxPerFaction - balanceFaction["IGNIS"][_minter], factions["TERRA"].maxPerFaction - balanceFaction["TERRA"][_minter]);
        }
    }

    function mint(uint256 _amount, bytes32 _faction) external override payable {
        require(saleIsOpen("PRESALES") || saleIsOpen("PUBLIC"),"Sales are not open");
        if(saleIsOpen("PRESALES")) {
            preSalesMint(_amount, _faction);
        } else if (saleIsOpen("PUBLIC")) {
            publicSalesMint(_amount, _faction);
        }
    }

    function getInfo() external override view returns (Info memory, SupplyRemainingPerFaction memory)  {
        return (Info(sales["PUBLIC"].price, FOUNDING_MEMBERS_PRICE, sales["PRESALES"].price, MAX_SUPPLY, totalSupply(), 15, 5), 
        SupplyRemainingPerFaction(factions["TERRA"].supplyRemaining, factions["AQUA"].supplyRemaining, factions["IGNIS"].supplyRemaining)); 
    }

    //*****************************************//
    //          AIRDROP MAFIA FACTION          //
    //*****************************************//
    function airdrop() public onlyOwner {
        uint256[] memory tokens = getWalletOfOwner(owner());
        require(tokens.length == eligibleAddresses.length, "Number of tokens is different than number of eligible addressses");
        for(uint256 i = 0; i < eligibleAddresses.length; i++) {
            safeTransferFrom(owner(), eligibleAddresses[i], tokens[i]);
        }
    }
}