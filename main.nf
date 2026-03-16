nextflow.enable.dsl=2

reads = Channel.fromFilePairs("data/*_{R1,R2}.fastq.gz")

process ALIGN_MINIMAP {

    tag "$sample"

    input:
    tuple val(sample), path(reads)

    output:
    tuple val(sample), path("${sample}.bam")

    script:
        """
        minimap2 -ax sr ${params.ref} ${reads[0]} ${reads[1]} \
        | samtools sort -o ${sample}.bam
        samtools index ${sample}.bam
        """
}

process ALIGN_BWA {

    tag "$sample"

    input:
    tuple val(sample), path(reads)

    output:
    tuple val(sample), path("${sample}.bam")

    script:
        """
        bwa mem -K 1000000000 -Y -t 16 ${params.ref} ${reads[0]} ${reads[1]} \
        | samtools sort -o ${sample}.bam
        samtools index ${sample}.bam
        """
}


process DEDUP {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    tuple val(sample), path("${sample}.dedup.bam")

    script:
    """
    gatk MarkDuplicates \
        -I ${bam} \
        -O ${sample}.dedup.bam \
        -M ${sample}.metrics.txt

    samtools index ${sample}.dedup.bam
    """
}


process BQSR_TABLE {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    tuple val(sample), path("${sample}.recal.table"), path(bam)

    script:
    """
    gatk BaseRecalibrator \
        -R ${params.ref} \
        -I ${bam} \
        --known-sites ${params.dbsnp} \
        --known-sites ${params.mills} \
        -O ${sample}.recal.table
    """
}


process APPLY_BQSR {

    tag "$sample"

    input:
    tuple val(sample), path(table), path(bam)

    output:
    tuple val(sample), path("${sample}.recal.bam")

    script:
    """
    gatk ApplyBQSR \
        -R ${params.ref} \
        -I ${bam} \
        --bqsr-recal-file ${table} \
        -O ${sample}.recal.bam
    """
}


process CALL_VARIANTS_GATK {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    path("${sample}.g.vcf.gz")

    script:
        """
        gatk HaplotypeCaller \
            -R ${params.ref} \
            -I ${bam} \
            -O ${sample}.g.vcf.gz \
            -ERC GVCF
        """
}
process CALL_VARIANTS_DEEPVARIANT {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    path("${sample}.g.vcf.gz")

    script:
         """
        run_deepvariant \
            --model_type=WGS \
            --ref=${params.ref} \
            --reads=${bam} \
            --output_vcf=${sample}.vcf.gz
        """
}
       

process COMBINE_GVCFS {

    input:
    path gvcfs

    output:
    path "cohort.g.vcf.gz"

    script:
    """
    gatk CombineGVCFs \
        -R ${params.ref} \
        ${gvcfs.collect{ "-V $it" }.join(' ')} \
        -O cohort.g.vcf.gz
    """
}


process GENOTYPE_GVCFS {

    input:
    path "cohort.g.vcf.gz"

    output:
    path "cohort.vcf.gz"

    script:
    """
    gatk GenotypeGVCFs \
        -R ${params.ref} \
        -V cohort.g.vcf.gz \
        -O cohort.vcf.gz
    """
}


workflow {
    if (params.caller == "gatk"){
        aligned = ALIGN_BWA(reads)
        deduped = DEDUP(aligned)

        recal_tables = BQSR_TABLE(deduped)

        recalibrated = APPLY_BQSR(recal_tables)
        gvcfs = CALL_VARIANTS_GATK(recalibrated)
        combined = COMBINE_GVCFS(gvcfs.collect())

        GENOTYPE_GVCFS(combined)
    }
    else{
        aligned = ALIGN_MINIMAP(reads)
        gvcfs = CALL_VARIANTS_DEEPVARIANT(aligned)
        combined = COMBINE_GVCFS(gvcfs.collect())

        GENOTYPE_GVCFS(combined)
    }

}