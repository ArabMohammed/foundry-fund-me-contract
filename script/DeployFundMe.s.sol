// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.29;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
contract DeployFundMe is Script{
    function run() external returns (FundMe){
        // before startBroadcast -> No areal tx! 
        HelperConfig helperConfig = new HelperConfig();
        address ethUsbPriceFeed = helperConfig.activeNetworkConfig();
        // after startbroadcast -> real tx!
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsbPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}