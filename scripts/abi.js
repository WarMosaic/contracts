#!/usr/bin/env node
(async () => {
  const path = require('path')
  const fs = require('fs')
  const glob = require('glob')
  const outDir = path.join(__dirname, '..', 'out')
  const jsonFiles = glob.sync(`${outDir}/**/*.json`)

  const abi = []

  jsonFiles.forEach(f => {
    try {
      const j = require(f)
      if (j.abi) {
        if (f.endsWith('IDiamondProxy.json')) {
          abi.push(...j.abi)
        } else {
          abi.push(...j.abi.filter(({ type }) => type === 'error'))
        }
      }
    } catch (e) {}
  })

  fs.writeFileSync(path.join(outDir, 'abi.json'), JSON.stringify(abi, null, 2), 'utf-8')
})()
