#!/bin/bash
set -e

SAMPLE_SHEET="sample_sheet.tsv"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $SAMPLE_SHEET)

SAMPLE=$(echo $LINE | awk '{print $1}')
R1=$(echo $LINE | awk '{print $2}')
R2=$(echo $LINE | awk '{print $3}')

echo "Running sample: $SAMPLE"

bash pipeline.sh $SAMPLE $R1 $R2
