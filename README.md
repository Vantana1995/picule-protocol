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
  - [`erc721.sol`](./src/contracts/erc721.sol) - Picule NFT - [0x1a91f666527b04fb8dfe8ae05fd2e628e9370bad](https://testnet.monadexplorer.com/address/0x1a91f666527b04fb8dfe8ae05fd2e628e9370bad)
  - [`factory.sol`](./src/contracts/factory.sol) - Pair creation factory - [0x88f935cc12efc73f1590bfc12178539351b145c5](https://testnet.monadexplorer.com/address/0x88f935cc12efc73f1590bfc12178539351b145c5)
  - [`lpToken.sol`](./src/contracts/lpToken.sol) - Liquidity provider token
  - [`marketplace.sol`](./src/contracts/marketplace.sol) - NFT trading marketplace - [0xe8c3490eed91ba902731ea2bbb69426282604012](https://testnet.monadexplorer.com/address/0xe8c3490eed91ba902731ea2bbb69426282604012)
  - [`mpcToken.sol`](./src/contracts/mpcToken.sol) - MPC token - [0xe91df27c401084ec11998766d64717f998b47b33](https://testnet.monadexplorer.com/address/0xe91df27c401084ec11998766d64717f998b47b33)
  - [`pair.sol`](./src/contracts/pair.sol) - AMM pool with commission tracking implementation - [0xcaa8d5a92dbdc4d9c0c488782cf27a852e618c98](https://testnet.monadexplorer.com/address/0xcaa8d5a92dbdc4d9c0c488782cf27a852e618c98)
  - [`router.sol`](./src/contracts/router.sol) - Swap and liquidity router - [0x6ac52fc7988cf99a4a66911e248f40838ca56e9d](https://testnet.monadexplorer.com/address/0x6ac52fc7988cf99a4a66911e248f40838ca56e9d)
  - [`treasuryController.sol`](./src/contracts/treasuryController.sol) - Treasury management - [0x6e59986a3e83c0db7c59461582c48e36c32db25b](https://testnet.monadexplorer.com/address/0x6e59986a3e83c0db7c59461582c48e36c32db25b)
  - [`ICO.sol`](./src/contracts/ICO.sol) - Crowdfunding and contribution management - [0x7927a4bd40ab5a60c4a319ea55424469560e947b](https://testnet.monadexplorer.com/address/0x7927a4bd40ab5a60c4a319ea55424469560e947b)
  - [`fundsManager.sol`](./src/contracts/fundsManager.sol) - LP token locking and commission distribution - [0xe582fc0dad42d73a9023f801e9e46ddf59ae0856](https://testnet.monadexplorer.com/address/0xe582fc0dad42d73a9023f801e9e46ddf59ae0856)
  - [`TokenLaunchManager.sol`](./src/contracts/TokenLaunchManager.sol) - Project creation factory - [0xbb29be458dcaa439f1259bc9b42a7240b1d37af5](https://testnet.monadexplorer.com/address/0xbb29be458dcaa439f1259bc9b42a7240b1d37af5)

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
