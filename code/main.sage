# Example entry point. The container's runscript executes this file.
# Write any outputs to /output (bind-mounted by the Slurm script).

import os, sys

print(f"SageMath version: {version()}")
print(f"Arguments: {sys.argv[1:]}")

# Demo computation
E = EllipticCurve([0, -1, 1, -10, -20])
print(f"Rank of {E}: {E.rank()}")

outdir = "/output" if os.path.isdir("/output") else "."
with open(os.path.join(outdir, "result.txt"), "w") as f:
    f.write(f"rank = {E.rank()}\n")
print(f"Wrote the results to {outdir}/result.txt")
