//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0;
contract Timelock{
    error queuedError(bytes32);
    error TimestampNotInTheRangeError(uint,uint);
    error NotqueuedError(bytes32 txId);
    error  TimestampNotPassedError(uint ,uint);
    error TimestampExpired(uint);
    error transactionFailedError(bytes);
    event que(address  target,
    uint value,
    string  func,
    bytes  data,
    uint timestamp);
    //create txid;
    //txis is unique;
    //check timestamp
    //queue tx
    address public owner;
    constructor(){
        owner=msg.sender;
    }
    receive() external payable{}
    modifier onlyowner(){
        require(msg.sender==owner);
        
        _;
    }
    mapping(bytes32=>bool)public queued;

    uint public MIN_DELAY=10;
    uint public MAX_DELAY=1000;
    uint GRACE_PERIOD=1000;

    function getTxId(address  target,
    uint value,
    string memory func,
    bytes memory  data,
    uint timestamp)public pure returns(bytes32){
        return keccak256(abi.encode(target,value,func,data,timestamp));

    }
    function queue(address  target,
    uint value,
    string memory func,
    bytes memory  data,
    uint timestamp)external  onlyowner{
        bytes32  txId=getTxId(target,value,func,data,timestamp);
        if(queued[txId]){
            revert queuedError(txId);

        }
        if(timestamp<block.timestamp+MIN_DELAY||timestamp>block.timestamp+MAX_DELAY){
            revert TimestampNotInTheRangeError(timestamp,block.timestamp);
        }
        queued[txId]=true;
        emit que(target, value,func, data,timestamp);
    }

    function execute(address  target,
    uint _value,
    string memory func,
    bytes memory _data,
    uint timestamp)public payable onlyowner{
        bytes32 txId=getTxId(target,_value,func,_data,timestamp);
        if(!queued[txId]){
            revert NotqueuedError(txId);

        }
        if(block.timestamp<timestamp){
            revert TimestampNotPassedError(block.timestamp,timestamp);
        }
        if(block.timestamp>timestamp+GRACE_PERIOD){
            revert TimestampExpired(timestamp);
        }
        queued[txId]=false;
        bytes memory data;
        if(bytes(func).length>0){
            data=abi.encodePacked(
               bytes4(keccak256(bytes(func))),_data
            );

        }
        else{
            data=_data;
        }
        (bool ok,bytes memory re)=target.call{value:_value}(data);
        if(!ok){
            revert transactionFailedError(re);
        }

    }
}
contract testTimelock{
    address public timelock;
    constructor(address  _timelock){
        timelock=_timelock;
    }
   receive() external payable{}
    function test() external payable{
        require(msg.sender==timelock,"not timelock");
       
    }
    function getTimestamp()public view returns(uint){
        return block.timestamp+100;

    }


}