# Question 1:

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
```
nextflow run main.nf --aligner bwa --caller gatk
nextflow run main.nf --aligner minimap2 --caller deepvariant
```
![plot](./flowchart_gatk.png)
![plot](./flowchart_deep.png)


## Annotate VCF
```
vep \
    --input_file cohort.vcf.gz \
    --output_file cohort.annotated.vcf.gz \
    --vcf \
    --compress_output bgzip \
    --offline \
    --cache \
    --assembly GRCh38 \
    --dir_cache ~/.vep \
    --fasta reference.fa \
    --plugin CADD,annotations/CADD_GRCh38.tsv.gz \
    --plugin AlphaMissense,annotations/AlphaMissense_GRCh38.tsv.gz,cols=all
    --plugin SpliceAI,snv=annotations/spliceai_scores.masked.snv.hg38.vcf.gz \
    --custom annotations/clinvar.vcf.gz,ClinVar,vcf,exact,0,CLNSIG,CLNDN \
    --custom annotations/gnomad.genomes.v3.1.sites.vcf.gz,gnomADg,vcf,exact,0,AF,AF_popmax \
    --fields "Uploaded_variation,Location,Allele,Gene,Feature,Consequence,Protein_position,Amino_acids,CADD-raw,am_pathogenicity,am_class,SpliceAI_pred_DS_AG,SpliceAI_pred_DS_AL"
  ```

## Variant interpretation
### ACMG classifiction
Many ACMG classifiction APIs seem to exist (e.g. Alphamissense) to perform an intitial assignment of `Pathogenic`,`Very likely pathogenic`,`...`,`VUS` to variants and possibly prioritise cases.

### Potentially could try RAMEDIES to cluster patients by HPO terms
from: https://www.nature.com/articles/s41467-025-61712-2
See below exemplary script for computing semantic difference between HPO lists of 2 patients:
https://bitbucket.org/bejerano/phrank/src/master/demo/demo_phrank.py
Subsequently- could use what ever means to assign genes to each patient (e.g. AF<0.001 or CADD>10) and then perform per-cluster enrichment analysis to nominate variants.

### Alpha genome could help contextualise variant effect at unprecedented level:
The API is queryable: https://deepmind.google.com/science/alphagenome/api

# Complex variation structural variation and repeat expansions
## Structural variation
Minimap2 + Manta seems to outperform all other SV calling methods:
```
./SV_caller.sh sample1 sample1_R1.fastq.gz sample1_R2.fastq.gz
```
## Denovo repeat expansion discovery
While flawed due to the limitations of srWGS- ExpansionHunter denovo can be a powerfull tool to identify deviations in STR motif constitution from reference genome. (Exemplary code only on GEL platform right now. Can be shown if asked.)

Furthermore repeat crawler (https://github.com/chrisclarkson/gel/blob/main/RC_latest.py) can help to assign structure to alleles for subsequent instability analysis.

![plot](./shank2_structure.png)
For methods/details of structure imputation of expanded repeats- see bottom of https://github.com/chrisclarkson/gel/blob/main/README.md

# Question 2:

## Long read
Makes it possible to phase distal variants but also ascertain much more complex variation:
```
nextflow run long_read.nf -with-dag long_read.png
```
![plot](./long_read.png)
Furthermore, simply studying segregation of SVs and repeat expansions across family trios could also highlight significant variation.

## Storing LR data
Storage solutions of these data will be vital- at a first glance it might be necessary to only keep reference genome, pipelines to generate results and the results files to enable rerunning revised strategy is needed- also see: 
  - https://www.biostars.org/p/384118/
  - https://aws.amazon.com/blogs/industries/store-omics-data-cost-effectively-at-any-scale-with-aws-healthomics/
## RNA Seq
Very informative pipeline for handling expression values and outliers:
https://github.com/lfresard/blood_rnaseq_rare_disease_paper/blob/master/pipeline.md

### More generic DROP pipeline:
#### Initially map RNA seq reads
```
./DROP.sh sample1 sample_rna1.fastq.gz sample_rna2.fastq.gz reference.fa
```