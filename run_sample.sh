#!/bin/bash
set -e

JA="${1}"
ALIGNER="${2}"
CALLER="${3}"
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $JA)

SAMPLE=$(echo $LINE | awk '{print $1}')
R1=$(echo $LINE | awk '{print $2}')
R2=$(echo $LINE | awk '{print $3}')

echo "Running sample: $SAMPLE"

bash pipeline.sh $SAMPLE $R1 $R2 $ALIGNER $CALLER
