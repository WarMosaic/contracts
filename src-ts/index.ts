import type { TargetDeploymentRecords } from 'gemforge/build/shared/chain'
import type { Fragment } from '@ethersproject/abi'

export const deployedAddresses = require("../gemforge.deployments.json") as TargetDeploymentRecords

export const abi = require("../out/abi.json") as Fragment[]
