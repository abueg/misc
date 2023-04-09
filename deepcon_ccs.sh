#!/bin/bash
echo Script for deepconsensus v0.3
if [[ -z $1 ]] || [[ -z $2 ]]; then
    echo "Usage: ./deepcon.sh <subreads file> <chunk number> <chunk end> <# of ccs CPUs>"
    echo -e "\t<chunk end>: base pairs downstream of the end coordinate in the BED file"
    echo -e "\t<subreads file>: subreads file"
    echo -e "\t<$ of ccs cpus>: suggest 4"
    exit -1
fi

export SUBREADS_FILE=$1
export CHUNK_END=$2
export CCS_CPUS=$3

filename=$(basename -- "$SUBREADS_FILE")
extension="${SUBREADS_FILE##*.}"
filename="${SUBREADS_FILE%.*}"
FILE_ROOT=$(echo $filename | cut -d "." -f -1)

## setting up environment
/lustre/fs5/vgl/store/labueg/anaconda3/bin/conda init
source ~/.bashrc
conda activate deepconsensus_v0.3


echo [DEBUG] ccs started at `date`

ccs --min-rq=0.88 -j ${CCS_CPUS} --chunk=${SLURM_ARRAY_TASK_ID}/${CHUNK_END} ${SUBREADS_FILE} ${FILE_ROOT}_${SLURM_ARRAY_TASK_ID}-of-${CHUNK_END}.ccs.bam

echo [DEBUG] ccs finished at `date`