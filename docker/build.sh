#!/bin/bash

# STRipy-pipeline Docker Build Script
# Usage: ./build.sh [--no-cache] [--tag custom-tag]

set -e

# Default values
NO_CACHE=""
TAG="stripy-pipeline:latest"
BUILD_ARGS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --expansionhunter-version)
            BUILD_ARGS="$BUILD_ARGS --build-arg EXPANSIONHUNTER_VERSION=$2"
            shift 2
            ;;
        --reviewer-version)
            BUILD_ARGS="$BUILD_ARGS --build-arg REVIEWER_VERSION=$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-cache                 Build without using cache"
            echo "  --tag TAG                  Docker image tag (default: stripy-pipeline:latest)"
            echo "  --expansionhunter-version  ExpansionHunter version (default: 5.0.0)"
            echo "  --reviewer-version         REViewer version (default: 0.2.7)"
            echo "  -h, --help                 Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Basic build"
            echo "  $0 --no-cache                         # Build without cache"
            echo "  $0 --tag my-stripy:v1.0              # Custom tag"
            echo "  $0 --expansionhunter-version 4.0.0   # Custom ExpansionHunter version"
            echo "  $0 --reviewer-version 0.2.6            # Custom REViewer version"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Building STRipy-pipeline Docker image..."
echo "Tag: $TAG"
echo "Build args: $BUILD_ARGS"
echo "Cache: $([ -n "$NO_CACHE" ] && echo "disabled" || echo "enabled")"
echo ""

# Check if requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo "Warning: requirements.txt not found. Creating a basic one..."
    cat > requirements.txt << 'EOF'
numpy>=1.21.0
pandas>=1.3.0
pysam>=0.19.0
requests>=2.25.0
matplotlib>=3.5.0
tqdm>=4.62.0
click>=8.0.0
EOF
fi

# Build the Docker image
echo "Starting Docker build..."
docker build \
    $NO_CACHE \
    $BUILD_ARGS \
    --platform linux/amd64 \
    -t "$TAG" \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully!"
    echo "Image: $TAG"
    echo ""
    echo "Quick test command:"
    echo "docker run --rm $TAG --help"
    echo ""
    echo "Example usage:"
    echo "docker run --rm -v \$(pwd)/data:/data -v \$(pwd)/output:/output -v \$(pwd)/references:/references $TAG \\"
    echo "  --input /data/sample.bam \\"
    echo "  --genome hg38 \\"
    echo "  --reference /references/hg38.fa \\"
    echo "  --output /output \\"
    echo "  --locus HTT,ATXN3,AFF2"
    echo ""
    echo "Or use docker-compose:"
    echo "docker-compose up stripy-pipeline"
else
    echo "❌ Build failed!"
    exit 1
fi
