#!/usr/bin/env bash


########################################
# INPUTS
########################################

SAMPLE=$1
R1=$2
R2=$3
REF=$4
GTF=$5

THREADS=16

OUTDIR=rna_results/${SAMPLE}
mkdir -p $OUTDIR

########################################
# 1 STAR alignment
########################################

echo "Running STAR..."
if [ ! -f ${OUTDIR}/${SAMPLE}.bam ]
then
    STAR \
        --runThreadN $THREADS \
        --genomeDir star_index \
        --readFilesIn $R1 $R2 \
        --readFilesCommand zcat \
        --outFileNamePrefix ${OUTDIR}/${SAMPLE}. \
        --outSAMtype BAM SortedByCoordinate

    mv ${OUTDIR}/${SAMPLE}.Aligned.sortedByCoord.out.bam ${OUTDIR}/${SAMPLE}.bam
    samtools index ${OUTDIR}/${SAMPLE}.bam
else
    echo "${OUTDIR}/${SAMPLE}.bam already exists"
fi
################################################
# VCF specified to drop separately
################################################

echo "Running DROP..."

drop run drop_config.yaml

echo "DONE"
