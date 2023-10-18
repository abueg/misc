#!/bin/bash
#SBATCH --cpus-per-task=8
#SBATCH --array=1-100
#SBATCH --partition=vgl
#SBATCH --exclude=node[143-159]

inputSUBREADS=$1
cell=$2

conda activate pacbiosuite

ccs ${inputSUBREADS} ${cell}.${SLURM_ARRAY_TASK_ID}.ccs.bam --log-level INFO --chunk ${SLURM_ARRAY_TASK_ID}/100 --all --all-kinetics --subread-fallback --minLength 10 --maxLength 50000 --minPasses 0 --minSnr 2.5 --minPredictedAccuracy 0.0 --alarms alarms.json --task-report task-report.json --report-json ccs_processing.report.json --zmw-metrics-json ccs_zmws.json.gz -j 8
