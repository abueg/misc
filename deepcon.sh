#!/bin/bash
echo Script for deepconsensus v0.3
if [[ -z $1 ]] || [[ -z $2 ]]; then
    echo "Usage: ./deepcon.sh <chunk start> <chunk end> <subreads file> <# of ccs CPUs> <# of actc CPUs>"
    echo -e "\t<chunk start>: base pairs upstream of the start coordinate in the BED file"
    echo -e "\t<chunk end>: base pairs downstream of the end coordinate in the BED file"
    echo -e "\t<subreads file>: subreads file"
    echo -e "\t<$ of ccs cpus>: suggest 4"
    echo -e "\t<$ of actc cpus>: suggest 8"
    echo -e "\texample: ./deepcon.sh 1 50 sample.subreads.bam 4 8"
    exit -1
fi

export SUBREADS_FILE=$1
export CHUNK_START=$2
export CHUNK_END=$3
export CCS_CPUS=$4
export ACTC_CPUS=$5

filename=$(basename -- "$SUBREADS_FILE")
extension="${SUBREADS_FILE##*.}"
filename="${SUBREADS_FILE%.*}"
FILE_ROOT=$(echo $filename | cut -d "." -f -1)

## setting up environment
/lustre/fs5/vgl/store/labueg/anaconda3/bin/conda init
source ~/.bashrc
source /lustre/fs5/vgl/scratch/labueg/venvs/deepconsensus_v0.3_venv_1/bin/activate
conda activate deepconsensus_v0.3

## run ccs and actc with parameters specified in deepconsensus quickstart
echo [DEBUG] running pacbio ccs with ${CCS_CPUS} CPUs and actc with ${ACTC_CPUS} CPUs across ${CHUNK_END} chunks on ${FILE_ROOT} aka ${SUBREADS_FILE}
echo [DEBUG] ccs and actc started at `date`

for i in $( seq 1 ${CHUNK_END} )
do
    sbatch --partition=vgl --nodes=1 --cpus-per-task=$CCS_CPUS --export=CHUNK_END --export=SUBREADS_FILE --export=CCS_CPUS --wrap='conda activate deepconsensus_v0.3 ; ccs --min-rq=0.88 -j ${CCS_CPUS} --chunk=${i}/${CHUNK_END} ${SUBREADS_FILE} ${FILE_ROOT}_${i}_of_${CHUNK_END}.ccs.bam' ;
   sbatch --partition=vgl --nodes=1 --cpus-per-task=$ACTC_CPUS --wrap='' ;
done

echo [DEBUG] ccs and actc finished at `date`

## run deepconsensus
echo [DEBUG] running deepconsensus on ${CHUNK_END} chunks
echo [DEBUG] deepconsensus starting at `date`
for i in $(eval echo "{$CHUNK_START}..{$CHUNK_END}")
do
    sbatch --exclude=node[141-159] --nodes=1 --cpus-per-task=16 --wrap="deepconsensus run --subreads_to_ccs=${FILE_ROOT}_${i}-of-${CHUNK_END}.subreads_to_ccs.bam --ccs_bam=${FILE_ROOT}_${i}-of-${CHUNK_END}.ccs.bam --checkpoint=./model/checkpoint --output=${FILE_ROOT}_${i}-of-${END}.output.fastq"
done
echo [DEBUG] deepconsensus ending at `date`

## cat all fastqs from deepcon to one fastq, and then zip
echo [DEBUG] combining ${CHUNK_END} fastqs
echo [DEBUG] starting at `date`
echo [DEBUG] this is job $SLURM_JOB_ID
for i in $(eval echo "{$CHUNK_START..$CHUNK_END}")
do
    cat ${FILE_ROOT}_${i}-of-${CHUNK_END}.output.fastq >> ${FILE_ROOT}_deepconsensus.output.fastq ;
done
gzip ${FILE_ROOT}_deepconsensus.output.fastq