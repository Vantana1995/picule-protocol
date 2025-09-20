# Picule Protocol

🚧 **Work in Progress** - Website launching soon
Revolutionary value-backed NFTs with permanently locked liquidity that eliminates rug pulls and creates intrinsic NFT value.

## 📚 Documentation

- 📖 [Project Description PDF](./docs/description.pdf) - Complete project overview and origin story
- 📄 [Whitepaper PDF](./docs/whitepaper.pdf) - Technical specifications and protocol details

## 📁 Repository Structure

### 📋 Smart Contracts

- [`/src/contracts`](./src/contracts) - Core protocol contracts
  - [`erc20.sol`](./src/contracts/erc20.sol) - ERC-20 token implementation - [0x912db3dc33dc9798ceb45e2da919acbaa29d2565](https://sepolia.etherscan.io/address/0x912db3dc33dc9798ceb45e2da919acbaa29d2565)
  - [`erc20Constructor.sol`](./src/contracts/erc20Constructor.sol) - ERC-20 factory constructor
  - [`erc721.sol`](./src/contracts/erc721.sol) - Picule NFT - [0x1867ea756e38899d725479109ae678758518c667](https://sepolia.etherscan.io/address/0x1867ea756e38899d725479109ae678758518c667)
  - [`factory.sol`](./src/contracts/factory.sol) - Pair creation factory - [0x7a0ba2f48ecc7db655cd5890e1e53b01196c3616](https://sepolia.etherscan.io/address/0x7a0ba2f48ecc7db655cd5890e1e53b01196c3616)
  - [`lpToken.sol`](./src/contracts/lpToken.sol) - Liquidity provider token
  - [`marketplace.sol`](./src/contracts/marketplace.sol) - NFT trading marketplace - [0x6b705c2e5ab18eb9b888ba317420d9f1c5a46dc2](https://sepolia.etherscan.io/address/0x6b705c2e5ab18eb9b888ba317420d9f1c5a46dc2)
  - [`mpcToken.sol`](./src/contracts/mpcToken.sol) - MPC token - [0x79fd213135a9f948f7c7abf281f65e62decf5ed8](https://sepolia.etherscan.io/address/0x79fd213135a9f948f7c7abf281f65e62decf5ed8)
  - [`pair.sol`](./src/contracts/pair.sol) - AMM pool with commission tracking implementation - [0x2248d1716383a3a96e60aa17b8280006e0a285c5](https://sepolia.etherscan.io/address/0x2248d1716383a3a96e60aa17b8280006e0a285c5)
  - [`router.sol`](./src/contracts/router.sol) - Swap and liquidity router - [0xeadc04541ee096a49e45ab3a3ef14a65d70ae85d](https://sepolia.etherscan.io/address/0xeadc04541ee096a49e45ab3a3ef14a65d70ae85d)
  - [`treasuryController.sol`](./src/contracts/treasuryController.sol) - Treasury management - [0x405c002ae48c2df956c9be551e4bfad066bf31d0](https://sepolia.etherscan.io/address/0x405c002ae48c2df956c9be551e4bfad066bf31d0)
  - [`ICO.sol`](./src/contracts/ICO.sol) - Crowdfunding and contribution management - [0xf551cce75e94b08409cc4b6f69132abee27324c3](https://sepolia.etherscan.io/address/0xf551cce75e94b08409cc4b6f69132abee27324c3)
  - [`fundsManager.sol`](./src/contracts/fundsManager.sol) - LP token locking and commission distribution - [0x6051700da98d38e47db2de3c8b670158ff24671d](https://testnet.monadexplorer.com/address/0x6051700da98d38e47db2de3c8b670158ff24671d)
  - [`TokenLaunchManager.sol`](./src/contracts/TokenLaunchManager.sol) - Project creation factory - [0x2223e98224a6c1f19dfba9e6f249606cdc21bd9d](https://sepolia.etherscan.io/address/0x2223e98224a6c1f19dfba9e6f249606cdc21bd9d)

### 🔗 Interfaces

- [`/src/interfaces`](./src/interfaces) - Contract interfaces
  - [`IERC20.sol`](./src/interfaces/IERC20.sol)
  - [`IERC721.sol`](./src/interfaces/IERC721.sol)
  - [`IFactory.sol`](./src/interfaces/IFactory.sol)
  - [`IICO.sol`](./src/interfaces/IICO.sol)
  - [`ILpToken.sol`](./src/interfaces/ILpToken.sol)
  - [`IPair.sol`](./src/interfaces/IPair.sol)
  - [`IRouter.sol`](./src/interfaces/IRouter.sol)
  - [`ITLmanager.sol`](./src/interfaces/ITLmanager.sol)
  - [`IWMON.sol`](./src/interfaces/IWMON.sol)

### 📚 Libraries

- [`/src/libraries`](./src/libraries) - Utility libraries
  - [`Library.sol`](./src/libraries/Library.sol) - Router helper functions
  - [`Math.sol`](./src/libraries/Math.sol) - Mathematical operations
  - [`TransferLib.sol`](./src/libraries/TransferLib.sol) - Safe transfer utilities
  - [`UQ112x112.sol`](./src/libraries/UQ112x112.sol) - Fixed point math library

### 📚 Documentation

- [`/docs`](./docs) - PDF documentation and technical specs

## 📜 License

This repository contains smart contracts licensed under two different licenses:

### Business Source License 1.1 (BSL)

**Commercial use prohibited until August 12, 2028, after which it becomes MIT.**

Core Protocol Contracts:

- [`ICO.sol`](./src/contracts/ICO.sol)
- [`fundsManager.sol`](./src/contracts/fundsManager.sol)
- [`TokenLaunchManager.sol`](./src/contracts/TokenLaunchManager.sol)

### MIT License

**Free to use, copy, modify, and distribute with attribution.**

- [`erc20.sol`](./src/contracts/erc20.sol)
- [`erc721.sol`](./src/contracts/erc721.sol)
- [`factory.sol`](./src/contracts/factory.sol)
- [`marketplace.sol`](./src/contracts/marketplace.sol)
- [`pair.sol`](./src/contracts/pair.sol)
- [`router.sol`](./src/contracts/router.sol)

Supporting Components:

- [`/src/interfaces/`](./src/interfaces) - All interface files
- [`/src/libraries/`](./src/libraries) - Utility libraries
  - [`Library.sol`](./src/libraries/Library.sol)
  - [`Math.sol`](./src/libraries/Math.sol)
  - [`TransferLib.sol`](./src/libraries/TransferLib.sol)
  - [`UQ112x112.sol`](./src/libraries/UQ112x112.sol)

---

_One-person project - Conceived and developed in 2024_
