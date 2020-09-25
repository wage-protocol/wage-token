pragma solidity ^0.6.6;

contract MockContract {

    bool public paramFunctionCalled;
    bool public noParamFunctionCalled;

    uint8 public functionParam1;
    uint8 public functionParam2;

    function mockFunctionParam(uint8 param1, uint8 param2) external {
        functionParam1 = param1;
        functionParam2 = param2;

        paramFunctionCalled = true;
    }

    function mockFunction() external {
        noParamFunctionCalled = true;
    }

}