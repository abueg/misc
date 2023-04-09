#!/bin/bash
echo Script for deepconsensus v0.3
if [[ -z $1 ]] || [[ -z $2 ]]; then
    echo "Usage: ./deepcon.sh <subreads file> <chunk end> <# of ccs CPUs> <# of actc CPUs>"
    echo -e "\t<chunk end>: base pairs downstream of the end coordinate in the BED file"
    echo -e "\t<subreads file>: subreads file"
    echo -e "\t<$ of ccs cpus>: suggest 4"
    echo -e "\t<$ of actc cpus>: suggest 8"
    echo -e "\texample: ./deepcon.sh 1 50 sample.subreads.bam 4 8"
    exit -1
fi

export SUBREADS_FILE=$1
export CHUNK_END=$2
export CCS_CPUS=$3
export ACTC_CPUS=$4

filename=$(basename -- "$SUBREADS_FILE")
extension="${SUBREADS_FILE##*.}"
filename="${SUBREADS_FILE%.*}"
FILE_ROOT=$(echo $filename | cut -d "." -f -1)

## run ccs and actc with parameters specified in deepconsensus quickstart
echo [DEBUG] running pacbio ccs with ${CCS_CPUS} CPUs and actc with ${ACTC_CPUS} CPUs across ${CHUNK_END} chunks on ${FILE_ROOT} aka ${SUBREADS_FILE}
echo "sbatch --parsable --partition=vgl --nodes=1 --array=1-${CHUNK_END} --cpus-per-task=$CCS_CPUS ~/_scripts/deepcon_ccs.sh $SUBREADS_FILE $CHUNK_END $CCS_CPUS"
CCS_JID=$(sbatch --parsable --partition=vgl --nodes=1 --array=1-${CHUNK_END} --cpus-per-task=$CCS_CPUS ~/_scripts/deepcon_ccs.sh $SUBREADS_FILE $CHUNK_END $CCS_CPUS)

# for i in $( seq 1 ${CHUNK_END} )
# do
#     sbatch --partition=vgl --nodes=1 --cpus-per-task=$CCS_CPUS ~/_scripts/deepcon_ccs.sh $SUBREADS_FILE $i $CHUNK_END $CCS_CPUS ;
# done

echo "sbatch --parsable --partition=vgl --nodes=1 --array=1-${CHUNK_END} --cpus-per-task=$ACTC_CPUS --dependency=aftercorr:${CCS_JID} ~/_scripts/deepcon_actc.sh $SUBREADS_FILE $CHUNK_END $ACTC_CPUS"
ACTC_JID=$(sbatch --parsable --partition=vgl --nodes=1 --array=1-${CHUNK_END} --cpus-per-task=$ACTC_CPUS --dependency=aftercorr:${CCS_JID} ~/_scripts/deepcon_actc.sh $SUBREADS_FILE $CHUNK_END $ACTC_CPUS)

# for i in $( seq 1 ${CHUNK_END} )
# do
#     sbatch --partition=vgl --nodes=1 --cpus-per-task=$ACTC_CPUS ~/_scripts/deepcon_actc.sh $SUBREADS_FILE $i $CHUNK_END $ACTC_CPUS ;
# done


## run deepconsensus


echo "sbatch --parsable --partition=vgl --exclude=node[141-160] --array=1-${CHUNK_END} --nodes=1 --cpus-per-task=32 --dependency=aftercorr:${ACTC_JID} ~/_scripts/deepcon_deepcon.sh $SUBREADS_FILE $CHUNK_END"
DEEPCON_JID=$(sbatch --parsable --partition=vgl --exclude=node[141-160] --array=1-${CHUNK_END} --nodes=1 --cpus-per-task=32 --dependency=aftercorr:${ACTC_JID} ~/_scripts/deepcon_deepcon.sh $SUBREADS_FILE $CHUNK_END)

# for i in $( seq 1 ${CHUNK_END} )
# do
#     sbatch --exclude=node[141-159] --nodes=1 --cpus-per-task=16 ~/_scripts/deepcon_deepcon.sh $SUBREADS_FILE $i $CHUNK_END ;
# done


## cat all fastqs from deepcon to one fastq, and then zip

echo "sbatch --partition=vgl --dependency=afterok:${DEEPCON_JID} ~/_scripts/deepcon_merge.sh ${SUBREADS_FILE} ${CHUNK_END} "
sbatch --partition=vgl --dependency=afterok:${DEEPCON_JID} ~/_scripts/deepcon_merge.sh ${SUBREADS_FILE} ${CHUNK_END} 

# for i in $( seq 1 ${CHUNK_END} )
# do
#     cat ${FILE_ROOT}_${i}-of-${CHUNK_END}.output.fastq >> ${FILE_ROOT}_deepconsensus.output.fastq ;
# done

