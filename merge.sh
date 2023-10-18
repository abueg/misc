#!/bin/bash
#SBATCH --cpus-per-task=8
#SBATCH --partition=vgl
#SBATCH --exclude=node[143-159]

sample=$1
cell=$2

cd /lustre/fs5/vgl/scratch/labueg/genomeark_uploading/hprc/generating_reads_bams/${sample}/${cell}
samtools merge -@8 $cell.ccs.bam $cell.*.ccs.bam
mkdir slurm_logs
mv slurm*.out slurm_logs
rm $cell.*.ccs.bam
