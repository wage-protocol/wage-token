pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWageSyncer.sol";

//The WageSyncer contract.
//Syncs trading pairs across different exchanges.
contract WageSyncer is IWageSyncer, Ownable {
    
    using Address for address;
    
    /**
     * @dev Event emitted after a successful sync.
     */ 
    event WageSync();
    /**
     * @dev Event emitted when adding a new trading pair.
     * @param pairAddress the pair's address
     * @param callData data needed to perform the low level call
     */ 
    event PairAdded(address indexed pairAddress, bytes callData);
    /**
     * @dev Event emitted when removing a trading pair.
     * @param pairAddress the pair's address
     */ 
    event PairRemoved(address indexed pairAddress);
    
    /**
     * @dev Struct that holds the data needed to sync a trading pair.
     * @field pairAddress the pair's address
     * @field syncData the data needed to sync the pair.
     */
    struct Pair {
        address pairAddress;
        bytes syncData;
    }
    
    Pair[] public pairs;
    
    /**
     * @dev The sync function. Called by Wage's contract after each rebase.
     * This function has been designed to support future trading pairs on different dexes.
     * We are sending a low level function call to apply the same syncing logic to every pair
     */ 
    function sync() external override {
        for (uint i = 0; i < pairs.length; i ++) {
            pairs[i].pairAddress.functionCall(pairs[i].syncData);
        }
        
        emit WageSync();
    }
    
    
    /**
     * @dev Adds a pair to the pairs array. Can only be called  by the owner
     * @param addr the pair's address.
     * @param syncData the data to send when calling the low level function `functionCall`
     */ 
    function addPair(address addr, bytes calldata syncData) external override onlyOwner {
        Pair storage pair = pairs.push();
        
        pair.pairAddress = addr;
        pair.syncData = syncData;
        
        emit PairAdded(addr, syncData);
    }    
    
    
    /**
     * @dev Removes a pair from tthe pairs array. Can  only be called by the owner.
     * @param pairAddress the pair's address
     */ 
    function removePair(address pairAddress) external override onlyOwner {
        (bool res, uint256 index) = _findPair(pairAddress);
        
        require(res, "Pair not found");
        
        delete pairs[index];
        
        emit PairRemoved(pairAddress);
    }
    
    /**
     * @dev Finds a pair in the pairs array.
     * @param pair The pair to find
     * @return bool Whether the pair was found
     * @return uint256 The index of the pair if is present in the array, 0 if not
     */ 
    function _findPair(address pair) internal view returns (bool, uint256) {
        for (uint i = 0; i < pairs.length; i ++) {
            if (pairs[i].pairAddress == pair)
                return (true, i);
        }
        
        return (false, 0);
    }
    
}