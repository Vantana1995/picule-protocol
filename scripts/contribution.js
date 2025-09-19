require("dotenv").config();

const { Web3 } = require("web3");

const rpcURL = process.env.RPC_URL;
const privateKey = process.env.PRIVATE_KEY;
const contractAddress = process.env.ICO;

const contractABI = [
  {
    inputs: [],
    name: "numOfRequests",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "_numOfRequest", type: "uint256" },
    ],
    name: "getRequestInfo",
    outputs: [
      { internalType: "address", name: "ercToken", type: "address" },
      { internalType: "address", name: "erc721", type: "address" },
      { internalType: "address", name: "manager", type: "address" },
      { internalType: "address", name: "fundsManager_", type: "address" },
      { internalType: "uint256", name: "target", type: "uint256" },
      { internalType: "uint256", name: "deadline", type: "uint256" },
      { internalType: "uint256", name: "minimum", type: "uint256" },
      { internalType: "uint256", name: "value", type: "uint256" },
      { internalType: "uint256", name: "raised", type: "uint256" },
      { internalType: "bool", name: "completed", type: "bool" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "uint256", name: "_numOfRequest", type: "uint256" },
    ],
    name: "contribution",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [],
    name: "initialized",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
];

const web3 = new Web3(rpcURL);

async function makeContribution() {
  let signedTx;

  try {
    const account = web3.eth.accounts.privateKeyToAccount(privateKey);
    const myAddress = account.address;
    console.log("Your address:", myAddress);

    const balance = await web3.eth.getBalance(myAddress);
    console.log("Balance:", web3.utils.fromWei(balance, "ether"), "ETH");

    const contract = new web3.eth.Contract(contractABI, contractAddress);

    try {
      const isInitialized = await contract.methods.initialized().call();
      console.log("Contract initialized:", isInitialized);
    } catch (e) {
      console.log("Cannot check initialization status");
    }

    const numOfRequests = await contract.methods.numOfRequests().call();
    console.log("Total requests:", numOfRequests);

    const requestId = numOfRequests > 0 ? Number(numOfRequests) - 1 : 0;
    console.log("Using request ID:", requestId);

    const requestInfo = await contract.methods.getRequestInfo(requestId).call();
    console.log("Request info:");
    console.log(
      "- Target:",
      web3.utils.fromWei(requestInfo.target, "ether"),
      "ETH"
    );
    console.log(
      "- Raised:",
      web3.utils.fromWei(requestInfo.raised, "ether"),
      "ETH"
    );
    console.log("- Deadline:", new Date(Number(requestInfo.deadline) * 1000));
    console.log("- Completed:", requestInfo.completed);

    const target = BigInt(requestInfo.target);
    const raised = BigInt(requestInfo.raised);
    const remaining = target - raised;

    console.log(
      "Remaining to reach target:",
      web3.utils.fromWei(remaining.toString(), "ether"),
      "ETH"
    );

    const oneEthInWei = web3.utils.toWei("1", "ether");
    const contributionAmount =
      remaining < BigInt(oneEthInWei) ? remaining.toString() : oneEthInWei;

    console.log(
      "Contributing:",
      web3.utils.fromWei(contributionAmount, "ether"),
      "ETH"
    );
    console.log("To request ID:", requestId);

    const contributionTx = contract.methods.contribution(requestId);

    const gasPrice = await web3.eth.getGasPrice();
    console.log("Gas price:", gasPrice);

    const tx = {
      from: myAddress,
      to: contractAddress,
      data: contributionTx.encodeABI(),
      value: contributionAmount,
      gas: 5000000,
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

console.log("Starting contribution script...");
makeContribution().catch(console.error);
