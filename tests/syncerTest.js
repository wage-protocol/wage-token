const WageSyncer = artifacts.require("WageSyncer");
const MockContract = artifacts.require("MockContract");

const assert = require("chai").assert;

contract("WageSyncer", (accounts) => {

    const owner = accounts[0];

    beforeEach(async () => {
        this.wageSyncer = await WageSyncer.new({ from: owner });
        this.mockContract = await MockContract.new({ from: owner }); 
    });

    it("should be able to call a function without params", async () => {
        let web3MockContract = new web3.eth.Contract(this.mockContract.abi, this.mockContract.address);
        let encodedABI = web3MockContract.methods.mockFunction().encodeABI();

        assert.isFalse(await this.mockContract.noParamFunctionCalled());

        await this.wageSyncer.addPair(this.mockContract.address, encodedABI, { from: owner });
        await this.wageSyncer.sync();

        assert.isTrue(await this.mockContract.noParamFunctionCalled());
    });

    it("should be able to call a function with params", async () => {
        let web3MockContract = new web3.eth.Contract(this.mockContract.abi, this.mockContract.address);
        let encodedABI = web3MockContract.methods.mockFunctionParam("10", "20").encodeABI();

        assert.isFalse(await this.mockContract.paramFunctionCalled());

        await this.wageSyncer.addPair(this.mockContract.address, encodedABI, { from: owner });
        await this.wageSyncer.sync();

        assert.isTrue(await this.mockContract.paramFunctionCalled());
        assert.equal("10", (await this.mockContract.functionParam1()).toString());
        assert.equal("20", (await this.mockContract.functionParam2()).toString());
    });
});