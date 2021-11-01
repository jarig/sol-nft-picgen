<template>
  <div>
    <div style="float: left">
      <p>1. Add layers</p>
      <button v-on:click="addLayer()">Add Layer</button>
      <button v-on:click="clearNewLayer()">Clear</button>
      <br />
      <div>Background: <input v-model="newLayerBg" type="color" /></div>
      <span
        >Pixel Color: <input v-model="newLayerCurrColor" type="color"
      /></span>
      <br />
      <div style="padding: 0">
        <canvas
          ref="newLayerCanvas"
          style="border: 1px solid"
          :width="canvasSize"
          :height="canvasSize"
        />
      </div>
    </div>
    <div style="float: left; margin-left: 10px">
      <p>2. Test layers</p>
      <button v-on:click="renderTestLayer()">Render Layer</button>
      <button v-on:click="clearTestLayer()">Clear</button>
      <br />
      <div>Layer ID: <input v-model="testLayerId" style="width: 50px" /></div>
      <br />
      <div style="padding: 0">
        <canvas
          style="border: 1px solid"
          ref="layerTestCanvas"
          :width="canvasSize"
          :height="canvasSize"
        />
      </div>
    </div>
    <div style="float: left; margin-left: 10px">
      <p>3. Overview</p>
      <button v-on:click="renderPreviewLayers()">Get Layers</button>
      <br /><br />
      <div style="max-width: 80px">
        <div
          v-for="(ref, index) in previewCanvasRefs"
          :key="ref"
          style="float: left"
          class="previewLayer"
          :title="'ID: ' + (index + 1)"
          v-on:click="selectLayer(index + 1)"
        >
          <canvas
            :ref="ref"
            :id="ref"
            style="border: 1px solid; margin: 2px; float: left"
            :width="previewCanvasSize"
            :height="previewCanvasSize"
          /><br />
          <p style="font-size: 8px; padding: 0; margin: 0">
            ID: {{ index + 1 }}
          </p>
        </div>
      </div>
    </div>
    <div style="float: left; margin-left: 10px">
      <p>4. Generate SID</p>
      <button v-on:click="genPicture()">Gen Picture</button>
      <br />
      <div>Layers: <input v-model="layerList" style="width: 70px" /></div>
      SID: <span>{{ sid }}</span>
      <br />
      <div>
        <canvas
          ref="displayCanvas"
          style="border: 1px solid"
          :width="canvasSize"
          :height="canvasSize"
        />
      </div>
    </div>
    <div style="float: left; width: 100%">
      <p>
        {{ debug_message }}
      </p>
    </div>
  </div>
</template>

<script>
import Web3 from "web3";
import getGenPicContract from "../web3/genPicContract.js";

var web3 = new Web3(
  "https://rinkeby.infura.io/v3/72366994a9fd4e8b8a38684d343a65da"
);
const account = web3.eth.accounts.privateKeyToAccount(
  "0xabda44ba61555742fc678d7cd4cad9922a5a3369ed481386ebf29af12fbc5f0e"
);
web3.eth.defaultAccount = account.address;
web3.eth.accounts.wallet.add(account);
console.log(`Test account ${account.address}`);
var ownerAccount = account.address;
var genPicContract = getGenPicContract(web3);

