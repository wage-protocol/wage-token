const Wage = artifacts.require("Wage");
const WageSyncerMock = artifacts.require("WageSyncerMock");

const chai = require("chai");
chai.use(require("chai-bn")(require("bn.js")));
const assert = chai.assert;

const truffleAssert = require("truffle-assertions");

contract("Wage", (accounts) => {

    const owner = accounts[0];
    const holder = accounts[1];

    beforeEach(async () => {
        this.wageToken = await Wage.new("Wage", "$WAGE", 26e18.toString(), false, { from: owner });
        this.wageToken.transfer(holder, 10e18.toString(), { from: owner });
    });

    it("should not be able to transfer tokens while transfers are locked", async () => {
        await truffleAssert.reverts(
            this.wageToken.transfer(owner, 10e18.toString(), { from: holder }), 
            "Transfers are disabled");
    });

    it("should be able to transfer tokens after enabling transfers", async () => {
        await this.wageToken.enableTransfers({ from: owner });
        
        await truffleAssert.passes(
            this.wageToken.transfer(owner, 10e18.toString(), { from: holder }));

        assert.equal(
            await this.wageToken.balanceOf(owner),
            26e18.toString()
        );
    });

    it("should not be able to transfer tokens if they are locked", async () => {
        await this.wageToken.enableTransfers({ from: owner });
        await this.wageToken.grantAccess(owner, { from: owner });

        await this.wageToken.lock(holder, web3.utils.toBN(10e18).mul(await this.wageToken.gonsPerFragment()), { from: owner });
        
        
        //not exactly a fan of this syntax    
        chai.expect(await this.wageToken.balanceOf(holder)).to.be.a.bignumber.that.equals(await this.wageToken.getLockedFragments(holder));

        await truffleAssert.reverts(
            this.wageToken.transfer(owner, 2e18.toString(), { from: holder})
        );
    });

    it("should be able to transfer tokens after an unlock", async () => {
        await this.wageToken.enableTransfers({ from: owner });
        await this.wageToken.grantAccess(owner, { from: owner });

        await this.wageToken.lock(holder, web3.utils.toBN(10e18).mul(await this.wageToken.gonsPerFragment()), { from: owner });

        await truffleAssert.reverts(
            this.wageToken.transfer(owner, 2e18.toString(), { from: holder })
        );

        await this.wageToken.unlock(holder, web3.utils.toBN(10e18).mul(await this.wageToken.gonsPerFragment()), { from: owner });

        await truffleAssert.passes(
            this.wageToken.transfer(owner, 2e18.toString(), { from: holder })
        );
    });

    it("should have the same % of the total supply after a rebase", async () => {
        let syncerMock = await WageSyncerMock.new();

        let oldSupply = await this.wageToken.totalSupply();
        let rebaseAmount = await this.wageToken.rebaseAmount();

        await this.wageToken.changeWageSyncer(syncerMock.address, { from: owner });

        await this.wageToken.rebase(rebaseAmount, { from: owner });
        assert.isTrue(await syncerMock.calledSync());
        
        let newSupply = await this.wageToken.totalSupply();
        chai.expect(newSupply).to.be.a.bignumber.that.equals(oldSupply.add(rebaseAmount));

        //BN.js doesn't handle decimals. To calculate the supply % we have to be sure to not have any division with < 1 as the result
        chai.expect(web3.utils.toBN(10e18)
            .mul(web3.utils.toBN(10e18))
            .div(oldSupply)
            .mul(rebaseAmount)
            .div(web3.utils.toBN(10e18))
            .add(web3.utils.toBN(10e18))).to.be.a.bignumber.that.equals(await this.wageToken.balanceOf(holder));
    });
    
    it("should not change the total supply after a 0 rebase", async () => {
        let syncerMock = await WageSyncerMock.new();
        await this.wageToken.changeWageSyncer(syncerMock.address, { from: owner });

        let oldSupply = await this.wageToken.totalSupply();

        await this.wageToken.rebase("0", { from: owner });

        chai.expect(oldSupply).to.be.a.bignumber.that.equals(await this.wageToken.totalSupply());
    });

    it("should automatically perform a rebase if enabled and nextReb < now", async () => {
        let syncerMock = await WageSyncerMock.new();
        assert.isFalse(await syncerMock.calledSync());

        await this.wageToken.changeRebaseRate("0");
        await this.wageToken.changeWageSyncer(syncerMock.address, { from: owner });

        await this.wageToken.toggleRebase(true);

        await this.wageToken.enableTransfers({ from: owner });
        await this.wageToken.transfer(owner, 10e18.toString(), { from: holder })

        assert.isTrue(await syncerMock.calledSync());

        await syncerMock.reset();

        await this.wageToken.changeRebaseRate("10800");

        await this.wageToken.transfer(holder, 10e18.toString(), { from: owner })

        assert.isFalse(await syncerMock.calledSync());

    });
});