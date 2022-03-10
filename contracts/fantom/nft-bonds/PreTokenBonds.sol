// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/VoucherCore.sol";
import "./NFTGame.sol";

contract PreTokenBonds is VoucherCore {
  /**
   * @dev NFTGame contract address changed
   */
  event NFTGameChanged(address newAddress);

  /**
   * @dev Underlying token address changed
   */
  event UnderlyingChanged(address newAddress);

  NFTGame private nftGame;

  address public underlying;

  function _initialize(
      string memory _name,
      string memory _symbol,
      uint8 _unitDecimals,
      address _nftGame
  ) internal override {
    VoucherCore._initialize(_name, _symbol, _unitDecimals);
    nftGame = NFTGame(_nftGame);
  }

  /**
   * @notice Set address for NFTGame contract
   */
  function setNFTGame(address _nftGame) external {
    require(nftGame.hasRole(nftGame.GAME_ADMIN(), msg.sender), "No permission!");
    nftGame = NFTGame(_nftGame);
    emit NFTGameChanged(_nftGame);
  }

  /**
   * @notice Set address for underlying Fuji ERC-20
   */
  function setUnderlying(address _underlying) external {
    require(nftGame.hasRole(nftGame.GAME_ADMIN(), msg.sender), "No permission!");
    underlying = _underlying;
    emit UnderlyingChanged(_underlying);
  }

  /**
   * @notice Function to be called from Interactions contract, after burning the points
   */
  function mint(address _user, uint256 _slot, uint256 _units) external {
    require(nftGame.hasRole(nftGame.GAME_INTERACTOR(), msg.sender), "No permission!");
    _mint(_user, _slot, _units);
  }

  /**
   * @notice Deposits Fuji ERC-20 tokens as underlying
   */
  function deposit(uint256 _amount) external {
    require(nftGame.hasRole(nftGame.GAME_ADMIN(), msg.sender), "No permission!");
    IERC20(underlying).transferFrom(msg.sender, address(this), _amount);
  }

  function claim(address user, uint256 _slot, uint256 _units) external {
    require(nftGame.hasRole(nftGame.GAME_INTERACTOR(), msg.sender), "No permission!");
    require (nftGame.getPhase() == 3, "Wrong game phase");

    //burn units
    IERC20(underlying).transfer(user, tokensPerUnit(_slot) * _units);
  }

  function tokensPerUnit(uint256 _slot) public {
    uint256[] slots = [3, 6, 12];
    uint256 totalUnits = 0;
    for (uint256 i = 0; i < slots.length; i++) {
      totalUnits += unitsInSlot(slots[i]);
    }

    uint256 multiplier = _slot == 3 ? 1 : _slot == 6 ? 2 : 4;
    return (IERC20(underlying).balanceOf(address(this)) / totalUnits) * multiplier;
  }
}