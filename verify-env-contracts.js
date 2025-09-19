require("dotenv").config();
const fs = require("fs");
const path = require("path");

const compilationSettings = {
  "erc721.sol": { runs: 200 },
  "treasuryController.sol": { runs: 200 },
  "router.sol": { runs: 1000000 },
  "pair.sol": { runs: 1000000 },
  "mpcToken.sol": { runs: 200000 },
  "marketplace.sol": { runs: 200000 },
  "factory.sol": { runs: 10000000 },
  "erc20.sol": { runs: 200000 },
  "TokenLaunchManager.sol": { runs: 10000000 },
  "ICO.sol": { runs: 1000000 },
  "fundsManager.sol": { runs: 5000000 },
};

const envToContract = {
  ERC20: "erc20.sol",
  MPC: "mpcToken.sol",
  ERC721: "erc721.sol",
  PAIR: "pair.sol",
  TreasuryController: "treasuryController.sol",
  FACTORY: "factory.sol",
  FUNDS_MANAGER: "fundsManager.sol",
  TLM: "TokenLaunchManager.sol",
  ROUTER: "router.sol",
  ICO: "ICO.sol",
  Marketplace: "marketplace.sol",
};

function normalizePath(filePath) {
  return filePath.replace(/\\/g, "/");
}

function resolveOpenZeppelinPath(importPath) {
  if (importPath.includes("node_modules/@openzeppelin")) {
    const ozPath = importPath.substring(
      importPath.indexOf("@openzeppelin/contracts")
    );
    return ozPath;
  }

  if (importPath.startsWith("../../node_modules/@openzeppelin/contracts")) {
    return importPath.replace("../../node_modules/", "");
  }

  return importPath;
}

function getAllDependencies(contractPath) {
  const sources = {};
  const visited = new Set();
  const projectRoot = process.cwd();

  function addSource(filePath, sourceName) {
    const normalizedSourceName = normalizePath(sourceName);

    if (visited.has(normalizedSourceName)) return;
    visited.add(normalizedSourceName);

    let fullPath;
    let content;

    try {
      if (normalizedSourceName.startsWith("@openzeppelin/")) {
        fullPath = path.join(projectRoot, "node_modules", normalizedSourceName);
      } else if (path.isAbsolute(filePath)) {
        fullPath = filePath;
      } else {
        fullPath = path.resolve(projectRoot, filePath);
      }

      if (!fs.existsSync(fullPath)) {
        console.warn(`⚠️ Warning: File not found: ${fullPath}`);
        return;
      }

      content = fs.readFileSync(fullPath, "utf8");
      sources[normalizedSourceName] = { content };

      console.log(`✅ Added: ${normalizedSourceName}`);

      const importRegex =
        /import\s+(?:{[^}]*}|\*\s+as\s+\w+|\w+)?\s*(?:from\s+)?["']([^"']+)["'];/g;
      let match;

      while ((match = importRegex.exec(content)) !== null) {
        const rawImportPath = match[1];

        if (rawImportPath.includes("@openzeppelin/contracts")) {
          const ozPath = resolveOpenZeppelinPath(rawImportPath);
          addSource(path.join(projectRoot, "node_modules", ozPath), ozPath);
        } else if (
          rawImportPath.startsWith("./") ||
          rawImportPath.startsWith("../")
        ) {
          let resolvedPath;
          let resolvedSourceName;

          if (normalizedSourceName.startsWith("@openzeppelin/")) {
            const baseDir = path.dirname(normalizedSourceName);
            resolvedSourceName = normalizePath(
              path.posix.join(baseDir, rawImportPath)
            );
            resolvedPath = path.join(
              projectRoot,
              "node_modules",
              resolvedSourceName
            );
          } else {
            const currentDir = path.dirname(fullPath);
            resolvedPath = path.resolve(currentDir, rawImportPath);

            if (resolvedPath.includes("src")) {
              resolvedSourceName = normalizePath(
                path.relative(path.join(projectRoot, "src"), resolvedPath)
              );
            } else {
              resolvedSourceName = normalizePath(
                path.relative(projectRoot, resolvedPath)
              );
            }
          }

          if (fs.existsSync(resolvedPath)) {
            addSource(resolvedPath, resolvedSourceName);
          }
        }
      }
    } catch (e) {
      console.error(`❌ Error processing ${normalizedSourceName}:`, e.message);
    }
  }

  const contractName = normalizePath(
    path.relative(path.join(projectRoot, "src"), contractPath)
  );
  addSource(contractPath, contractName);
  return sources;
}

function generateVerificationFile(contractFile, optimizerRuns) {
  console.log(
    `🔍 Generating verification for ${contractFile} (runs: ${optimizerRuns})...`
  );

  const contractPath = path.join(
    process.cwd(),
    "src",
    "contracts",
    contractFile
  );

  if (!fs.existsSync(contractPath)) {
    console.error(`❌ Contract file not found: ${contractPath}`);
    return null;
  }

  try {
    const sources = getAllDependencies(contractPath);

    console.log(`📊 Found ${Object.keys(sources).length} source files`);

    const verificationInput = {
      language: "Solidity",
      sources,
      settings: {
        optimizer: {
          enabled: true,
          runs: optimizerRuns,
        },
        outputSelection: {
          "*": {
            "*": ["abi", "evm.bytecode", "evm.deployedBytecode"],
          },
        },
      },
    };

    const fileName = `verification-${path.basename(contractFile, ".sol")}.json`;
    fs.writeFileSync(fileName, JSON.stringify(verificationInput, null, 2));

    console.log(`✅ Generated ${fileName} with ${optimizerRuns} runs\n`);

    return fileName;
  } catch (error) {
    console.error(
      `❌ Error generating verification for ${contractFile}:`,
      error.message
    );
    return null;
  }
}

