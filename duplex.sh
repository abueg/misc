#!/bin/sh
### set things up first
### the nodes with gpu are hpc_a10,hpc_a100,hpc_k80,hpc_v100
. $SCRATCH/venvs/duplex_tools_venv_v0.3.2/bin/activate
export DORADO=$STORE/programs/dorado-0.2.1-linux-x64/bin/dorado
export RDEVAL=/vggpfs/fs3/vgl/store/nbrajuka/rdeval/build/bin/rdeval
export MODELSDIR=/lustre/fs5/vgl/scratch/labueg/ONT_things/DORADO_MODELS
export SAMTOOLS=$STORE/programs/samtools-1.13/bin/samtools

runname=$1
threads=$2
export newthreads=$(($threads-2))

set -euxo pipefail

## convert fast5s in directory to one pod5
#export POD5_DEBUG=1
#srun -c 32 -p vglbfx pod5 convert from_fast5 -t 32 $fast5spath pod5directory

## dorado simplex basecalling
echo "DEBUG: STARTING DORADO SIMPLEX BASECALLING FROM POD5 DIRECTORY"
$DORADO basecaller $MODELSDIR/dna_r10.4.1_e8.2_400bps_fast@v4.0.0 pod5directory --emit-moves | samtools view -@ $newthreads -Shb > ${runname}.unmapped_reads_w_moves.bam
#$SAMTOOLS index ${runname}.unmapped_reads_w_moves.bam

## working on main pairs ##

### finding duplex reads
echo "DEBUG: FINDING DUPLEX READS"
duplex_tools pair --output_dir ${runname}.pairs_from_bam ${runname}.unmapped_reads_w_moves.bam

### basecalling main reads
echo "DEBUG: DUPLEX BASECALLING ON MAIN DUPLEX READS"
echo "\
$DORADO duplex --pairs ${runname}.pairs_from_bam/pair_ids_filtered.txt --emit-fastq --threads $newthreads $MODELSDIR/dna_r10.4.1_e8.2_400bps_sup@v4.0.0 pod5directory > ${runname}.duplex_orig.sam"
$DORADO duplex --pairs ${runname}.pairs_from_bam/pair_ids_filtered.txt --emit-fastq --threads $newthreads $MODELSDIR/dna_r10.4.1_e8.2_400bps_sup@v4.0.0 pod5directory > ${runname}.duplex_orig.sam

### stats for main reads
echo "DEBUG: SAM to FASTQ and stats for main duplex reads"
$SAMTOOLS view -b ${runname}.duplex_orig.sam | $SAMTOOLS fastq - -@ $newthreads | gzip - -c > ${runname}.duplex_orig.fastq.gz
$RDEVAL ${runname}.duplex_orig.fastq.gz

## working on additional pairs ##

### finding them in non-split reads
echo "FINDING SPLIT PAIRS"
duplex_tools split_pairs ${runname}.unmapped_reads_w_moves.bam pod5directory pod5directorys_splitduplex/
cat pod5directorys_splitduplex/*_pair_ids.txt > ${runname}.split_duplex_pair_ids.txt

### basecalling additional reads
echo "DUPLEX BASECALLING ON SPLIT PAIRS"
$DORADO duplex --pairs ${runname}.split_duplex_pair_ids.txt --emit-fastq --threads $newthreads $MODELSDIR/dna_r10.4.1_e8.2_400bps_sup@v4.0.0 pod5directorys_splitduplex/ > ${runname}.duplex_splitduplex.sam

### stats for additional reads
echo "DEBUG: BAM to FASTQ and stats for additional reads"
$SAMTOOLS view -b ${runname}.duplex_splitduplex.sam | $SAMTOOLS fastq - -@ $newthreads | gzip - -c > ${runname}.duplex_splitduplex.fastq.gz
$RDEVAL ${runname}.duplex_splitduplex.fastq.gz

## stats for all
echo "DEBUG: stats for all duplex"
cat ${runname}.duplex_orig.fastq.gz ${runname}.duplex_splitduplex.fastq.gz > ${runname}.duplex_all.fastq.gz
$RDEVAL ${runname}.duplex_all.fastq.gz


