// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IdentityManager} from "../../../src/Identity Management/IdentityManager.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";

contract TestIdentityManager is Test {
  IdentityManager identityManager;
  HelperConfig helperConfig;

  address OWNER = makeAddr("Owner");

  //potential error coming from helperConfig _appid and/or _actionId
  function setUp() public {
    helperConfig = new HelperConfig();
    identityManager = new IdentityManager(
      OWNER,
      helperConfig.getAnvilConfig()._WorldcoinRouterAddress,
      helperConfig.getAnvilConfig()._appid,
      helperConfig.getAnvilConfig()._actionId
    );
    console.log("deployed");
  }

  function testDefault() public {
    vm.prank(OWNER);
    // identityManager.verifyAndExecute(
    //   msg.sender,
    //   0x2cbfea1be1299aaffa8321856855b48e69dc3b54e37c3f73c030ac5202b54006,
    //   0xda30b6aee2ac6ddea471f85d38365cc1ec06f56770b91fd81b68a67c0cb44ec,
    //   [
    //     0xf021f1b1a6bc42401c7705f7d3f1821d68c40f41f95860c44d0913bd9343515,
    //     0x120220744783ea538363b3acb128908141f09a841f28f60226286225d28c3385,
    //     0x7bec2b688927f5d1ed7f55ee8381bd85276672b043be79ef502256335a7c7b3,
    //     0x75c12c7b45d581c4e0405f158013b389494150f19d80e167d4e6f90dd0c1aea,
    //     0x1ce9fea51fbfee5776bf1ebd11499514ab62570151b05796f00de5d0b85086bd,
    //     0x14a7cccc1e8d70fa5fe217e7a07858c762b7ae7be9e12c018952d16357dac349,
    //     0xc1b6f2a7e01d5cea9d023b9376cdd5daee7cc57ebfc4a2478686fdf46030adf,
    //     0x46a4e471b76b609afda80f92db1cddaf2749b00b9c69b544da2669a28c30ab3
    //   ]
    // );
  }
}
