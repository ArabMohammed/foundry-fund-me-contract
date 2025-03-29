// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.29;

import  {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    uint256 number = 1;  
    FundMe fundMe ; 
    /******
      At each time we run a test, it runs independently from 
      other test so at each time we run a test we have first :
      1) setUp , then the test .
    */
    // create a fake user for our experiments 
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // ether has 18 decimal positions 
    uint256 constant STARTING_BALANCE = 10 ether ;
    uint256 constant GAS_PRICE = 1 ;
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run(); 
        // intialize user balance with fake ether (only for test)
        vm.deal(USER,STARTING_BALANCE);
    }
    // types of tests 
    // 1. Unit 
    // - Testing a specific part of our code 
    // 2. Integration 
    // - Testing how our code works with other parts of our code 
    // 3. Forked 
    // - Testing our code in a simulated real environment 
    // 4. Staging 
    // - Testing our code in a real environment that is not production 

    /*function testDemo() public {
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(),address(this));
    }*/
    function testPriceFeedVersionIsAccurate() public {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }   

    function testFundFailsWithoutEnoughEth() public {
        // to have succeful test the code after vm.expectRevert() must 
        // revert with an error 
        vm.expectRevert();
        fundMe.fund();
    }    
  
    function testFundUpdatesFundeDataStructure() public {
        vm.prank(USER); // set That next TX will be sent by USER
        fundMe.fund{value: 10e18}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,10e18);
    }
    
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value : SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    }
    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }
    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; // address(fundMe)

        // Act 
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice ;
        console.log(gasUsed);
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingOwnerBalance+startingFundMeBalance,endingOwnerBalance);


    }
    function testWithdrawMultipleFunders() public funded{
        // Arrange 
        uint160 numberOfFunders = 10 ;
        uint160 startingFunderIndex = 1 ;
        for(uint160 i =startingFunderIndex;i<10;i++){
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; // address(fundMe)

        // Act 
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingOwnerBalance+startingFundMeBalance,endingOwnerBalance);

    }
    /*
    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value : SEND_VALUE}();
        vm.expectRevert();
        fundMe.withdraw();
    }*/
}