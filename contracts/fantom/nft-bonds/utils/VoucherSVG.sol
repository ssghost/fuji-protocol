// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IVoucherSVG.sol";
import "../NFTGame.sol";
import "../PreTokenBonds.sol";
import "../libraries/StringConvertor.sol";

library SolvConstants {
    enum ClaimType {
        LINEAR,
        ONE_TIME,
        STAGED
    }
    enum VoucherType {
        STANDARD_VESTING,
        FLEXIBLE_DATE_VESTING,
        BOUNDING
    }
}

contract VoucherSVG is IVoucherSVG {
  using StringConvertor for uint256;
  using StringConvertor for bytes;

  struct SVGParams {
      address voucher;
      string underlyingTokenSymbol;
      uint256 tokenId;
      uint256 bondsAmount;
      uint64 startTime;
      uint64 endTime;
      uint8 claimType;
      uint8 bondsDecimals;
  }

  string[2] public voucherBgColors;

  NFTGame private nftGame;

  bytes32 private _nftgame_GAME_ADMIN;

  constructor(
    address _nftGame,
    string[2] memory _onetimeBgColors
  ) {
    nftGame = NFTGame(_nftGame);
    require(_onetimeBgColors.length >= 2, GameErrors.INVALID_INPUT);
    voucherBgColors = _onetimeBgColors;
  }

  /// Admin functions

  function setVoucherBgColors(
        string[2] memory _onetimeBgColors
  ) external {
    require(nftGame.hasRole(_nftgame_GAME_ADMIN, msg.sender), GameErrors.NOT_AUTH);
    voucherBgColors = _onetimeBgColors;
  }

  /// View functions

  function generateSVG(address _voucher, uint256 _tokenId) external view override returns (string memory) {
    PreTokenBonds voucher = PreTokenBonds(_voucher);
    ERC20 underlyingToken = ERC20(voucher.underlying());
    uint256 slotId = voucher.slotOf(_tokenId);

    SVGParams memory svgParams;
    svgParams.voucher = address(voucher);
    svgParams.underlyingTokenSymbol = underlyingToken.symbol();
    svgParams.tokenId = _tokenId;
    svgParams.bondsAmount = voucher.unitsInToken(_tokenId);
    svgParams.bondsDecimals = uint8(nftGame.POINTS_DECIMALS());
    svgParams.startTime = uint64(nftGame.gamePhaseTimestamps(3));
    svgParams.endTime = uint64(voucher.vestingTypeToTimestamp(slotId));
    svgParams.claimType = uint8(SolvConstants.ClaimType.ONE_TIME);

    return _generateSVG(svgParams);
  }

  /// Internal functions

  function _generateSVG(SVGParams memory params) internal view virtual returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<svg width="600px" height="400px" viewBox="0 0 600 400" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          _generateDefs(),
          '<g stroke-width="1" fill="none" fill-rule="evenodd" font-family="Arial">',
          _generateBackground(),
          _generateTitle(params),
          _generateLegend(),
          _generateClaimType(params),
          "</g>",
          "</svg>"
        )
      );
  }

  function _generateDefs() internal view returns (string memory) {
    string memory color0 = voucherBgColors[0];
    string memory color1 = voucherBgColors[1];
    return 
        string(
            abi.encodePacked(
                '<defs>',
                    '<linearGradient x1="0%" y1="75%" x2="100%" y2="30%" id="lg-1">',
                        '<stop stop-color="', color0,'" offset="0%"></stop>',
                        '<stop stop-color="', color1, '" offset="100%"></stop>',
                    '</linearGradient>',
                    '<rect id="path-2" x="16" y="16" width="568" height="368" rx="16"></rect>',
                    '<linearGradient x1="100%" y1="50%" x2="0%" y2="50%" id="lg-2">',
                        '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                        '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                    '</linearGradient>', 
                    abi.encodePacked(
                        '<linearGradient x1="50%" y1="0%" x2="50%" y2="100%" id="lg-3">',
                            '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                            '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                        '</linearGradient>',
                        '<linearGradient x1="100%" y1="50%" x2="35%" y2="50%" id="lg-4">',
                            '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                            '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                        '</linearGradient>',
                        '<linearGradient x1="50%" y1="0%" x2="50%" y2="100%" id="lg-5">',
                            '<stop stop-color="#FFFFFF" offset="0%"></stop>',
                            '<stop stop-color="#FFFFFF" stop-opacity="0" offset="100%"></stop>',
                        '</linearGradient>'
                    ),
                    '<path id="text-path-a" d="M30 12 H570 A18 18 0 0 1 588 30 V370 A18 18 0 0 1 570 388 H30 A18 18 0 0 1 12 370 V30 A18 18 0 0 1 30 12 Z" />',
                '</defs>'
            )
        );
  }

  function _generateBackground() internal pure returns (string memory) {
    return 
        string(
            abi.encodePacked(
                '<rect fill="url(#lg-1)" x="0" y="0" width="600" height="400" rx="24"></rect>',
                '<g text-rendering="optimizeSpeed" opacity="0.5" font-family="Arial" font-size="10" font-weight="500" fill="#FFFFFF">',
                    '<text><textPath startOffset="-100%" xlink:href="#text-path-a">In Crypto We Trust<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                    '<text><textPath startOffset="0%" xlink:href="#text-path-a">In Crypto We Trust<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                    '<text><textPath startOffset="50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                    '<text><textPath startOffset="-50%" xlink:href="#text-path-a">Powered by Solv Protocol<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>',
                '</g>',
                '<rect stroke="#FFFFFF" x="16.5" y="16.5" width="567" height="367" rx="16"></rect>',
                '<mask id="mask-3" fill="white">',
                    '<use xlink:href="#path-2"></use>',
                '</mask>',
                '<path d="M404,-41 L855,225 M165,100 L616,366 M427,-56 L878,210 M189,84 L640,350 M308,14 L759,280 M71,154 L522,420 M380,-27 L831,239 M143,113 L594,379 M286,28 L737,294 M47,169 L498,435 M357,-14 L808,252 M118,128 L569,394 M262,42 L713,308 M24,183 L475,449 M333,0 L784,266 M94,141 L545,407 M237,57 L688,323 M0,197 L451,463 M451,-69 L902,197 M214,71 L665,337 M665,57 L214,323 M902,197 L451,463 M569,0 L118,266 M808,141 L357,407 M640,42 L189,308 M878,183 L427,449 M545,-14 L94,252 M784,128 L333,394 M616,28 L165,294 M855,169 L404,435 M522,-27 L71,239 M759,113 L308,379 M594,14 L143,280 M831,154 L380,420 M498,-41 L47,225 M737,100 L286,366 M475,-56 L24,210 M713,84 L262,350 M451,-69 L0,197 M688,71 L237,337" stroke="url(#lg-2)" opacity="0.2" mask="url(#mask-3)"></path>'
            )
        );
  }

  function _generateTitle(SVGParams memory params) internal pure returns (string memory) {
    string memory tokenIdStr = params.tokenId.toString();
    uint256 tokenIdLeftMargin = 488 - 20 * bytes(tokenIdStr).length;
    return 
      string(
        abi.encodePacked(
          '<g transform="translate(40, 40)" fill="#FFFFFF" fill-rule="nonzero">',
              '<text font-family="Arial" font-size="32">',
                  abi.encodePacked(
                      '<tspan x="', tokenIdLeftMargin.toString(), '" y="29"># ', tokenIdStr, '</tspan>'
                  ),
              '</text>',
              '<text font-family="Arial" font-size="36">',
                  '<tspan x="0" y="72">', _formatValue(params.bondsAmount, params.bondsDecimals), '</tspan>',
              '</text>',
              '<text font-family="Arial" font-size="24" font-weight="500">',
                  '<tspan x="0" y="26">', params.underlyingTokenSymbol, ' Fuji Pre-Token Bond Voucher</tspan>',
              '</text>',
          '</g>'
        )
      );
  }

  function _formatValue(uint256 value, uint8 decimals) private pure returns (bytes memory) {
    return value.uint2decimal(decimals).trim(decimals - 2).addThousandsSeparator();
  }

  function _generateLegend() internal pure returns (string memory) {
    return 
      string(
        abi.encodePacked(
          '<g transform="translate(431, 165)">',
            '<path d="M0,146 L1,0" stroke="url(#lg-3)" stroke-width="20" opacity="0.4" stroke-linecap="round" stroke-linejoin="round"></path>',
            '<path d="M1,-12 C8,-12 13,-7 13,0 C13,6 9,11 3,12 L2,146 L-1,146 L-1,12 C-7,11 -11,6 -11,-0 C-11,-7 -6,-12 1,-12 Z" fill="url(#lg-5)" fill-rule="nonzero"></path>',
            '<path d="M117,217 L-415,-98" stroke="url(#lg-4)" stroke-width="2" opacity="0.2"></path>',
          '</g>'
        )
      );
  }

  function _generateClaimType(SVGParams memory params) internal pure returns (string memory) {
    return 
      string(
        abi.encodePacked(
          '<g transform="translate(40, 281)">',
            '<rect fill="#000000" opacity="0.2" x="0" y="0" width="240" height="80" rx="16"></rect>',
            '<text fill-rule="nonzero" font-family="Arial" font-size="20" font-weight="500" fill="#FFFFFF">',
                '<tspan x="31" y="31">One-time</tspan>',
            '</text>',
            '<text fill-rule="nonzero" font-family="Arial" font-size="14" font-weight="500" fill="#FFFFFF">',
                '<tspan x="30" y="58">Claim Date: ', uint256(params.endTime).dateToString(), '</tspan>',
            '</text>',
          '</g>'
        )
      );
  }
}
