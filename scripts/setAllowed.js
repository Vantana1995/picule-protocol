require("dotenv").config();

const { Web3 } = require("web3");

const rpcURL = process.env.RPC_URL;
const privateKey = process.env.PRIVATE_KEY;
const factoryAddress = process.env.FACTORY;
const addressToAdd = "0x8b78EbA33460Ad98004dcE874e8Ed29cBd99EF98";

const factoryABI = [
  {
    inputs: [{ internalType: "address", name: "addr", type: "address" }],
    name: "addAllowed",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const web3 = new Web3(rpcURL);

async function addAllowedCreator() {
  let signedTx;

  try {
    const account = web3.eth.accounts.privateKeyToAccount(privateKey);
    const myAddress = account.address;
    console.log("Your address:", myAddress);

    const balance = await web3.eth.getBalance(myAddress);
    console.log("Balance:", web3.utils.fromWei(balance, "ether"), "ETH");

    const contract = new web3.eth.Contract(factoryABI, factoryAddress);

    console.log("Factory contract:", factoryAddress);
    console.log("Adding address:", addressToAdd);

    const addAllowedTx = contract.methods.addAllowed(addressToAdd);

    const gasPrice = await web3.eth.getGasPrice();
    console.log("Gas price:", gasPrice);

    const tx = {
      from: myAddress,
      to: factoryAddress,
      data: addAllowedTx.encodeABI(),
      gas: 100000, // Небольшой лимит газа для простой функции
      gasPrice: gasPrice,
      nonce: await web3.eth.getTransactionCount(myAddress),
    };

    console.log("Signing transaction...");
    signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);

    console.log("Transaction Hash:", signedTx.transactionHash);
    console.log(
      "Etherscan Link:",
      `https://sepolia.etherscan.io/tx/${signedTx.transactionHash}`
    );

    console.log("Sending transaction...");
    const receipt = await web3.eth.sendSignedTransaction(
      signedTx.rawTransaction
    );

    console.log("Transaction successful!");
    console.log("Transaction hash:", receipt.transactionHash);
    console.log("Block number:", receipt.blockNumber);
    console.log("Gas used:", receipt.gasUsed);
    console.log(`Address ${addressToAdd} has been added to allowed creators`);
  } catch (error) {
    console.error("Error:", error.message);

    if (signedTx && signedTx.transactionHash) {
      console.log("Transaction Hash:", signedTx.transactionHash);
      console.log(
        "Etherscan Link:",
        `https://sepolia.etherscan.io/tx/${signedTx.transactionHash}`
      );
    }

    if (error.reason) {
      console.error("Reason:", error.reason);
    }
  }
}

console.log("Starting addAllowed script...");
addAllowedCreator().catch(console.error);
