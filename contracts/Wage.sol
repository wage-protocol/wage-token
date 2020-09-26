pragma solidity ^0.6.0;

import "@hq20/contracts/contracts/access/AuthorizedAccess.sol";
import "./ERC20.sol";

import "../interfaces/IWage.sol";
import "../interfaces/IWageSyncer.sol";

contract Wage is IWage, ERC20, AuthorizedAccess {
    
    using SafeMath for uint256;
    
    uint256 private constant MAX_UINT256 = 2 ** 256 - 1;
    uint128 private constant MAX_SUPPLY = 2 ** 128 - 1;
    
    uint256 private _gonsPerFragment;
    
    mapping(address => uint256) private _lockedGons;
    
     // Union Governance / Rebase Settings
    uint256 public nextReb; // when's it time for the next rebase?
    uint256 public rebaseAmount = 1e18; // initial is 1
    uint256 public rebaseRate = 10800; // initial is every 3 hours
    bool public rebState; // Is rebase enabled?
    uint256 public rebaseCount = 0;
    
    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private immutable TOTAL_GONS;
    
    //Blocks token transfers when set to false
    bool public _transfersEnabled;
    
    //The address of the wage syncer.
    //Used to sync trading pairs across different exchanges.
    IWageSyncer public _syncer;
    
    
    constructor(string memory name, string memory symbol, uint256 initialSupply, bool shouldEnableTransfers) ERC20(name, symbol) public {
        //A temporary variaable is necessary here.
        //Solidity doesn't allow reading from an immutable variable during contract initialization
        uint256 totalGonsTemp = MAX_UINT256 - (MAX_UINT256 % initialSupply);
        TOTAL_GONS = totalGonsTemp;
        
        _totalSupply = initialSupply;
        
        _gonsPerFragment = totalGonsTemp.div(initialSupply);
        
        _balances[msg.sender] = totalGonsTemp;

        //Enables transfers if specified in the constructor
        _transfersEnabled = shouldEnableTransfers;
        
    }
    
    /**
     * @dev Modifier that prevents transfers from every address (except the owner of the contract) when the _transfersEnabled flag is set to false 
     */
    modifier transfersEnabled() {
        require(_transfersEnabled || msg.sender == owner(), "Transfers are disabled");
        _;
    }
    
    /**
     * @dev Enables transfers when called. Once enabled, transfers cannot be disabled.
     */ 
    function enableTransfers() public onlyOwner override {
        _transfersEnabled = true;
        emit TransfersEnabled();
    }
    
    //REBASE LOGIC FORKED FROM uFragments.
    
    /**
     * @dev Notifies Fragments contract about a new rebase cycle. Can only be called by the contract owner
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 supplyDelta) external onlyOwner override returns (uint256) {
        return _rebase(supplyDelta);
    }
    
    /**
     * @dev Notifies Fragments contract about a new rebase cycle. Can only be called internally.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function _rebase(uint256 supplyDelta) internal returns (uint256) {
        if (supplyDelta == 0) {
            emit LogRebase(now, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply.add(uint256(supplyDelta));

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // From this point forward, _gonsPerFragment is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UIN128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_GONS.div(_gonsPerFragment)

        //Syncing trading pairs
        _syncer.sync();
        
        rebaseCount.add(1);

        emit LogRebase(now, _totalSupply);
        return _totalSupply;
    }
    
    /**
     * @dev Toggles rebases. Can only be called by the owner
     * @param state Whether to enable or disable rebases
     */ 
    function toggleRebase(bool state) external override onlyOwner {
        rebState = state;
        //We are setting the next rebase's timestamp to now + rebaseRate.
        //Done to prevent multiple consecutive rebases
        nextReb =  now + rebaseRate;
        
        emit RebaseToggled(state);
    }
    
    /**
     * @dev Changes the amount of time between each rebase. Can only be called by the owner
     * @param newRate the new rebase rate (seconds)
     */ 
    function changeRebaseRate(uint256 newRate) external override onlyOwner {
        uint256 oldRate = rebaseRate;
        rebaseRate = newRate;
        nextReb = now.add(newRate);
        
        emit RebaseRateChanged(newRate, oldRate);
    }
    
    /**
     * @dev Changes the inflation amount after each rebase. Can only be called by the owner
     * @param newAmount the new inflation amount
     */ 
    function changeRebaseAmount(uint256 newAmount) external override onlyOwner {
        uint256 oldAmount = rebaseAmount;
        rebaseAmount = newAmount;
        
        emit RebaseAmountChanged(newAmount, oldAmount);
    }

    /**
     * @dev Sets a new syncer smart contract. Can only be called by the owner.
     * Syncers are used to sync trading pairs across dexes.
     * @param newSyncer the address of the new syncer smart contract
     */ 
    function changeWageSyncer(address newSyncer) external override onlyOwner {
        address oldSyncer = address(_syncer);
        _syncer = IWageSyncer(newSyncer);
        
        emit WageSyncerChanged(newSyncer, oldSyncer);
    }
    
    /**
     * @dev Returns the gons per fragment rate. Can only be called by the owner.
     * @return the gons per fragment rate
     */
    function gonsPerFragment() external view override onlyAuthorized("Address not authorized") returns (uint256) {
        return _gonsPerFragment;
    }
    
    /**
     * @dev Locks part of an address' gon balance. Needed for governance.
     * The amount of locked fragments inflates after each rebase.
     * @param target The target address
     * @param gonAmount the amount of gons to lock
     */
    function lock(address target, uint256 gonAmount) external override onlyAuthorized("Address not authorized") {
        require(_balances[target].sub(_lockedGons[target]) >= gonAmount, "Insufficient unlocked balance");
        
        _lockedGons[target] = _lockedGons[target].add(gonAmount);
        
        emit TokensLocked(target, gonAmount.div(_gonsPerFragment));
    }
    
    /**
     * @dev Unlocks part of an adress' locked gon balane. Needed for governance.
     * @param target The target address
     * @param gonAmount the amount of gons to unlock
     */
    function unlock(address target, uint256 gonAmount) external override onlyAuthorized("Address not authorized") {
        require(_lockedGons[target] >= gonAmount, "Insufficient locked balance");
        
        _lockedGons[target] = _lockedGons[target].sub(gonAmount);
        
        emit TokensUnlocked(target, gonAmount.div(_gonsPerFragment));
    }
    
    
    /**
     * @dev Returns the current locked fragments for an address
     * @param addr the address
     */ 
    function getLockedFragments(address addr) external view override returns (uint256) {
        return _lockedGons[addr].div(_gonsPerFragment);
    }
    
    /**
     * @dev Executes a token transfer and rebases if the conditions are met. Can only be called internally
     * @param from the address who's sending the tokens
     * @param to the recipient address
     * @param value the amount to transfer
     */
    function _transfer(address from, address to, uint256 value) internal override transfersEnabled {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        uint256 gonsAmount = value.mul(_gonsPerFragment);
        require(_balances[from].sub(_lockedGons[from]) >= gonsAmount, "Insufficient unlocked balance");

        //Rebases if the conditions are met. 
        if (rebState && now >= nextReb) {
            _rebase(rebaseAmount);
            nextReb = now.add(rebaseRate);
        }
        
        uint256 gonValue = value.mul(_gonsPerFragment);
        _balances[from] = _balances[from].sub(gonValue);
        _balances[to] = _balances[to].add(gonValue);
        emit Transfer(from, to, value);
    }
    
    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override(ERC20, IERC20) returns (uint256) {
        return _balances[who].div(_gonsPerFragment);
    }
}