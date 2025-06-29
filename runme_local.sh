#!/bin/bash
set -e

echo "Running a test container from ci-cd-github-runner:local..."
docker run --rm -it ci-cd-github-runner:local bash 