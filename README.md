# Picule Protocol

🚧 **Work in Progress** - Website launching soon

Revolutionary value-backed NFTs with permanently locked liquidity that eliminates rug pulls and creates intrinsic NFT value.

## 📚 Documentation

- 📖 [Project Description PDF](./docs/description.pdf) - Complete project overview and origin story
- 📄 [Whitepaper PDF](./docs/whitepaper.pdf) - Technical specifications and protocol details

## 📁 Repository Structure

### 📋 Smart Contracts

- [`/src/contracts`](./src/contracts) - Core protocol contracts
  - [`erc20.sol`](./src/contracts/erc20.sol) - ERC-20 token implementation
  - [`erc20Constructor.sol`](./src/contracts/erc20Constructor.sol) - ERC-20 factory constructor
  - [`erc721.sol`](./src/contracts/erc721.sol) - NFT implementation with LP locking
  - [`factory.sol`](./src/contracts/factory.sol) - Pair creation factory
  - [`lpToken.sol`](./src/contracts/lpToken.sol) - Liquidity provider token
  - [`marketplace.sol`](./src/contracts/marketplace.sol) - NFT trading marketplace
  - [`mpcToken.sol`](./src/contracts/mpcToken.sol) - Protocol governance token
  - [`pair.sol`](./src/contracts/pair.sol) - AMM pool with commission tracking
  - [`router.sol`](./src/contracts/router.sol) - Swap and liquidity router
  - [`treasuryController.sol`](./src/contracts/treasuryController.sol) - Treasury management
  - [`ICO.sol`](./src/contracts/ICO.sol) - Crowdfunding and contribution management
  - [`fundsManager.sol`](./src/contracts/fundsManager.sol) - LP token locking and commission distribution
  - [`TokenLaunchManager.sol`](./src/contracts/TokenLaunchManager.sol) - Project creation factory

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

- [`erc20.sol`](./src/contracts/erc20.sol)
- [`erc721.sol`](./src/contracts/erc721.sol)
- [`factory.sol`](./src/contracts/factory.sol)
- [`marketplace.sol`](./src/contracts/marketplace.sol)
- [`pair.sol`](./src/contracts/pair.sol)
- [`router.sol`](./src/contracts/router.sol)
- [`ICO.sol`](./src/contracts/ICO.sol)
- [`fundsManager.sol`](./src/contracts/fundsManager.sol)
- [`TokenLaunchManager.sol`](./src/contracts/TokenLaunchManager.sol)

### MIT License

**Free to use, copy, modify, and distribute with attribution.**

Supporting Components:

- [`/src/interfaces/`](./src/interfaces) - All interface files
- [`/src/libraries/`](./src/libraries) - Utility libraries
  - [`Library.sol`](./src/libraries/Library.sol)
  - [`Math.sol`](./src/libraries/Math.sol)
  - [`TransferLib.sol`](./src/libraries/TransferLib.sol)
  - [`UQ112x112.sol`](./src/libraries/UQ112x112.sol)

**Full License Terms:**

- [LICENSE-BSL](./LICENSE-BSL.md) - Business Source License 1.1
- [LICENSE-MIT](./LICENSE-MIT.md) - MIT License

---

_One-person project - Conceived and developed in 2024_
