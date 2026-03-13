# Run mapping and variant calling using using either GATK or Deepvariant
## run using bwa and gatk
```
sbatch --array=1-$N  map_and_call_variants_submit_jobs.sh samples_to_process.tsv bwa gatk
```
## run using minimap and deepvariant
```
sbatch --array=1-$N  map_and_call_variants_submit_jobs.sh samples_to_process.tsv minimap deepvariant
```

## check jobs ran and produced expected outputs
```
check_job_output.py --prefix ./ --cols 0 --suffix .g.vcf.gz samples_to_process.tsv
cat unfinished_jobs.txt # check log files of any jobs that didn't finish
```

## Nextflow optionality
nextflow run main.nf --aligner minimap2 --caller deepvariant

## Concatenate GVCF outputs
To be done...


## Annotate VCF
vep \
  --input_file cohort.vcf.gz \
  --output_file cohort.annotated.vcf.gz \
  --vcf \
  --compress_output bgzip \
  --fork 16 \
  --offline \
  --cache \
  --assembly GRCh38 \
  --dir_cache ~/.vep \
  --fasta Homo_sapiens.GRCh38.dna.primary_assembly.fa \
  --everything \
  \
  --plugin CADD,annotations/CADD_GRCh38.tsv.gz \
  --plugin REVEL,annotations/revel_grch38.tsv.gz \
  --plugin SpliceAI,snv=annotations/spliceai_scores.masked.snv.hg38.vcf.gz \
  \
  --custom annotations/clinvar.vcf.gz,ClinVar,vcf,exact,0,CLNSIG,CLNDN \
  --custom annotations/gnomad.genomes.v3.1.sites.vcf.gz,gnomADg,vcf,exact,0,AF,AF_popmax \
  \
  --fields "Uploaded_variation,Location,Allele,Gene,Feature,Consequence,Protein_position,Amino_acids,CADD_PHRED,REVEL,SpliceAI_pred_DS_AG,SpliceAI_pred_DS_AL"