# Sage → Apptainer → Slurm pipeline

Commit Sage code, GitHub Actions builds a self-contained Apptainer image, and the cluster pulls and runs it as a Slurm job.

## Repository layout

```
.github/workflows/build-sage-container.yml   CI workflow
container/sage.def                           Apptainer definition
code/main.sage                               Your Sage entry point (edit me)
slurm/run_sage.sbatch                        Submission script for the cluster
```

## How it works

1. A push to `main` that touches `code/` or `container/` triggers the workflow.
2. The runner installs Apptainer, builds `sage-job.sif` from `container/sage.def` (which bakes `code/` into the image at `/opt/sage-code`), and runs `apptainer test` as a smoke test.
3. The SIF is pushed to GitHub Container Registry as an ORAS artifact, tagged `latest` and with the commit SHA. It's also attached as a workflow artifact as a fallback.
4. On the cluster, `sbatch slurm/run_sage.sbatch` pulls the image and runs it. The container's runscript executes `sage /opt/sage-code/main.sage`, forwarding any arguments you pass to `sbatch ... script args`.

## One-time setup

1. Edit `REPO` in `slurm/run_sage.sbatch` to your `ghcr.io/<user>/<repo>/sage-job` path.
2. After the first push, go to the package on GitHub (Profile → Packages → sage-job) and either make it **public** (simplest for the cluster) or, if it must stay private, authenticate on the cluster once with a classic PAT that has `read:packages`:

   ```
   apptainer registry login --username <gh-user> oras://ghcr.io
   ```

3. Make sure your cluster's login/compute nodes can reach `ghcr.io`. If they can't, download the workflow artifact instead and `scp` the SIF over.

## Running on the cluster

```
sbatch slurm/run_sage.sbatch                # runs main.sage
sbatch slurm/run_sage.sbatch --n 1000      # args are forwarded to main.sage
SAGE_IMAGE_TAG=<commit-sha> sbatch slurm/run_sage.sbatch   # pin a specific build
```

Outputs written to `/output` inside the container land in `results-<jobid>/` next to where you submitted.

## Notes and knobs

- **Image size**: the image installs core Sage from conda-forge on a micromamba base — typically ~2 GB instead of the ~6+ GB official Docker image. Need extra Python packages? Add them to the `micromamba install` line in `container/sage.def` (e.g. `numpy scipy pandas`).
- **Reproducibility**: pin the Sage version in `sage.def` (pinned to `sage=10.4` in the conda install) and submit jobs with the commit-SHA tag rather than `latest`.
- **Different entry point**: change the `%runscript` in `sage.def`, or override at runtime with `apptainer exec sage-job.sif sage /opt/sage-code/whatever.sage`.
- **MPI / GPU**: add `--nv` to the `apptainer run` line for CUDA, or restructure with `srun apptainer exec ...` for multi-task MPI jobs.
