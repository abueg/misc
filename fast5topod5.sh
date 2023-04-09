#!/bin/sh
### set things up first
### the nodes with gpu are hpc_a10,hpc_a100,hpc_k80,hpc_v100
. $SCRATCH/venvs/duplex_tools_venv_v0.3.2/bin/activate
export DORADO=$STORE/programs/dorado-0.2.1-linux-x64/bin/dorado
export RDEVAL=/vggpfs/fs3/vgl/store/nbrajuka/rdeval/build/bin/rdeval
export MODELSDIR=/lustre/fs5/vgl/scratch/labueg/ONT_things/DORADO_MODELS
export SAMTOOLS=$STORE/programs/samtools-1.13/bin/samtools

fast5spath=$1
runname=$2

mkdir -p fast5hard
export POD5_DEBUG=1
cp $fast5spath/* fast5hard
pod5 convert from_fast5 -t 32 ./fast5hard ${runname}.pod5 
mkdir -p ./pod5directory
mv ${runname}.pod5 ./pod5directory


