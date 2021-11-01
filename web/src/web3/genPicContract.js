import genPicAbi from "./genPic.abi.json";

function getGenPicContract(web3) {
  // load abi
  var genPicContract = new web3.eth.Contract(
    genPicAbi,
    "0xaC15B95067CBcC204E9ad89AF5cF0CC2C8eB0e16"
  );
  return genPicContract;
}

export default getGenPicContract;