export default {
  name: "picgen",
  props: {},
  computed: {
    canvasSize() {
      return this.pictureDimension * this.scaleFactor;
    },
    previewScaleFactor() {
      return this.scaleFactor / 5;
    },
    previewCanvasSize() {
      return this.pictureDimension * this.previewScaleFactor;
    },
  },
  data() {
    return {
      sidBitsForLayer: 6,
      pictureDimension: 8,
      scaleFactor: 20,
      layerList: "",
      sid: 0,
      newLayerBg: "#000FFF",
      newLayerCurrColor: "#000000",
      testLayerId: 0,
      debug_message: "",
      previewLayers: [],
      previewCanvasRefs: [],
    };
  },
  methods: {
    hexToInt: function (hVal) {
      return parseInt(hVal.replace("#", ""), 16);
    },
    rgbToInt: function (r, g, b) {
      return (r << 16) + (g << 8) + b;
    },
    intToRgb: function (int) {
      var red = int >> 16;
      var green = (int - (red << 16)) >> 8;
      var blue = int - (red << 16) - (green << 8);
      return [red, green, blue];
    },
    drawLayer: function (
      canvas,
      background,
      colorMap,
      pixelLocations,
      scaleFactor
    ) {
      var pixels = [];
      // convert pixelLocations to map struct
      var pixelLocationMap = {};
      for (var p = 0; p < pixelLocations.length; p++) {
        pixelLocationMap[pixelLocations[p]] = p;
      }
      for (var i = 0; i < this.pictureDimension ** 2; i++) {
        var color = parseInt(background, 10);
        if (pixelLocationMap[i] !== undefined) {
          color = parseInt(colorMap[pixelLocationMap[i]], 10);
        }
        pixels.push(color);
      }
      this.drawFromPixels(canvas, pixels, scaleFactor);
    },
    drawFromPixels: function (canvas, pixels, scaleFactor) {
      var ctx = canvas.getContext("2d");
      for (var i = 0; i < pixels.length; i++) {
        var pLoc = i;
        var color = this.intToRgb(parseInt(pixels[i], 10));
        var y = Math.floor(pLoc / this.pictureDimension);
        var x = pLoc - y * this.pictureDimension;
        console.log(`Loc: ${pLoc} = ${x} ${y}, ${color}`);
        ctx.fillStyle = `rgba(${color[0]}, ${color[1]}, ${color[2]}, 1)`;
        ctx.fillRect(
          x * scaleFactor,
          y * scaleFactor,
          scaleFactor,
          scaleFactor
        );
      }
    },
    clearTestLayer: function () {
      this.fillCanvas(this.$refs.layerTestCanvas, this.newLayerBg);
    },
    renderTestLayer: function () {
      console.log(`Getting layer: ${this.testLayerId}`);
      var testCanvas = this.$refs.layerTestCanvas;
      var self = this;
      genPicContract.methods
        .getLayer(this.testLayerId)
        .call({ gas: 3000000 }, function (error, result) {
          if (error) {
            self.debug_message = `Failed to get layer ${error}`;
          }
        })
        .then(function (res) {
          var background = res[0];
          var colorMap = res[1];
          var pixelLocations = res[2];
          self.drawLayer(
            testCanvas,
            background,
            colorMap,
            pixelLocations,
            self.scaleFactor
          );
        });
    },
    renderPreviewLayers: function () {
      var self = this;
      this.previewLayers = [];
      this.previewCanvasRefs = [];
      genPicContract.methods
        .getLayers()
        .call({ gas: 3000000 }, function (error, result) {
          if (error) {
            self.debug_message = `Failed to get layers: ${error}`;
          }
        })
        .then(function (res) {
          console.log(res);
          for (var i = 0; i < res.length; i++) {
            var layer = res[i];
            self.previewLayers.push(layer);
            self.previewCanvasRefs.push(`pCanvas${i}`);
          }
          self.$nextTick(() => {
            for (var i = 0; i < self.previewCanvasRefs.length; i++) {
              var cRef = self.previewCanvasRefs[i];
              var layer = self.previewLayers[i];
              // note: refs not working correctly
              var canvas = document.getElementById(cRef);
              self.drawLayer(
                canvas,
                layer[0],
                layer[1],
                layer[2],
                self.previewScaleFactor
              );
            }
          });
        });
    },
    clearNewLayer: function () {
      this.fillCanvas(this.$refs.newLayerCanvas, this.newLayerBg);
    },
    selectLayer: function (layerIndex) {
      if (this.layerList !== "") {
        this.layerList += ";";
      }
      this.layerList += layerIndex;
    },
    addLayer: function () {
      var ctx = this.$refs.newLayerCanvas.getContext("2d");
      var colorMap = [];
      var pixelLocations = [];
      var background = this.hexToInt(this.newLayerBg);

      var pixelIndex = 0;
      for (var i = 0; i < this.pictureDimension; i++) {
        for (var j = 0; j < this.pictureDimension; j++) {
          var pixel = ctx.getImageData(
            j * this.scaleFactor,
            i * this.scaleFactor,
            1,
            1
          );
          var pData = pixel.data;
          var pixelColor = this.rgbToInt(pData[0], pData[1], pData[2]);
          if (pixelColor !== background) {
            colorMap.push(pixelColor);
            pixelLocations.push(pixelIndex);
          }
          pixelIndex += 1;
        }
      }
      console.log(`Pixel locations: ${pixelLocations}`);
      var dataToSend = [background, colorMap, pixelLocations];
      this.debug_message = `Saving in blockchain: ${background} , ${colorMap}, ${pixelLocations}`;
      var self = this;
      genPicContract.methods
        .addLayer(dataToSend)
        .send({ from: ownerAccount, gas: 3000000 }, function (
          error,
          transactionHash
        ) {
          console.log(`Trans: ${transactionHash}, err: ${error}`);
        })
        .on("receipt", function (rec) {
          console.log(`Gas Used: ${rec.cumulativeGasUsed}`);
          self.debug_message = `Sent, gas used: ${rec.cumulativeGasUsed}`;
        });
    },
    genPicture: function () {
      var self = this;
      var displayCanvas = this.$refs.displayCanvas;
      console.log(`Displaying sid ${this.sid}`);
      genPicContract.methods
        .getPicture8(this.sid)
        .call({ gas: 3000000 }, function (error, result) {
          if (error) {
            self.debug_message = `Failed to generate pic ${error}`;
          }
        })
        .then(function (res) {
          console.log(res);
          self.drawFromPixels(displayCanvas, res, self.scaleFactor);
        });
    },
    newLayerClick: function (event) {
      var ctx = this.$refs.newLayerCanvas.getContext("2d");
      var x = event.layerX;
      var y = event.layerY;
      var scX = Math.floor(x / this.scaleFactor);
      var scY = Math.floor(y / this.scaleFactor);
      ctx.fillStyle = this.newLayerCurrColor;
      ctx.fillRect(
        scX * this.scaleFactor,
        scY * this.scaleFactor,
        this.scaleFactor,
        this.scaleFactor
      );
    },
    fillCanvas: function (canvas, color) {
      var ctx = canvas.getContext("2d");
      ctx.fillStyle = color;
      ctx.fillRect(0, 0, this.canvasSize, this.canvasSize);
    },
  },
  watch: {
    newLayerBg: function (value) {
      this.fillCanvas(this.$refs.newLayerCanvas, value);
    },
    layerList: function (value) {
      var layerIds = value.split(";");
      this.sid = 0;
      for (var i = layerIds.length - 1; i >= 0; i--) {
        // shift left
        this.sid <<= this.sidBitsForLayer;
        this.sid += parseInt(layerIds[i], 10);
        console.log(this.sid.toString(2));
      }
    },
  },
  mounted() {
    this.$refs.newLayerCanvas.addEventListener("click", (event) => {
      this.newLayerClick(event);
    });
    // initialize canvas for the newLayer element
    this.newLayerBg = "#FFFFFF";
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.previewLayer:hover {
  background-color: #007c4842;
}
</style>
