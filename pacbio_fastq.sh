#!/bin/bash
conda activate pacbiosuite

INPUTFILE=$1

export hifiExportPattern='.*/jobs_root/.*'
export subreadExportPattern='^.*.xml$'

get_hifi_stats () {
    echo "DEBUG: grabbing hifi yield for run $run of $vglid with metadataid $metadataid and SMRT link reported yield of $hifiyield"
    if test -f ./$vglid/$metadataid.hifi_reads.fastq.gz
    then
        $STORE/programs/BINARIES/seqkit stats ./$vglid/$metadataid.hifi_reads.fastq.gz
    else
        $STORE/programs/BINARIES/seqkit stats ./$vglid/$metadataid.$barcode--$barcode.hifi_reads.fastq.gz
    fi
}

while IFS="," read -r vglid latinname run metadataid multiplexyn barcode hifiyield subreadpath ccspath ; do
    echo "DEBUG: processing run $run for $vglid with metadata ID $metadataid (SMRTlink hifi yield: $hifiyield) at `date`"
    echo "DEBUG: $vglid cell $metadataid using ccspath: $ccspath"
    [ -d "$vglid" ] || mkdir "$vglid"
    if [[ $ccspath =~ $hifiExportPattern ]]
    then
        echo "DEBUG: the CCS path listed matches the 'jobs_root' pattern, i will look in the outputs for hifi fastq.gz"
        hifiExportPath=$ccspath/outputs/
        echo "DEBUG: first checking for demultiplexed fastq.gz"
        if test -n "$(find $hifiExportPath -maxdepth 1 -name 'demultiplex.*.fastq.gz' -print -quit)"
        then
            echo "DEBUG: found demultiplexed fastq.gz in outputs dir"
            ln -s $hifiExportPath/demultiplex.$barcode--$barcode.hifi_reads.fastq.gz ./$vglid/$metadataid.$barcode--$barcode.hifi_reads.fastq.gz
            get_hifi_stats
        elif test -n "$(find $hifiExportPath -maxdepth 1 -name '*.hifi_reads.fastq.gz' -print -quit)"
        then
            echo "DEBUG: no demux hifi_reads.fastq.gz is in folder, but found a normal hifi_reads.fastq.gz"
            ln -s $hifiExportPath/$metadataid.hifi_reads.fastq.gz ./$vglid/
            get_hifi_stats
        else
            echo "DEBUG: nothing found in outputs... lol"
        fi
    elif [[ $ccspath =~ $subreadExportPattern ]]
    then 
        echo "DEBUG: CCS path listed does not match 'jobs_root' pattern, it is instead pointing to subreads XML file"
        export hifiExportPath=$(echo $ccspath | cut -d '/' -f 1-9)
        echo "DEBUG: i will check for a barcoded subdir"
        if [ -d "$hifiExportPath/$barcode--$barcode" ] 
        then
            echo "DEBUG: i found a barcoded subdir, i will now run bam2fastq on the hifi_fastq there"
            hifiExportPath=$hifiExportPath/$barcode--$barcode
            cd ./$vglid/
            ln -s $hifiExportPath/$metadataid.hifi_reads.$barcode--$barcode.ba* .
            bam2fastq -o $metadataid.$barcode--$barcode.hifi_reads $metadataid.hifi_reads.$barcode--$barcode.bam
            cd ..
            get_hifi_stats
        elif test -n "$(find $hifiExportPath -maxdepth 1 -name '*.subreads.bam' -print -quit)"
        then
            echo "DEBUG: did not find a barcoded subdir, but i did find subreads in the directory"
            echo "DEBUG: running extracthifi then bam2fastq on the subreads BAM"
            cd ./$vglid/
            ln -s $hifiExportPath/$metadataid.subreads.ba* .
            extracthifi $metadataid.subreads.bam $metadataid.hifi_reads.bam
            pbindex $metadataid.hifi_reads.bam
            bam2fastq -o $metadataid.hifi_reads $metadataid.hifi_reads.bam
            cd ..
            get_hifi_stats
        elif test -n "$(find $hifiExportPath -maxdepth 1 -name '*.reads.bam' -print -quit)"
        then
            echo "DEBUG: did not find a barcoded subdir, but i did find reads in the directory"
            echo "DEBUG: running extracthifi then bam2fastq on the reads BAM"
            cd ./$vglid/
            ln -s $hifiExportPath/$metadataid.reads.ba* .
            extracthifi $metadataid.reads.bam $metadataid.hifi_reads.bam
            pbindex $metadataid.hifi_reads.bam
            bam2fastq -o $metadataid.hifi_reads $metadataid.hifi_reads.bam
            cd ..
            get_hifi_stats
        fi
    elif [[ $ccspath =~ '' ]]
    then
        echo "ccspath column is empty for $run of $vglid with metadataid $metadataid"
    else
        echo "CCS path exists but does not match 'jobs_root' or subreads XML patterns, ruh roh"
    fi
    
    echo -e "DEBUG: finished at `date` \n\n\n"
#    ln -s $SUBREADSPATH/*.subreads.ba* ./$vglid/
#    aws s3 cp --recursive --exclude "*" --include "$metadataid*" ./$vglid/ s3://genomeark/species/$latinname/$vglid/genomic_data/pacbio_hifi/
done < $INPUTFILE
