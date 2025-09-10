# Picule Protocol

🚧 **Work in Progress** - Website launching soon
Revolutionary value-backed NFTs with permanently locked liquidity that eliminates rug pulls and creates intrinsic NFT value.

## 📚 Documentation

- 📖 [Project Description PDF](./docs/description.pdf) - Complete project overview and origin story
- 📄 [Whitepaper PDF](./docs/whitepaper.pdf) - Technical specifications and protocol details

## 📁 Repository Structure

### 📋 Smart Contracts

- [`/src/contracts`](./src/contracts) - Core protocol contracts
  - [`erc20.sol`](./src/contracts/erc20.sol) - ERC-20 token implementation - [0x002e13268edf8b3680bbd7b1b3e9e59740b9b008](https://testnet.monadexplorer.com/address/0x002e13268edf8b3680bbd7b1b3e9e59740b9b008)
  - [`erc20Constructor.sol`](./src/contracts/erc20Constructor.sol) - ERC-20 factory constructor
  - [`erc721.sol`](./src/contracts/erc721.sol) - Picule NFT - [0x628885763fc5f4009626e7b596f466dec36d0e02](https://testnet.monadexplorer.com/address/0x628885763fc5f4009626e7b596f466dec36d0e02)
  - [`factory.sol`](./src/contracts/factory.sol) - Pair creation factory - [0xf6a6500d4bed8ab7045c2eb35828eb2b4bae1644](https://testnet.monadexplorer.com/address/0xf6a6500d4bed8ab7045c2eb35828eb2b4bae1644)
  - [`lpToken.sol`](./src/contracts/lpToken.sol) - Liquidity provider token
  - [`marketplace.sol`](./src/contracts/marketplace.sol) - NFT trading marketplace - [0x5b1c95f15fe45a1cf2626188042602c3ae30a902](https://testnet.monadexplorer.com/address/0x5b1c95f15fe45a1cf2626188042602c3ae30a902)
  - [`mpcToken.sol`](./src/contracts/mpcToken.sol) - MPC token - [0x28e83e1e16e5d2254d77879e71cc021b0205223c](https://testnet.monadexplorer.com/address/0x28e83e1e16e5d2254d77879e71cc021b0205223c)
  - [`pair.sol`](./src/contracts/pair.sol) - AMM pool with commission tracking implementation - [0xcaa8d5a92dbdc4d9c0c488782cf27a852e618c98](https://testnet.monadexplorer.com/address/0xcaa8d5a92dbdc4d9c0c488782cf27a852e618c98)
  - [`router.sol`](./src/contracts/router.sol) - Swap and liquidity router - [0x6ac52fc7988cf99a4a66911e248f40838ca56e9d](https://testnet.monadexplorer.com/address/0x6ac52fc7988cf99a4a66911e248f40838ca56e9d)
  - [`treasuryController.sol`](./src/contracts/treasuryController.sol) - Treasury management - [0x6e59986a3e83c0db7c59461582c48e36c32db25b](https://testnet.monadexplorer.com/address/0x6e59986a3e83c0db7c59461582c48e36c32db25b)
  - [`ICO.sol`](./src/contracts/ICO.sol) - Crowdfunding and contribution management - [0xb53b1a9ea896af728a9c2d7d40cb5a53168ed835](https://testnet.monadexplorer.com/address/0xb53b1a9ea896af728a9c2d7d40cb5a53168ed835)
  - [`fundsManager.sol`](./src/contracts/fundsManager.sol) - LP token locking and commission distribution - [0xcc068c35e60a8c0a3cc1c057bdf49413e05cb04a](https://testnet.monadexplorer.com/address/0xcc068c35e60a8c0a3cc1c057bdf49413e05cb04a)
  - [`TokenLaunchManager.sol`](./src/contracts/TokenLaunchManager.sol) - Project creation factory - [0x30334e7455328cd59ff0486735d9f014dad80fa4](https://testnet.monadexplorer.com/address/0x30334e7455328cd59ff0486735d9f014dad80fa4)

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
