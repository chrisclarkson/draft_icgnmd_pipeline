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


if [ "$ALIGNER" = "bwa" ]; then
    echo "Running BWA-MEM alignment"
    bwa mem -Y -t $THREADS $REF $R1 $R2 | samtools sort -@ $THREADS -o ${SAMPLE}.bam
    gatk MarkDuplicates \
        -I ${SAMPLE}.bam \
        -O ${SAMPLE}.dedup.bam \
        -M ${SAMPLE}.metrics.txt
    samtools index ${SAMPLE}.dedup.bam
    gatk BaseRecalibrator \
        -R reference.fa \
        -I ${SAMPLE}.dedup.bam \
        --known-sites dbsnp.vcf.gz #must be predownloaded \
        --known-sites mills_indels.vcf.gz #must be predownloaded \
        -O sample.recal.table
    gatk ApplyBQSR \
        -R reference.fa \
        -I ${SAMPLE}.dedup.bam \
        --bqsr-recal-file sample.recal.table \
        -O ${SAMPLE}.recalibrated.bam
elif [ "$ALIGNER" = "minimap2" ]; then
    echo "Running minimap2 alignment"
    minimap2 -ax sr -t $THREADS $REF $R1 $R2 | samtools sort -@ $THREADS -o ${SAMPLE}.bam
fi

samtools index ${SAMPLE}.bam
REF="/path/to/refererenc.fa"
if [ "$CALLER" = "gatk" ]; then
    echo "Running GATK HaplotypeCaller"

    gatk HaplotypeCaller \
        -R $REF \
        -I ${SAMPLE}.recalibrated.bam \
        -O ${SAMPLE}.g.vcf.gz \
        -ERC GVCF
   gatk CombineGVCFs \
        -R reference.fa \
        -V *.g.vcf.gz \
        -O cohort.g.vcf.gz
    gatk GenotypeGVCFs \
        -R reference.fa \
        -V cohort.g.vcf.gz \
        -O cohort.vcf.gz

elif [ "$CALLER" = "deepvariant" ]; then
    echo "Running DeepVariant"
    if [ "$ALIGNER" = "bwa" ]; then
        BAM="${SAMPLE}.dedup.bam"
    elif [ "$ALIGNER" = "minimap2" ]; then
        BAM="${SAMPLE}.bam"
    fi
    run_deepvariant \
        --model_type=WGS \
        --ref=$REF \
        --reads=${BAM} \
        --output_vcf=${SAMPLE}.vcf.gz \
        --output_gvcf=${SAMPLE}.g.vcf.gz \
        --num_shards=$THREADS
fi

