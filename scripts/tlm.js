require("dotenv").config();

const { Web3 } = require("Web3");
const fs = require("fs");
const path = require("path");

const rpcURL = process.env.RPC;
const privateKey = process.env.PRIVATE_KEY;

const artifactData = JSON.parse(
  fs.readFileSync(
    path.join(
      __dirname,
      "../artifacts/tokenLauncherManager/TokenLauncherManager.json"
    ),
    "utf-8"
  )
);
const abi = artifactData.abi;
const bytecode = artifactData.bytecode;
const web3 = new Web3(rpcURL);

async function deploy() {
  const account = web3.eth.accounts.privateKeyToAccount(privateKey);
  const myAddress = account.address;
  const contract = new web3.eth.Contract(abi);

  const deployTx = contract.deploy({
    data: bytecode,
    arguments: [],
  });

  const gas = await deployTx.estimateGas({ from: myAddress });
  const gasPrice = await web3.eth.getGasPrice();
  const nonce = await web3.eth.getTransactionCount(myAddress);

  const tx = {
    from: myAddress,
    data: deployTx.encodeABI(),
    gas,
    gasPrice,
    nonce,
  };

  const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
  const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
  console.log("Contract deployed at:", receipt.contractAddress);
}

deploy().catch(console.error);
