#!/bin/bash

#SBATCH --job-name=AAFTF
#SBATCH --output=slurm-logs/AAFTF/slurm-%j-AAFTF.out
#SBATCH --error=slurm-logs/AAFTF/slurm-%j-AAFTF.err
#SBATCH --array=1-3
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal 
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=96gb
#SBATCH --time=23:59:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=andre.bourbonnais@sund.ku.dk


# Source .bashrc so mamba is added to PATH and then activate environment
source /home/gfr152/.bashrc
mamba activate aaftf

# Define memory and CPU settings
MEM=96
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}  # Get the task ID from the job array

# Define directories and input files
FASTQ=fastq                             # Path to fastq folder
SAMPLEFILE=doc/samples.csv                      # Path to samples.csv
ASM=$1
WORKDIR=$2
PHYLUM=Basidiomycota

# Create necessary directories
mkdir -p $ASM $WORKDIR


# Read the sample file, parsing values with "," as the delimiter
IFS=,
tail -n +2 $SAMPLEFILE | sed -n ${N}p | while read BASE ILLUMINASAMPLE SPECIES INTERNALID PROJECT
do
    ID=$INTERNALID

    # Define output file paths for each stage of processing
    ASMFILE=$ASM/${ID}.spades.fasta
    VECCLEAN=$ASM/${ID}.vecscreen.fasta
    PURGE=$ASM/${ID}.sourpurge.fasta
    CLEANDUP=$ASM/${ID}.rmdup.fasta
    PILON=$ASM/${ID}.pilon.fasta
    SORTED=$ASM/${ID}.sorted.fasta
    STATS=$ASM/${ID}.sorted.stats.txt

    # Define input FASTQ file paths
    LEFTIN=$FASTQ/${ILLUMINASAMPLE}_1.fastq.gz
    RIGHTIN=$FASTQ/${ILLUMINASAMPLE}_2.fastq.gz

    echo "Processing sample: $BASE"

    # Check if input files exist
    if [ ! -f $LEFTIN ]; then
        echo "Missing input file: $LEFTIN for sample $ID/$BASE"
        exit
    fi

    # Define intermediate output file paths
    LEFTTRIM=$WORKDIR/${BASE}_1P.fastq.gz
    RIGHTTRIM=$WORKDIR/${BASE}_2P.fastq.gz
    MERGETRIM=$WORKDIR/${BASE}_fastp_MG.fastq.gz
    LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
    RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz
    MERGED=$WORKDIR/${BASE}_filtered_U.fastq.gz

    # Perform read trimming and filtering if the filtered files don't exist
    if [ ! -f $LEFT ]; then
        if [ ! -f $LEFTTRIM ]; then
            # Step 1: Trim reads with fastp (deduplication, merging, and quality filtering)
            AAFTF trim --method fastp --dedup --merge --memory $MEM --left $LEFTIN --right $RIGHTIN -c $CPU -o $WORKDIR/${BASE}_fastp -ml 50
            
            # Step 2: Additional trimming to remove low-quality bases
            AAFTF trim --method fastp --cutright -c $CPU --memory $MEM --left $WORKDIR/${BASE}_fastp_1P.fastq.gz --right $WORKDIR/${BASE}_fastp_2P.fastq.gz -o $WORKDIR/${BASE}_fastp2 -ml 50
            
            # Step 3: Final trimming with bbduk
            AAFTF trim --method bbduk -c $CPU --memory $MEM --left $WORKDIR/${BASE}_fastp2_1P.fastq.gz --right $WORKDIR/${BASE}_fastp2_2P.fastq.gz -o $WORKDIR/${BASE} -ml 50
        fi
        
        # Step 4: Filter reads using bbduk
        AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${BASE} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk
        AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${BASE} --left $MERGETRIM --aligner bbduk

        # Verify that filtering produced output
        if [ -f $LEFT ]; then
            rm -f $LEFTTRIM $RIGHTTRIM $WORKDIR/${BASE}_fastp*
            echo "Filtered reads found: $LEFT"
        else
            echo "Filtering failed, no output reads generated"
            exit
        fi    
    fi

    # Assemble genome if assembly file does not exist
    if [ ! -f $ASMFILE ]; then
        AAFTF assemble -c $CPU --left $LEFT --right $RIGHT --merged $MERGED --memory $MEM \
              -o $ASMFILE -w $WORKDIR/spades_${ID}

        # Cleanup temporary files from SPAdes assembly
        if [ -s $ASMFILE ]; then
            rm -rf $WORKDIR/spades_${ID}/K?? $WORKDIR/spades_${ID}/tmp $WORKDIR/spades_${ID}/K???
        fi

        # If assembly failed, exit
        if [ ! -f $ASMFILE ]; then
            echo "SPADES assembly failed for $ID, exiting"
            exit
        fi
    fi
    
    # Step 6: Remove vector contamination
    if [ ! -f $VECCLEAN ]; then
        AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN
    fi

    # Step 7: Remove contaminant sequences using sourpurge
    if [ ! -f $PURGE ]; then
        AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT --right $RIGHT
    fi
    
    # Step 8: Remove duplicate sequences
    if [ ! -f $CLEANDUP ]; then
        AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 1000
    fi
    
    # Step 9: Error correction using Pilon
    if [ ! -f $PILON ]; then
        AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT --right $RIGHT --mem $MEM
    fi
    
    # Check if Pilon successfully created the file
    if [ ! -f $PILON ]; then
        echo "Pilon failed, no output file created. Exiting."
        exit
    fi
    
    # Step 10: Sort the final assembly
    if [ ! -f $SORTED ]; then
        AAFTF sort -i $PILON -o $SORTED
    fi
    
    # Step 11: Generate assembly statistics
    if [ ! -f $STATS ]; then
        AAFTF assess -i $SORTED -r $STATS
    fi
done