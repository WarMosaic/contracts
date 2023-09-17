[![ci](https://github.com/WarMosaic/contracts/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/WarMosaic/contracts/actions/workflows/ci.yml)

# WarMosaic contracts

The EVM smart contracts for [WarMosaic](https://warmosaic.com).

## Development

_Note: We use [Gemforge](https://gemforge.xyz) to manage deployments. [Node.js](https://nodejs.org) 20+ and [PNPM](https://pnpm.io) 8+ is required_.

Install:

- Install [foundry](https://github.com/foundry-rs/foundry/blob/master/README.md)
- Run `foundryup`
- Run `forge install foundry-rs/forge-std`
- Run `pnpm i`
- Run `git submodule update --init --recursive`
- Create `.env` and set the following within:

```
export SEPOLIA_RPC_URL=...
export MNEMONIC=...
export ETHERSCAN_API_KEY=...
```

### Build

```zsh
pnpm build
```

### Deploy Locally

Run in a new terminal:

```zsh
pnpm devnet
```

Then run in a separate terminal:

```zsh
pnpm dep local
```

The contract addresses can be found in `gemforge.deployments.json`.

### Deploy to Sepolia

```
pnpn deploy sepolia
```

The contract addresses can be found in `gemforge.deployments.json`.

## License

MIT - see [LICENSE.md](LICENSE.md)