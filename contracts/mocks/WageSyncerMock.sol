pragma solidity ^0.6.6;

import "../../interfaces/IWageSyncer.sol";

//Mock Syncer used to test Wage's contract
contract WageSyncerMock is IWageSyncer {
    
    bool public calledSync;
    bool public calledAdd;
    bool public calledRemove;

    function sync() external override {
        calledSync = true;
    }
    
    function addPair(address addr, bytes calldata data) external override {
        calledAdd = true;
    }
    
    function removePair(address addr) external override {
        calledRemove = true;
    }

    function reset() external {
        calledSync = false;
        calledAdd = false;
        calledRemove = false;
    }
    
}