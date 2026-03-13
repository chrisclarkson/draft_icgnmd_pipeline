#!/bin/bash
#SBATCH --job-name=example
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=24:00:00

bash map_and_call_variants_sample.sh $1 $2 $3
