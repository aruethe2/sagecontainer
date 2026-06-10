#!/bin/bash
#SBATCH --job-name=sage-job
#SBATCH --partition=compute          # adjust to your cluster
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=sage-job-%j.out
#SBATCH --error=sage-job-%j.err

set -euo pipefail

# Where the container image lives. Pin to a commit SHA for reproducible
# runs, or use :latest to always get the most recent build.
REPO="ghcr.io/aruethe2/sagecontainer/sage-job"
TAG="${SAGE_IMAGE_TAG:-latest}"
SIF="$SLURM_SUBMIT_DIR/sage-job-${TAG}.sif"

# Pull (or refresh) the image. If the GHCR package is private, first run
# `apptainer registry login oras://ghcr.io` interactively with a PAT,
# or make the package public in the repo's package settings.
apptainer pull --force "$SIF" "oras://${REPO}:${TAG}"

# Keep Sage's threading honest with the Slurm allocation.
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export SAGE_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

# Run the container's default runscript (sage /opt/sage-code/main.sage),
# binding a scratch/output directory so results land outside the container.
OUTDIR="$SLURM_SUBMIT_DIR/results-$SLURM_JOB_ID"
mkdir -p "$OUTDIR"

apptainer run --bind "$OUTDIR:/output" "$SIF" "$@"
