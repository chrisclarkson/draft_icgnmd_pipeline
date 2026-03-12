# Run mapping and variant calling using using either GATK or Deepvariant
## run using bwa and gatk
sbatch submit_jobs.sh samples_to_process.tsv bwa gatk
## run using minimap and deepvariant
sbatch submit_jobs.sh samples_to_process.tsv bwa gatk
