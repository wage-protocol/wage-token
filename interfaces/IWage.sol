pragma solidity ^0.6.0;

interface IWage {
    
    /**
    * @dev Event emitted when enabling transfers
    */
    event TransfersEnabled();
    
    /**
    * @dev Event emitted on each rebase
    * @param epoch The rebase timestamp
    * @param totalSupply the new totalSupply after the rebase
    */
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    /**
    * @dev Event emitted when enabling transfers
    * @param enabled Whether rebases have been enabled or disabled
    */
    event RebaseToggled(bool enabled);
    /**
     * @dev Event emitted when the rebase rate changes 
     * @param newRate the new rabase rate
     * @param oldRate the old rebase rate
     */
    event RebaseRateChanged(uint256 newRate, uint256 oldRate);
    /**
     * @dev Event emitted when the rebase amount changes
     * @param newAmount the new supply increase applied for each rebase
     * @param oldAmount the old supply increase
     */
    event RebaseAmountChanged(uint256 newAmount, uint256 oldAmount);
    
    /**
     * @dev Event emitted when changing syncer
     * @param newSyncer the new syncer's address
     * @param oldSyncer the old syncer's address
     */
    event WageSyncerChanged(address newSyncer, address oldSyncer);
    
    /**
     * @dev Event emitted when locking tokens.
     * @dev We are locking gons, not fragments - this causes the locked amount to change after each rebase.
     * @param target the address whose tokens have been locked
     * @param initialAmount the initial amount of tokens locked
     */
    event TokensLocked(address target, uint256 initialAmount);
    /**
     * @dev Event emitted when unlocking tokens.
     * @param target the address whose tokens have been unlocked
     * @param initialAmount the initial amount of tokens unlocked
     */
    event TokensUnlocked(address target, uint256 initialAmount);
    
    /**
     * @dev Enables transfers when called. Once enabled, transfers cannot be disabled.
     */ 
    function enableTransfers() external;

    /**
     * @dev Notifies Fragments contract about a new rebase cycle. Can only be called by the contract owner
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 supplyDelta) external returns (uint256);
    /**
     * @dev Toggles rebases. Can only be called by the owner
     * @param enabled Whether to enable or disable rebases
     */ 
    function toggleRebase(bool enabled) external;
    /**
     * @dev Changes the amount of time between each rebase. Can only be called by the owner
     * @param newRate the new rebase rate (seconds)
     */ 
    function changeRebaseRate(uint256 newRate) external;
    /**
     * @dev Changes the inflation amount after each rebase. Can only be called by the owner
     * @param newAmount the new inflation amount
     */ 
    function changeRebaseAmount(uint256 newAmount) external;

    /**
     * @dev Sets a new syncer smart contract. Can only be called by the owner.
     * Syncers are used to sync trading pairs across dexes.
     * @param newSyncer the address of the new syncer smart contract
     */ 
    function changeWageSyncer(address newSyncer) external;
    
    /**
     * @dev Returns the gons per fragment rate. Can only be called by the owner.
     * @return the gons per fragment rate
     */
    function gonsPerFragment() external view returns (uint256);
    
    /**
     * @dev Locks part of an address' gon balance. Needed for governance.
     * The amount of locked fragments inflates after each rebase.
     * @param target The target address
     * @param gonAmount the amount of gons to lock
     */
    function lock(address target, uint256 gonAmount) external;
    /**
     * @dev Unlocks part of an adress' locked gon balane. Needed for governance.
     * @param target The target address
     * @param gonAmount the amount of gons to unlock
     */
    function unlock(address target, uint256 gonAmount) external;
    
    /**
     * @dev Returns the current locked fragments for an address
     * @param target the address
     */ 
    function getLockedFragments(address target) external view returns (uint256);
    
    
    
}