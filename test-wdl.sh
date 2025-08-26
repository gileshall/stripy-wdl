#!/bin/bash

# Test script for STRipy WDL workflow using miniwdl
# Usage: ./test-wdl.sh [--docker-image IMAGE] [--no-cache] [--custom-catalog FILE]

set -e

# Default values
DOCKER_IMAGE="stripy-pipeline:latest"
NO_CACHE=""
MINIWDL_ARGS=""
CUSTOM_CATALOG=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --docker-image)
            DOCKER_IMAGE="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --custom-catalog)
            CUSTOM_CATALOG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --docker-image IMAGE    Docker image to use (default: stripy-pipeline:latest)"
            echo "  --no-cache             Build Docker image without cache"
            echo "  --custom-catalog FILE  Use custom variant catalog file"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Use default image"
            echo "  $0 --docker-image my-stripy:v1.0     # Use custom image"
            echo "  $0 --no-cache                         # Build without cache"
            echo "  $0 --custom-catalog my_catalog.json   # Use custom catalog"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🧪 Testing STRipy WDL workflow with miniwdl"
echo "Docker image: $DOCKER_IMAGE"
if [ -n "$CUSTOM_CATALOG" ]; then
    echo "Custom catalog: $CUSTOM_CATALOG"
fi
echo ""

# Check if miniwdl is installed
if ! command -v miniwdl &> /dev/null; then
    echo "❌ miniwdl not found. Please install it first:"
    echo "   pip install miniwdl"
    exit 1
fi

# Validate WDL with miniwdl check
echo "🔍 Validating WDL syntax..."
if ! miniwdl check stripy-pipeline.wdl; then
    echo "❌ WDL validation failed!"
    exit 1
fi
echo "✅ WDL validation passed"
echo ""

# Check if Docker image exists
if ! docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
    echo "⚠️  Docker image '$DOCKER_IMAGE' not found."
    echo "   Building it now..."
    ./build.sh $NO_CACHE --tag "$DOCKER_IMAGE"
    echo ""
fi

# Download CRAM file if it doesn't exist
if [ ! -f "NA12878/NA12878.final.cram" ]; then
    echo "📥 Downloading NA12878 CRAM file..."
    mkdir -p NA12878
    curl -L -o "NA12878/NA12878.final.cram" \
        "https://42basepairs.com/download/s3/1000genomes/1000G_2504_high_coverage/data/ERR3239334/NA12878.final.cram"
    echo "✅ CRAM file downloaded"
fi

# Download CRAM index if it doesn't exist
if [ ! -f "NA12878/NA12878.final.cram.crai" ]; then
    echo "📥 Downloading NA12878 CRAM index..."
    curl -L -o "NA12878/NA12878.final.cram.crai" \
        "https://42basepairs.com/download/s3/1000genomes/1000G_2504_high_coverage/data/ERR3239334/NA12878.final.cram.crai"
    echo "✅ CRAM index downloaded"
fi

# Download hg38 reference if it doesn't exist
if [ ! -f "references/hg38.fa" ]; then
    echo "📥 Downloading hg38 reference genome..."
    mkdir -p references
    if [ ! -f "references/hg38.fa.gz" ]; then
        curl -L -o "references/hg38.fa.gz" \
            "https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.gz"
    fi
    echo "🔧 Decompressing hg38.fa.gz..."
    gunzip -f "references/hg38.fa.gz"
    echo "✅ hg38 reference downloaded and decompressed"
fi

# Download hg38 index if it doesn't exist
if [ ! -f "references/hg38.fa.fai" ]; then
    echo "📥 Downloading hg38 reference index..."
    curl -L -o "references/hg38.fa.fai" \
        "https://hgdownload.soe.ucsc.edu/goldenpath/hg38/bigZips/hg38.fa.fai"
    echo "✅ hg38 index downloaded"
fi

# Update test inputs if custom catalog is specified
if [ -n "$CUSTOM_CATALOG" ]; then
    echo "📝 Updating test inputs with custom catalog..."
    if [ ! -f "$CUSTOM_CATALOG" ]; then
        echo "❌ Custom catalog file not found: $CUSTOM_CATALOG"
        exit 1
    fi
    # Create a temporary test inputs file with custom catalog
    cp test-inputs.json test-inputs-custom.json
    # Add custom catalog and remove locus parameter (since custom catalog defines loci)
    jq --arg catalog "$CUSTOM_CATALOG" '.STRipyPipeline.custom_catalog = $catalog | del(.STRipyPipeline.locus)' test-inputs-custom.json > temp.json && mv temp.json test-inputs-custom.json
    echo "✅ Custom catalog will be used: $CUSTOM_CATALOG"
    echo "ℹ️  Locus parameter removed (custom catalog defines loci to analyze)"
fi

# Create test outputs directory
mkdir -p test-outputs

echo "🚀 Starting WDL workflow test..."
echo ""

# Run the workflow with miniwdl
if [ -n "$CUSTOM_CATALOG" ]; then
    miniwdl run stripy-pipeline.wdl \
        -i test-inputs-custom.json \
        -d test-outputs \
        -v
else
    miniwdl run stripy-pipeline.wdl \
        -i test-inputs.json \
        -d test-outputs \
        -v
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ WDL workflow completed successfully!"
    
    # Count the number of test runs
    RUN_COUNT=$(find test-outputs -maxdepth 1 -type d -name "*STRipyPipeline*" | wc -l)
    echo "📊 Total test runs: $RUN_COUNT"
    
    # Clean up temporary files
    if [ -f "test-inputs-custom.json" ]; then
        rm "test-inputs-custom.json"
    fi
else
    echo ""
    echo "❌ WDL workflow failed!"
    
    # Clean up temporary files
    if [ -f "test-inputs-custom.json" ]; then
        rm "test-inputs-custom.json"
    fi
    exit 1
fi
