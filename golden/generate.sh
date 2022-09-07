#!/bin/bash
set -euo pipefail

# Get directory of this script
GOLDEN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Clean existing golden files
rm -rf $GOLDEN_DIR/generated

# Generate golden files
for d in $GOLDEN_DIR/values/*; do
  chartname=$(basename $d)
  for f in $d/*.yaml; do
    filename=$(basename -- "$f" .yaml)
    helm template exadeploy $GOLDEN_DIR/../charts/$chartname -n default -f $f --output-dir $GOLDEN_DIR/generated/$chartname/$filename > /dev/null
    mv $GOLDEN_DIR/generated/$chartname/$filename/$chartname/templates/* $GOLDEN_DIR/generated/$chartname/$filename
    rm -rf $GOLDEN_DIR/generated/$chartname/$filename/$chartname/
  done
done
