#!/usr/bin/env node
(async () => {
  require('dotenv').config()
  const { $ } = (await import('execa'))

  const addresses = require('../gemforge.deployments.json')

  const chainId = process.env.GEMFORGE_DEPLOY_CHAIN_ID
  if (!chainId) {
    throw new Error('GEMFORGE_DEPLOY_CHAIN_ID env var not set')
  }

  // skip localhost
  if (chainId === '31337') {
    console.log('Skipping verification on localhost')
    return
  }

  console.log(`Verifying on chain ${chainId} ...`)

  const contracts = addresses[chainId] || []

  for (let { name, contract } of contracts) {
    let args = '0x'

    if (contract.constructorArgs.length) {
      args = (await $`cast abi-encode constructor(address) ${contract.constructorArgs.join(' ')}`).stdout
    }

    console.log(`Verifying ${name} at ${contract.address} with args ${args}`)

    await $`forge verify-contract ${contract.address} ${name} --constructor-args ${args} --chain-id ${chainId} --verifier etherscan --etherscan-api-key ${process.env.ETHERSCAN_API_KEY} --watch`

    console.log(`Verified!`)
  }
})()
