#!/bin/bash
#SBATCH --job-name=sage-job
#SBATCH --partition=compute
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=sage-job-%N-%j.out
#SBATCH --mail-type=ALL
#SBATCH --mail-user=NetID@swarthmore.edu

set -euo pipefail

## Set the value of BIGSCRATCH to 'true' if your job is
## anticipated to require more than a few hundred gigabytes
## of scratch space, which includes all input, temporary,
## and output data. If BIGSCRATCH is true, then the job
## will use scratch space on the parallel storage node.
## This is slower than local scratch space on the compute
## nodes but has significantly more space.
BIGSCRATCH=false

SCRATCHDIR='scratch'
if [ "$BIGSCRATCH" = true ]
then
        SCRATCHDIR='data/scratch'
fi

## Move files to the scratch location so we can execute the
## job. Make certain to replace the placeholder filenames
## below (main.sage) with all files required
## for your job (wildcards such as * are allowed, and by
## default any directories listed will be copied recursively).
mkdir -p /$SCRATCHDIR/$USER/$SLURM_JOB_NAME-$SLURM_JOB_ID
cp -r \
main.sage \
/$SCRATCHDIR/$USER/$SLURM_JOB_NAME-$SLURM_JOB_ID

## Change to the scratch directory.
cd /$SCRATCHDIR/$USER/$SLURM_JOB_NAME-$SLURM_JOB_ID

# Where the container image lives. Pin to a commit SHA for reproducible
# runs, or use :latest to always get the most recent build.
REPO="ghcr.io/aruethe2/sagecontainer/sage-job"
TAG="${SAGE_IMAGE_TAG:-latest}"
SIF="/$SCRATCHDIR/$USER/$SLURM_JOB_NAME-$SLURM_JOB_ID/sage-job-${TAG}.sif"

# Pull (or refresh) the image. If the GHCR package is private, first run
# `apptainer registry login oras://ghcr.io` interactively with a PAT,
# or make the package public in the repo's package settings.
apptainer pull --force "$SIF" "oras://${REPO}:${TAG}"

# Keep Sage's threading honest with the Slurm allocation.
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
export SAGE_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}

# Run the container's default runscript (sage /opt/sage-code/main.sage),
# binding a scratch/output directory so results land outside the container.
OUTDIR="results-$SLURM_JOB_ID"
mkdir -p "$OUTDIR"

apptainer run --bind "$OUTDIR:/output" "$SIF" "$@"

## Move any outputs and files back to the original submit
## directory and clean-up. Delete the .sif file.
rm $SIF
cp -pru /$SCRATCHDIR/$USER/$SLURM_JOB_NAME-$SLURM_JOB_ID/* $SLURM_SUBMIT_DIR
cd
rm -rf /$SCRATCHDIR/$USER/$SLURM_JOB_NAME-$SLURM_JOB_ID

## Hang out for 10 seconds just to ensure all actions complete.
sleep 10
