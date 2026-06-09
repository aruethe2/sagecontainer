# Example entry point. The container's runscript executes this file and
# forwards any CLI arguments, so:
#
#   sbatch slurm/run_sage.sbatch                    -> default demo curve
#   sbatch slurm/run_sage.sbatch --curve 0,0,0,-4,4 -> custom curve
#   sbatch slurm/run_sage.sbatch --primes 10000     -> different task entirely
#
# Outputs go to /output (bind-mounted by the Slurm script).

import argparse
import os
import sys

parser = argparse.ArgumentParser(description="Sage demo job")
parser.add_argument(
    "--curve",
    type=str,
    default="0,-1,1,-10,-20",
    help="comma-separated a-invariants a1,a2,a3,a4,a6 (default: 0,-1,1,-10,-20)",
)
parser.add_argument(
    "--primes",
    type=int,
    default=None,
    help="if set, skip the curve and count primes up to this bound instead",
)
args = parser.parse_args()

print(f"SageMath version: {version()}")
print(f"Arguments: {vars(args)}")

outdir = "/output" if os.path.isdir("/output") else "."
outfile = os.path.join(outdir, "result.txt")

if args.primes is not None:
    # Optional alternate task
    bound = Integer(args.primes)
    count = prime_pi(bound)
    print(f"pi({bound}) = {count}")
    result = f"pi({bound}) = {count}\n"
else:
    # Default task, with optionally user-supplied curve coefficients
    try:
        ainvs = [Integer(c) for c in args.curve.split(",")]
        E = EllipticCurve(ainvs)
    except (ValueError, ArithmeticError) as e:
        print(f"Invalid curve coefficients {args.curve!r}: {e}", file=sys.stderr)
        sys.exit(1)
    r = E.rank()
    print(f"Rank of {E}: {r}")
    result = f"curve = {ainvs}\nrank = {r}\n"

with open(outfile, "w") as f:
    f.write(result)
print(f"Wrote results to {outfile}")

