// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
 
import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";
import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";
 
contract GenPic is NFTokenMetadata, Ownable {
 
  struct Layer { 
      uint24 backgroundColor;
      // colors for an each pixel
      uint24[] colorMap;
      // pixel position indexes
      uint16[] pixelLocations;
  }
  Layer[] layers;
  
  // maximum number of layers encoded into the sid is 21
  // 12 bit steps define layer number, offset defines layer index (from bottom to top)
  // i.e there are 21 chunks, 12 bit each encoded into the sid
  mapping (uint256 => uint256) idToSid;
  
  constructor() {
    nftName = "GenPic NFT";
    nftSymbol = "GPIC";
  }
  
  function addLayer(Layer calldata _layer) external onlyOwner {
      layers.push(_layer);
  }
  
  function getLayers() external view returns(Layer[] memory) {
      return layers;
  }
  
  function getLayer(uint16 layerId) external view returns(Layer memory) {
      return layers[layerId];
  }
  
  function mint(address _to, uint256 _tokenId, uint256 sid) external onlyOwner {
    super._mint(_to, _tokenId);
    idToSid[_tokenId] = sid;
  }
  
  function applyLayer(Layer memory layer, uint24[] memory data, bool applyBackground) private pure {
      if (applyBackground) {
        // is there a better way to initialize array?
        for(uint16 i = 0; i< data.length; i++) {
            data[i] = layer.backgroundColor;
        }
      }
      // apply layer itself now
      for(uint16 i = 0; i < layer.pixelLocations.length; i++) {
          uint16 pixelPosition = layer.pixelLocations[i];
          uint24 pixelColor = layer.colorMap[i];
          data[pixelPosition] = pixelColor;   
      }
  }
  
  function getSidEncodedPicture(uint256 picSid, uint24 pixelPositionCount, uint8 layerNumBitLength) internal view returns (uint24[] memory) {
      // generate piture out of the sid that encodes layer indexes and their positions
      uint256 bitMask = uint256(2 ** layerNumBitLength - 1);
      uint24[] memory result = new uint24[](pixelPositionCount);
      // uint8 maxLayerCount = 256 / layerNumBitLength;
      Layer memory layer;
      for (uint8 i = 0; i <= 21; i++) {
        // read first 12 bits
        uint256 layerNum = uint256(picSid & bitMask);
        if (layerNum == 0) {
            // no more layers defined
            break;
        }
        layer = layers[layerNum - 1];
        // apply it
        applyLayer(layer, result, i == 0);
        // shift sid right
        picSid >>= layerNumBitLength;
      }
      return result;
  }
  
  function getPicture64(uint256 picSid) external view returns (uint24[] memory) {
      // generate 64x64 piture out of the sid
      return getSidEncodedPicture(picSid, 4096, 12);
  }
  
  function getPicture8(uint256 picSid) external view returns (uint24[] memory) {
      // generate 8x8 piture out of the sid
      return getSidEncodedPicture(picSid, 64, 6);
  }
 
}