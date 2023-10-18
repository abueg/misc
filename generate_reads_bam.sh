#!/bin/bash
#SBATCH --job-name=asdf
#SBATCH --cpus-per-task=8
#SBATCH --array=1-13
#SBATCH --partition=vgl
#SBATCH --exclude=node[143-159]

export SCRIPTPATH=/lustre/fs5/vgl/scratch/labueg/genomeark_uploading/hprc/generating_reads_bams

conda activate pacbiosuite

# config file
config=/lustre/fs5/vgl/scratch/labueg/genomeark_uploading/hprc/generating_reads_bams/reads_generating.ls

# parse config file
sample=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)
barcode=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $config)
CCSpath=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $4}' $config)
DEMUXpath=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $5}' $config)

# get cell ID from CCS outputs
cell=$(ls ${CCSpath}/outputs/*.fastq.gz | cut -d "/" -f 14 | cut -d "." -f 1)

# get input XML from CCS BAM header
inputXML=$(samtools view -H ${CCSpath}/outputs/${cell}.hifi_reads.bam | grep "ID:ccs" | cut -f 6 | grep -o ".*\.xml" | cut -d " " -f 2)
inputSUBREADS=$(grep "subreads bam" ${inputXML} | sed 's/.*ResourceId="\(.*\)" Version.*/\1/')

mkdir -p /lustre/fs5/vgl/scratch/labueg/genomeark_uploading/hprc/generating_reads_bams/${sample}/${cell}
cd /lustre/fs5/vgl/scratch/labueg/genomeark_uploading/hprc/generating_reads_bams/${sample}/${cell}

CCS_JID=$(sbatch --parsable ${SCRIPTPATH}/ccs_subscript.sh ${inputSUBREADS} ${cell})
sbatch --dependency=afterok:${CCS_JID} ${SCRIPTPATH}/merge.sh ${sample} ${cell
