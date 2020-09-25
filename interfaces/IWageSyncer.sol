pragma solidity ^0.6.0;

interface IWageSyncer {
    
    /**
     * @dev Event emitted after a successful sync.
     */ 
    event WageSync();
    /**
     * @dev Event emitted when adding a new trading pair.
     * @param pairAddress the pair's address
     * @param callData data needed to perform the low level call
     */ 
    event PairAdded(address pairAddress, bytes callData);
    /**
     * @dev Event emitted when removing a trading pair.
     * @param pairAddress the pair's address
     */ 
    event PairRemoved(address pairAddress);
    
     /**
     * @dev The sync function. Called by Wage's contract after each rebase.
     * This function has been designed to support future trading pairs on different dexes.
     * We are sending a low level function call to apply the same syncing logic to every pair
     */ 
    function sync() external;
    /**
     * @dev Adds a pair to the pairs array. Can only be called  by the owner
     * @param pairAddress the pair's address.
     * @param data the data to send when calling the low level function `functionCall`
     */ 
    function addPair(address pairAddress, bytes calldata data) external;
    /**
     * @dev Removes a pair from tthe pairs array. Can  only be called by the owner.
     * @param pair the pair's address
     */ 
    function removePair(address pair) external;
    
}