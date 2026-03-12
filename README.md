# Run mapping and variant calling using using either GATK or Deepvariant
## run using bwa and gatk
```
sbatch --array=1-$N  submit_jobs.sh samples_to_process.tsv bwa gatk
```
## run using minimap and deepvariant
```
sbatch --array=1-$N  submit_jobs.sh samples_to_process.tsv minimap deepvariant
```