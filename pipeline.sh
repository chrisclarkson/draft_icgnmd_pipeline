#!/bin/bash
set -e

source config.sh

if [ "$ALIGNER" = "bwa" ]; then
    echo "Running BWA-MEM alignment"
    bwa mem -t $THREADS $REF $R1 $R2 | samtools sort -@ $THREADS -o ${SAMPLE}.bam
    gatk MarkDuplicates \
    -I ${SAMPLE}.bam \
    -O ${SAMPLE}.dedup.bam \
    -M ${SAMPLE}.metrics.txt

    samtools index ${SAMPLE}.dedup.bam
elif [ "$ALIGNER" = "minimap2" ]; then
    echo "Running minimap2 alignment"
    minimap2 -ax sr -t $THREADS $REF $R1 $R2 | samtools sort -@ $THREADS -o ${SAMPLE}.bam
fi

samtools index ${SAMPLE}.bam

if [ "$CALLER" = "gatk" ]; then
    echo "Running GATK HaplotypeCaller"

    gatk HaplotypeCaller \
        -R $REF \
        -I ${SAMPLE}.dedup.bam \
        -O ${SAMPLE}.g.vcf.gz \
        -ERC GVCF

elif [ "$CALLER" = "deepvariant" ]; then
    echo "Running DeepVariant"

    run_deepvariant \
        --model_type=WGS \
        --ref=$REF \
        --reads=${SAMPLE}.dedup.bam \
        --output_vcf=${SAMPLE}.vcf.gz \
        --num_shards=$THREADS
fi
