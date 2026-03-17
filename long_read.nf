nextflow.enable.dsl=2

reads = Channel.fromPath(params.reads)

process ALIGN {

    tag "$sample"

    input:
    path reads

    output:
    tuple val(reads.baseName), path("aligned.bam")

    script:
    """
    minimap2 -ax map-hifi -t ${task.cpus} ${params.ref} ${reads} \
    | samtools sort -@ ${task.cpus} -o aligned.bam
    samtools index aligned.bam
    """
}

process DEEPVARIANT {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    path "${sample}.deepvariant.vcf.gz"

    script:
    """
    run_deepvariant \
        --model_type=PACBIO \
        --ref=${params.ref} \
        --reads=${bam} \
        --output_vcf=${sample}.deepvariant.vcf.gz \
        --num_shards=${task.cpus}
    """
}

process CLAIR3 {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    path "clair3_output/merge_output.vcf.gz"

    script:
    """
    
    """
}

process MERGE_SNV {
    tag "$sample"

    input:
    tuple val(sample), path(bam)
    input:
    tuple val(sample), path(bam)
    output:
    path "snv_merged/${sample}.merge_output.vcf.gz"
    script:
"""
bcftools concat \
  -a \
  ./${sample}.deepvariant.vcf.gz \
  clair3_output/merge_output.vcf.gz \
  -Oz \
  -o snv_merged/${sample}.merge_output.vcf.gz
"""
}

process SNIFFLES {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    path "${sample}.sniffles.vcf.gz"

    script:
    """
    sniffles \
        --input ${bam} \
        --vcf ${sample}.sniffles.vcf.gz \
        --threads ${task.cpus}
    """
}

process SVIM {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    path "svim/variants.vcf"

    script:
    """
    svim alignment svim ${bam} ${params.ref}
    """
}

process STRAGLR {

    tag "$sample"

    input:
    tuple val(sample), path(bam)

    output:
    path "${sample}.straglr"

    script:
    """
    trgt \
        --reads ${bam} \
        --reference ${params.ref} \
        --output-prefix ${sample}
        python straglr.py ${bam} \
            ${params.ref} ${sample}_straglr \
            --exclude centromeres_telomeres_regions.bed
    """
}

process PHASE {

    tag "$sample"

    input:
    tuple val(sample), path(bam)
    path vcf

    output:
    path "${sample}.phased.vcf.gz"

    script:
    """
    whatshap phase \
        --reference ${params.ref} \
        ${vcf} \
        ${bam} \
        -o ${sample}.phased.vcf.gz
    """
}

process HIFIASM {

    tag "$sample"

    input:
    path reads

    output:
    path "${reads.baseName}.asm.hap1.fa"
    path "${reads.baseName}.asm.hap2.fa"

    script:
    """
    hifiasm \
        -o ${reads.baseName} \
        -t ${task.cpus} \
        ${reads}
    """
}

process MERGE_SV {

    input:
    path sniffles_vcf
    path svim_vcf

    output:
    path "merged_sv.vcf"

    script:
    """
    truvari collapse \
        --in ${sniffles_vcf} \
        --in2 ${svim_vcf} \
        --output merged_sv.vcf
    """
}

workflow {

    aligned = ALIGN(reads)

    dv = DEEPVARIANT(aligned)
    clair = CLAIR3(aligned)
    merged_snv = MERGE_SNV(dv, clair)
    sniff = SNIFFLES(aligned)
    svim = SVIM(aligned)

    repeats = STRAGLR(aligned)

    phase = PHASE(aligned, merged_snv)

    // asm = HIFIASM(reads)

    merged_sv = MERGE_SV(sniff, svim)

}