function generateAllFromEnv() {
  console.log(
    "🚀 Generating verification files for deployed contracts from .env...\n"
  );

  const deployedContracts = {};
  const missingContracts = [];

  Object.keys(envToContract).forEach((envKey) => {
    const address = process.env[envKey];
    if (address && address !== "") {
      deployedContracts[envKey] = {
        address: address,
        contractFile: envToContract[envKey],
        runs: compilationSettings[envToContract[envKey]]?.runs || 200,
      };
    } else {
      missingContracts.push(envKey);
    }
  });

  console.log("📋 Found deployed contracts in .env:");
  Object.entries(deployedContracts).forEach(([envKey, info]) => {
    console.log(
      `   ${envKey}: ${info.address} (${info.contractFile}, runs: ${info.runs})`
    );
  });

  if (missingContracts.length > 0) {
    console.log("\n⚠️ Missing addresses in .env:");
    missingContracts.forEach((key) => console.log(`   ${key}`));
  }

  console.log(`\n${"=".repeat(80)}`);

  const generatedFiles = [];
  const contractInfo = [];

  Object.entries(deployedContracts).forEach(([envKey, info]) => {
    console.log(`\n📦 Processing ${envKey} (${info.contractFile})...`);

    const verificationFile = generateVerificationFile(
      info.contractFile,
      info.runs
    );

    if (verificationFile) {
      generatedFiles.push(verificationFile);
      contractInfo.push({
        envKey,
        address: info.address,
        contractFile: info.contractFile,
        verificationFile,
        runs: info.runs,
      });
    }
  });

  const summaryInfo = {
    timestamp: new Date().toISOString(),
    network: process.env.NETWORK || "unknown",
    contracts: contractInfo,
  };

  fs.writeFileSync(
    "verification-summary.json",
    JSON.stringify(summaryInfo, null, 2)
  );

  console.log(`${"=".repeat(80)}`);
  console.log("🎉 VERIFICATION SUMMARY");
  console.log(`✅ Generated ${generatedFiles.length} verification files`);
  console.log("💾 Created verification-summary.json with all contract info");

  console.log("\n📋 CONTRACT VERIFICATION TABLE:");
  console.log(
    "┌─────────────────────┬──────────────────────────────────────────────┬─────────────────────────────────┬─────────────┐"
  );
  console.log(
    "│ Contract            │ Address                                      │ Verification File               │ Runs        │"
  );
  console.log(
    "├─────────────────────┼──────────────────────────────────────────────┼─────────────────────────────────┼─────────────┤"
  );

  contractInfo.forEach((info) => {
    const name = info.envKey.padEnd(19);
    const address = info.address.padEnd(44);
    const file = info.verificationFile.padEnd(31);
    const runs = info.runs.toString().padEnd(11);
    console.log(`│ ${name} │ ${address} │ ${file} │ ${runs} │`);
  });

  console.log(
    "└─────────────────────┴──────────────────────────────────────────────┴─────────────────────────────────┴─────────────┘"
  );

  console.log("\n🔗 ETHERSCAN VERIFICATION STEPS:");
  console.log(
    "1. Go to https://etherscan.io/verifyContract (or testnet equivalent)"
  );
  console.log("2. Enter contract address");
  console.log("3. Select 'Solidity (Standard-Json-Input)'");
  console.log("4. Upload the corresponding verification-[contract].json file");
  console.log("5. Optimization will be automatically detected from the file");
  console.log("6. Enter constructor arguments if any");

  console.log("\n📁 Generated files:");
  generatedFiles.forEach((file) => console.log(`   - ${file}`));
  console.log("   - verification-summary.json");
}

function generateSpecific(contractName) {
  const contractFile = envToContract[contractName];
  if (!contractFile) {
    console.error(`❌ Unknown contract: ${contractName}`);
    console.log("Available contracts:", Object.keys(envToContract).join(", "));
    return;
  }

  const address = process.env[contractName];
  if (!address) {
    console.error(`❌ Address not found in .env for ${contractName}`);
    return;
  }

  const runs = compilationSettings[contractFile]?.runs || 200;
  console.log(`📦 Generating verification for ${contractName}:`);
  console.log(`   Contract: ${contractFile}`);
  console.log(`   Address: ${address}`);
  console.log(`   Optimizer runs: ${runs}\n`);

  generateVerificationFile(contractFile, runs);
}

const args = process.argv.slice(2);

if (args.length === 0) {
  generateAllFromEnv();
} else if (args[0] === "--help" || args[0] === "-h") {
  console.log("Usage:");
  console.log(
    "  node verify-env-contracts.js                    # Generate for all contracts from .env"
  );
  console.log(
    "  node verify-env-contracts.js [CONTRACT_NAME]    # Generate for specific contract"
  );
  console.log(
    "  node verify-env-contracts.js --list             # List available contracts"
  );
  console.log(
    "  node verify-env-contracts.js --help             # Show this help"
  );
  console.log("");
  console.log("Available contracts:");
  Object.keys(envToContract).forEach((name) => {
    console.log(
      `  ${name} -> ${envToContract[name]} (runs: ${
        compilationSettings[envToContract[name]]?.runs || 200
      })`
    );
  });
} else if (args[0] === "--list") {
  console.log("Available contracts in .env mapping:");
  Object.entries(envToContract).forEach(([envKey, contractFile]) => {
    const runs = compilationSettings[contractFile]?.runs || 200;
    const address = process.env[envKey] || "NOT SET";
    console.log(`  ${envKey}: ${address} -> ${contractFile} (runs: ${runs})`);
  });
} else {
  generateSpecific(args[0]);
}
