// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.5;
pragma experimental ABIEncoderV2;

import "./LibUniERC20.sol";
import "./VaultETHDAI.sol";

// DEBUG
import "hardhat/console.sol";

interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}

contract Flasher is IFlashLoanReceiver {

  using SafeMath for uint256;

  address constant LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

  //This Operation is called and required by Aave FlashLoan
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {

    console.log("Starting executeOperation from Aave Flashloan call");

    //Decoding Parameters
    // 1. vault's address on which we should call fujiSwitch
    // 2. new provider's address which we pass on fujiSwitch
    (address theVault, address newProvider) = abi.decode(params, (address,address));

    //approve vault to spend ERC20
    IERC20(assets[0]).approve(address(theVault), amounts[0]);

    //Estimate flashloan payback + premium fee,
    uint amountOwing = amounts[0].add(premiums[0]);

    //call fujiSwitch
    IVault(theVault).fujiSwitch(newProvider, amountOwing);
    console.log("Flasher fujiSwitch routine complete");

    //Approve aaveLP to spend to repay flashloan
    IERC20(assets[0]).approve(address(LENDING_POOL), amountOwing);

    return true;
  }

  receive() external payable {}

}
