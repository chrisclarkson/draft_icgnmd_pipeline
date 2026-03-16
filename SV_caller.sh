#!/usr/bin/env bash

SAMPLE=$1
R1=$2
R2=$3
REF=$4
THREADS=16

OUTDIR=${SAMPLE}_SVs_called

mkdir -p $OUTDIR

echo "Aligning reads..."

minimap2 \
    -ax sr \
    -t $THREADS \
    $REF \
    $R1 \
    $R2 \
| samtools sort \
    -@ $THREADS \
    -o ${OUTDIR}/${SAMPLE}.sorted.bam


echo "Indexing BAM..."

samtools index ${OUTDIR}/${SAMPLE}.sorted.bam


echo "Configuring Manta..."

configManta.py \
    --bam ${OUTDIR}/${SAMPLE}.sorted.bam \
    --referenceFasta $REF \
    --runDir ${OUTDIR}/manta_run


echo "Running Manta..."

${OUTDIR}/manta_run/runWorkflow.py \
    -m local \
    -j $THREADS


echo "SV calls located at:"

echo "${OUTDIR}/manta_run/results/variants/diploidSV.vcf.gz"
