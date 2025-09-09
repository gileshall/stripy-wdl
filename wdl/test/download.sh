#!/bin/bash
set -e

DIR="$(dirname "$0")"

mkdir -p "$DIR/NA12878"
mkdir -p "$DIR/hg38"

curl -C - -L -o \
    "${DIR}/NA12878/NA12878.final.cram" \
    "https://42basepairs.com/download/s3/1000genomes/1000G_2504_high_coverage/data/ERR3239334/NA12878.final.cram"

curl -C - -L -o \
    "${DIR}/NA12878/NA12878.final.cram.crai" \
    "https://42basepairs.com/download/s3/1000genomes/1000G_2504_high_coverage/data/ERR3239334/NA12878.final.cram.crai"

curl -C - -L -o \
    "${DIR}/hg38/hg38.fa" \
    "https://s3.amazonaws.com/igv.broadinstitute.org/genomes/seq/hg38/hg38.fa"

curl -C - -L -o \
    "${DIR}/hg38/hg38.fa.fai" \
    "https://s3.amazonaws.com/igv.broadinstitute.org/genomes/seq/hg38/hg38.fa.fai"

