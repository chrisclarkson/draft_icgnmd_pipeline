#!/bin/bash
#SBATCH --job-name=wgs_pipeline
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --array=1-100

bash run_sample.sh
