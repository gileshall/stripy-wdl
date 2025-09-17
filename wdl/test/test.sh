#!/bin/bash
set -e

DIR=$(dirname "$0")
miniwdl check ../stripy-pipeline.wdl
miniwdl run ../stripy-pipeline.wdl -i test-inputs.json -d "$DIR/test-output"
