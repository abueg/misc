#!/bin/sh
### set things up first
### the nodes with gpu are hpc_a10,hpc_a100,hpc_k80,hpc_v100
. $SCRATCH/venvs/duplex_tools_venv_v0.3.2/bin/activate
export DORADO=$STORE/programs/dorado-0.2.1-linux-x64/bin/dorado
export RDEVAL=/vggpfs/fs3/vgl/store/nbrajuka/rdeval/build/bin/rdeval
export MODELSDIR=/lustre/fs5/vgl/scratch/labueg/ONT_things/DORADO_MODELS
export SAMTOOLS=$STORE/programs/samtools-1.13/bin/samtools

runname=$1
fast5spath=$2
gpupartition=$3
gputhreads=$4

POD5_JID=$(sbatch --parsable --partition=vgl --nodes=1 --cpus-per-task=32 ~/_scripts/fast5topod5.sh $fast5spath $runname)

sbatch --partition=$gpupartition --cpus-per-task=$gputhreads --dependency=afterok:${POD5_JID} ~/_scripts/duplex.sh $runname $gputhreads 


