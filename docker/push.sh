#!/bin/bash

set -e

# Defaults
TAG="${TAG:-stripy-pipeline:latest}"
PROJECT_ID="${GCS_PROJECT_ID:-}"
REGION="${GCS_REGION:-us-central1}"
REPOSITORY="${GCS_REPOSITORY:-stripy}"

# Args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      TAG="$2"; shift 2 ;;
    --project)
      PROJECT_ID="$2"; shift 2 ;;
    --region)
      REGION="$2"; shift 2 ;;
    --repo|--repository)
      REPOSITORY="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  echo "Missing --project or GCS_PROJECT_ID"; exit 1
fi

IMAGE_NAME_NO_TAG="${TAG%%:*}"
IMAGE_TAG_PART="${TAG##*:}"
GCS_IMAGE_NAME="$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/$IMAGE_NAME_NO_TAG:$IMAGE_TAG_PART"

echo "Pushing $TAG to $GCS_IMAGE_NAME"

docker tag "$TAG" "$GCS_IMAGE_NAME"

gcloud auth configure-docker "$REGION"-docker.pkg.dev --quiet

if ! gcloud artifacts repositories describe "$REPOSITORY" \
  --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$REPOSITORY" \
    --repository-format=docker \
    --location="$REGION" \
    --project="$PROJECT_ID"
fi

docker push "$GCS_IMAGE_NAME"

echo "Pushed: $GCS_IMAGE_NAME"


