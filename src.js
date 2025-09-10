const { Web3 } = require("web3");
require("dotenv").config();

// Подключение к сети
const web3 = new Web3("https://testnet-rpc.monad.xyz");

// Адрес контракта
const contractAddress = "0x7927a4bd40ab5a60c4a319ea55424469560e947b";

// ABI только для нужной функции
const contractABI = [
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
];

async function getRequestInfo() {
  try {
    // Создаем инстанс контракта
    const contract = new web3.eth.Contract(contractABI, contractAddress);

    // Вызываем функцию
    const result = await contract.methods.getRequestInfo(0).call();

    console.log("Request Info for ID 0:");
    console.log("ercToken:", result.ercToken);
    console.log("erc721:", result.erc721);
    console.log("manager:", result.manager);
    console.log("fundsManager_:", result.fundsManager_);
    console.log(
      "target:",
      web3.utils.fromWei(result.target.toString(), "ether"),
      "ETH"
    );
    console.log("deadline:", new Date(Number(result.deadline) * 1000));
    console.log(
      "minimum:",
      web3.utils.fromWei(result.minimum.toString(), "ether"),
      "ETH"
    );
    console.log(
      "value:",
      web3.utils.fromWei(result.value.toString(), "ether"),
      "tokens"
    );
    console.log(
      "raised:",
      web3.utils.fromWei(result.raised.toString(), "ether"),
      "ETH"
    );
    console.log("completed:", result.completed);

    // Вычисляем остаток до target
    const targetBig = BigInt(result.target.toString());
    const raisedBig = BigInt(result.raised.toString());
    const remaining = targetBig - raisedBig;
    console.log(
      "Remaining to target:",
      web3.utils.fromWei(remaining.toString(), "ether"),
      "ETH"
    );

    // Показываем точные значения в wei
    console.log("\n=== ТОЧНЫЕ ЗНАЧЕНИЯ В WEI ===");
    console.log("target (wei):", result.target.toString());
    console.log("raised (wei):", result.raised.toString());
    console.log("remaining (wei):", remaining.toString());
  } catch (error) {
    console.error("Error calling contract:", error.message);
  }
}

// Запускаем
getRequestInfo();
