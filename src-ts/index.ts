import type { TargetDeploymentRecords } from 'gemforge/build/shared/chain'
import type { Fragment } from '@ethersproject/abi'

export const deployedAddresses = require("../gemforge.deployments.json") as TargetDeploymentRecords

export const IDiamondProxy = require("../out/abi.json").abi as Fragment[]
