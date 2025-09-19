require("dotenv").config();

const { Web3 } = require("web3");
const fs = require("fs");
const path = require("path");

const rpcURL = process.env.RPC_URL;
const privateKey = process.env.PRIVATE_KEY;
const factory = process.env.FACTORY;
const erc20 = process.env.ERC20;
const mpc = process.env.MPC;
const erc721 = process.env.ERC721;
const fundsManager = process.env.FUNDS_MANAGER;
const tlm = process.env.TLM;
const router = process.env.ROUTER;
const ico = process.env.ICO;
const nft = process.env.NFT_ADDRESS;
const weth = process.env.WETH;

const factoryMetadata = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../metadata/factory.json"), "utf-8")
);

const mpcMetadata = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../metadata/mpc.json"), "utf-8")
);

const erc721Metadata = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../metadata/erc721.json"), "utf-8")
);

const fundsManagerMetadata = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, "../metadata/fundsManager.json"),
    "utf-8"
  )
);

const icoMetadata = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../metadata/ico.json"), "utf-8")
);

const tlmMetadata = JSON.parse(
  fs.readFileSync(path.join(__dirname, "../metadata/tlm.json"), "utf-8")
);
const web3 = new Web3(rpcURL);
const account = web3.eth.accounts.privateKeyToAccount(privateKey);
web3.eth.accounts.wallet.add(account);
async function initializeFactory() {
  const contract = new web3.eth.Contract(factoryMetadata, factory);
  const initializeData = contract.methods.initialize(tlm);

  const gasEstimate = await initializeData.estimateGas({
    from: account.address,
  });

  const tx = await initializeData.send({
    from: account.address,
    gas: gasEstimate,
    gasPrice: await web3.eth.getGasPrice(),
  });

  console.log("initialization factory successfull:", tx.transactionHash);
}

async function initializeMPC() {
  const contract = new web3.eth.Contract(mpcMetadata, mpc);
  const initializeData = contract.methods.initialize(fundsManager, ico);

  const gasEstimate = await initializeData.estimateGas({
    from: account.address,
  });

  const tx = await initializeData.send({
    from: account.address,
    gas: gasEstimate,
    gasPrice: await web3.eth.getGasPrice(),
  });
  console.log("initialization MPC successfull:", tx.transactionHash);
}

async function initializeERC721() {
  const contract = new web3.eth.Contract(erc721Metadata, erc721);
  const initializeData = contract.methods.initialize(
    "MPAvatar",
    "MPA",
    fundsManager,
    account.address,
    nft
  );

  const gasEstimate = await initializeData.estimateGas({
    from: account.address,
  });

  const tx = await initializeData.send({
    from: account.address,
    gas: gasEstimate,
    gasPrice: await web3.eth.getGasPrice(),
  });
  console.log("initialization ERC721 successfull:", tx.transactionHash);
}

async function initializeFundsManager() {
  const contract = new web3.eth.Contract(fundsManagerMetadata, fundsManager);
  const initializeData = contract.methods.initialization(
    mpc,
    erc721,
    account.address,
    ico,
    factory,
    weth
  );

  const gasEstimate = await initializeData.estimateGas({
    from: account.address,
  });

  const tx = await initializeData.send({
    from: account.address,
    gas: gasEstimate,
    gasPrice: await web3.eth.getGasPrice(),
  });
  console.log("initialization Funds Manager successfull:", tx.transactionHash);
}

async function initializeICO() {
  const contract = new web3.eth.Contract(icoMetadata, ico);
  const initializeData = contract.methods.intitialize();

  const gasEstimate = await initializeData.estimateGas({
    from: account.address,
  });

  const tx = await initializeData.send({
    from: account.address,
    gas: gasEstimate,
    gasPrice: await web3.eth.getGasPrice(),
  });
  console.log("initialization ICO successfull:", tx.transactionHash);
}

async function initializeTLM() {
  const contract = new web3.eth.Contract(tlmMetadata, tlm);
  const initializeData = contract.methods.initializer(
    ico,
    router,
    erc20,
    erc721,
    fundsManager,
    factory,
    weth
  );

  const gasEstimate = await initializeData.estimateGas({
    from: account.address,
  });

  const tx = await initializeData.send({
    from: account.address,
    gas: gasEstimate,
    gasPrice: await web3.eth.getGasPrice(),
  });
  console.log("initialization TLM successfull:", tx.transactionHash);
}

async function setMaxSupply() {
  const contract = new web3.eth.Contract(erc721Metadata, erc721);
  const initializeData = contract.methods.setMaxSupply(1111);

  const gasEstimate = await initializeData.estimateGas({
    from: account.address,
  });

  const tx = await initializeData.send({
    from: account.address,
    gas: gasEstimate,
    gasPrice: await web3.eth.getGasPrice(),
  });
  console.log("initialization ERC721 successfull:", tx.transactionHash);
}

async function main() {
  await initializeFactory();
  await initializeMPC();
  await initializeERC721();
  await initializeFundsManager();
  await initializeICO();
  await initializeTLM();
  await setMaxSupply();
}

main().catch(console.error);
