#!/usr/bin/env bash


SAMPLE=$1
READS=$2
REF=$3
THREADS=32

OUTDIR=lr_results/${SAMPLE}

mkdir -p ${OUTDIR}/{alignment,small_variants,sv,repeats,assembly,merged,phasing}

echo " ALIGNMENT "

minimap2 \
  -t $THREADS \
  -ax map-hifi \
  $REF \
  $READS \
| samtools sort -@ $THREADS \
  -o ${OUTDIR}/alignment/${SAMPLE}.bam

samtools index ${OUTDIR}/alignment/${SAMPLE}.bam


echo " DEEPVARIANT "

run_deepvariant \
  --model_type=PACBIO \
  --ref=$REF \
  --reads=${OUTDIR}/alignment/${SAMPLE}.bam \
  --output_vcf=${OUTDIR}/small_variants/${SAMPLE}.deepvariant.vcf.gz \
  --num_shards=$THREADS


echo " CLAIR3 "

run_clair3.sh \
  --bam ${OUTDIR}/alignment/${SAMPLE}.bam \
  --ref $REF \
  --threads $THREADS \
  --platform hifi \
  --output ${OUTDIR}/small_variants/clair3


echo " SNIFFLES2 "

sniffles \
  --input ${OUTDIR}/alignment/${SAMPLE}.bam \
  --vcf ${OUTDIR}/sv/${SAMPLE}.sniffles.vcf.gz \
  --threads $THREADS


echo "SVIM"

svim alignment \
  ${OUTDIR}/sv/svim \
  ${OUTDIR}/alignment/${SAMPLE}.bam \
  $REF

echo "STRAGLR"

python straglr.py ${OUTDIR}/alignment/${SAMPLE}.bam \
    $REF ${OUTDIR}/repeats/${SAMPLE}_straglr \
    --exclude centromeres_telomeres_regions.bed

echo "Final repeats results in ${OUTDIR}/repeats/${SAMPLE}_straglr.vcf.gz"

echo "PHASING"

whatshap phase \
  --reference $REF \
  ${OUTDIR}/small_variants/${SAMPLE}.deepvariant.vcf.gz \
  ${OUTDIR}/alignment/${SAMPLE}.bam \
  -o ${OUTDIR}/phasing/${SAMPLE}.phased.vcf.gz



echo "HIFIASM ASSEMBLY"

hifiasm \
  -o ${OUTDIR}/assembly/${SAMPLE} \
  -t $THREADS \
  $READS

echo "ASSEMBLY SV CALLING"

minimap2 \
  -ax asm5 \
  $REF \
  ${OUTDIR}/assembly/${SAMPLE}.asm.hap1.fa \
| samtools sort -o ${OUTDIR}/assembly/hap1.bam

minimap2 \
  -ax asm5 \
  $REF \
  ${OUTDIR}/assembly/${SAMPLE}.asm.hap2.fa \
| samtools sort -o ${OUTDIR}/assembly/hap2.bam


echo "MERGING SVs"

truvari collapse \
  --in ${OUTDIR}/sv/${SAMPLE}.sniffles.vcf.gz \
  --in2 ${OUTDIR}/sv/svim/variants.vcf \
  --output ${OUTDIR}/merged/${SAMPLE}.merged_sv.vcf



echo " FINAL VARIANT SET "

bcftools concat \
  -a \
  ${OUTDIR}/small_variants/${SAMPLE}.deepvariant.vcf.gz \
  ${OUTDIR}/merged/${SAMPLE}.merged_sv.vcf \
  -Oz \
  -o ${OUTDIR}/merged/${SAMPLE}.final.vcf.gz

bcftools index ${OUTDIR}/merged/${SAMPLE}.final.vcf.gz


echo "Final SNVs and SVs: ${OUTDIR}/merged/${SAMPLE}.final.vcf.gz"
echo "Final repeats results in ${OUTDIR}/repeats/${SAMPLE}_straglr.vcf.gz"
