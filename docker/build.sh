#!/bin/bash

# STRipy-pipeline Docker Build Script
# Usage: ./build.sh [--no-cache] [--tag custom-tag]

set -e

# Default values
TAG="stripy-pipeline:latest"
BUILD_ARGS=""

echo "Building STRipy-pipeline Docker image..."
echo "Tag: $TAG"
echo "Build args: $BUILD_ARGS"
echo ""

# Build the Docker image
echo "Starting Docker build..."
docker build \
    $BUILD_ARGS \
    --platform linux/amd64 \
    -t "$TAG" \
    -f Dockerfile \
    .
