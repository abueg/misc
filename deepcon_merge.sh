#!/bin/bash

export SUBREADS_FILE=$1
export CHUNK_END=$2

filename=$(basename -- "$SUBREADS_FILE")
extension="${SUBREADS_FILE##*.}"
filename="${SUBREADS_FILE%.*}"
FILE_ROOT=$(echo $filename | cut -d "." -f -1)

echo [DEBUG] combining ${CHUNK_END} fastqs
echo [DEBUG] starting at `date`
echo [DEBUG] this is job $SLURM_JOB_ID

for i in $( seq 1 ${CHUNK_END} )
do
    cat ${FILE_ROOT}_${i}-of-${CHUNK_END}.output.fastq >> ${FILE_ROOT}_deepconsensus.output.fastq ;
done
gzip ${FILE_ROOT}_deepconsensus.output.fastq
