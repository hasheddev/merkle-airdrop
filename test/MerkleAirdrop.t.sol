// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test {
    BagelToken token;
    MerkleAirdrop airdrop;

    bytes32 public constant ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public amountToClaim = 25e18;
    bytes32 proofOne =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proof = [proofOne, proofTwo];
    address user;
    uint256 userPrivkey;
    uint256 amountToSend = 25e18 * 4;
    address gasPayer;

    function setUp() public {
        DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
        (airdrop, token) = deployer.run();
        (user, userPrivkey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
        vm.deal(gasPayer, 10e18);
    }

    function testUserCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user, amountToClaim);
        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivkey, digest);
        airdrop.claim(user, amountToClaim, proof, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        console.log("user ending balance: ", endingBalance);
        assertEq(endingBalance - startingBalance, amountToClaim);
    }

    function testOthersCanClaimOnBehalfOfUser() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user, amountToClaim);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivkey, digest);
        vm.prank(gasPayer);
        airdrop.claim(user, amountToClaim, proof, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        console.log("user ending balance: ", endingBalance);
        assertEq(endingBalance - startingBalance, amountToClaim);
    }
}
