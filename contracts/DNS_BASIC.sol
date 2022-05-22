// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.6;
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";


import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "http://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol"; 


//DNRS-domain Name Registration System

contract DNS is Ownable{

    using SafeMath for uint;
    uint lockamount=0.005 ether; //amount to lock
    uint lockperiod= 365 days;  //timeperiod to lock(for testing we can change it to "1 minutes"
    uint priceperchar=0.0005 ether; //fees to calulate price of each char in domainname
    uint feesamount=0;              //fess amount to register domainname
    uint constant MIN_LEN = 3; //min length of domain  name should be 3 chars
    uint constant MAX_LEN = 20;//max length of domain  name should be 3 chars
   

    //domain Name structure 
    struct domainName
    {
        string name;
        uint expirydate;
        address owner;
        uint lockedBal;
    }

    //mapping of domain names 
    mapping(string=>domainName) domainNames;

    //Events for vaious functions
    event domainNameRegistered(string name, address owner, uint256 indexed timestamp);
	event domainNameRenewed(string name, address owner, uint256 indexed timestamp);
	event AmountUnlocked(string name, uint256 indexed timestamp);
    



   //modifier to check calling from domainName owner or not
    modifier isNameOwner(string memory _vName)
    {
        string memory vNameHash = bytes32ToString(encrypt(_vName));
        require(domainNames[vNameHash].owner==msg.sender && domainNames[vNameHash].expirydate > block.timestamp,"You are not the Owner of this domain Name");
        _;
    }

     //modifier to check if name is available to register or not
    modifier isNameAvailable(string memory _vName) 
    {
        string memory vNameHash = bytes32ToString(encrypt(_vName));
        require(domainNames[vNameHash].expirydate < block.timestamp || domainNames[vNameHash].expirydate == 0,"domain Name is not Available");
        _;
    }

    //modifier to check funds are sufficient to register the domainName or not
    //total amount = fees(vName)+lockamount
    modifier isMoneyAvailable(string memory _vName)
    {
        uint namePrice=calculatePrice(_vName);
        uint finalAmt=lockamount.add(namePrice);

        require(msg.value>=finalAmt,"Insufficent funds");

        _;
    }
    //modifier to check size of the domainName
    //min_len=3 chars and max_len=20 chars
    modifier isValidName(string memory _vName)
    {
        
        require(bytes(_vName).length>=MIN_LEN && bytes(_vName).length <=MAX_LEN,"domain Name size must be >=3 and <=20");
    _;
    }

    //function to encrypt vName for mapping
    function encrypt(string memory _vName) public view returns (bytes32)
    {
        return keccak256(abi.encodePacked(_vName));
    }
    //funciton to calculate total fees to register domainName
    function calculatePrice(string memory _vName) public view returns(uint)
    {
        uint namePrice=bytes(_vName).length.mul(priceperchar);
        return namePrice;
    }

    //function to convert bytes32 to string data
  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    //function to register domainname
    //3 conditons must be satisfied in order to register domain name
    //isValidName,isNameAvailable,isMoneyAvailable
    function regiterdomainName(string memory _vName) public payable isValidName(_vName) isNameAvailable(_vName) isMoneyAvailable(_vName)
    {
        string memory vNameHash= bytes32ToString(encrypt(_vName));
        uint finalPrice=calculatePrice(_vName);
        
        domainName memory vname = domainName({
            name:_vName,
            expirydate: block.timestamp + lockperiod,
            owner:msg.sender,
            lockedBal:msg.value.sub(finalPrice)
        });

        domainNames[vNameHash]=vname;
        address payable _owner = payable(owner());
        feesamount=msg.value;
        bool success=_owner.send(feesamount);
        feesamount=0;
        require(success,"Error sending fees to owner");

        
        emit domainNameRegistered(_vName,msg.sender,block.timestamp);

        
    }

    //function to renewdomainName
    //allowed to call only from owner of domainname with sufficient funds
    function renewdomainName(string memory _vName) public payable isNameOwner(_vName) isMoneyAvailable(_vName)
    {
         string memory vNameHash=bytes32ToString(encrypt(_vName));
         uint finalPrice=calculatePrice(_vName);

        require(msg.value==finalPrice.add(lockamount),"Insuffient funds to renew domain Name");
        domainNames[vNameHash].expirydate+=lockperiod;
        address payable _owner = payable(owner());
        feesamount=msg.value;
        bool success=_owner.send(feesamount);
        feesamount=0;
        require(success,"Error sending fees to owner");

        emit domainNameRenewed(_vName,msg.sender,block.timestamp);

    }

    //function to release funds hold while registration 
    //domainName must be expired inorder to unlock locked amount
    function unLockAmount(string memory _vName) public
    {
         string memory vNameHash=bytes32ToString(encrypt(_vName));
        require(domainNames[vNameHash].owner == msg.sender ,"You are not the owner of domain Name");
         require(domainNames[vNameHash].lockedBal > 0,"Nothing to unlock");
         require(domainNames[vNameHash].expirydate <  block.timestamp ,"Expiry date is not due can't unlock funds" );
        
        address payable _sender = payable(msg.sender);
        feesamount=domainNames[vNameHash].lockedBal;
        domainNames[vNameHash].lockedBal=0;
        _sender.transfer(feesamount);
       
        emit AmountUnlocked(_vName,block.timestamp);
    }



        //function to set amount to lock 
    //allowed to call this only by deployer of contract
    function setLockAmount(uint _lockamount) public onlyOwner{
        lockperiod=_lockamount;
    }
    
    //function to set timeperiod  to lock  domainName  
    //allowed to call this only by deployer of contract
    function setLockPeriod(uint _lockperiod) public onlyOwner{
        lockperiod=_lockperiod;
    }

    //function to change prices per chhar of fees for registration  
    //allowed to call this only by deployer of contract
    function setPriceperChar(uint _price) public onlyOwner{
        priceperchar=_price;
    }

    //returns lock amount 
    function getLockAmount() public view returns(uint)
    {
        return lockamount;
    }
    //returns lockperiod
    function getLockPeriod() public view returns(uint)
    {
        return lockperiod;
    }
    //returns prices per char for calculation of fees
    function getPriceperChar() public view returns(uint)
    {
        return priceperchar;
    }
    
   
}