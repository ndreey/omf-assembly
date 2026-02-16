#!/bin/bash

# Script to estimate genome size using FastK, GenomeScope2, and Smudgeplot

# Set variables
PREFIX=$1
MEM=36
CPU=12
KMER=21
PLOIDY=2

# Define temporary and output directories
TMP_FASTK=tmp/fastk_tmp/$PREFIX
TMP_SMUDGE=tmp/smudge/$PREFIX
KMER_DB=kmer_db/$PREFIX
KMER_TABLE=$KMER_DB/$PREFIX
KMER_HIST=${KMER_DB}_k$KMER.hist
GSCOPE=genomescope/$PREFIX
GSCOPE_OUT=$GSCOPE/${PREFIX}_$PLOIDY
SMUDGE=smudgeplot/$PREFIX
SMUDGE_OUT=$SMUDGE/$PREFIX

# Create necessary directories
echo "Creating directories..."
mkdir -p $TMP_FASTK $TMP_SMUDGE $KMER_DB $GSCOPE $SMUDGE

# Run FastK if kmer table doesn't exist
if [ ! -f "${KMER_TABLE}.ktab" ]; then
    echo "Running FastK to build kmer table..."
    FastK -v -t1 -k$KMER -M$MEM -T$CPU -N$KMER_TABLE -P$TMP_FASTK trim_fastq/$PREFIX*
    echo "FastK completed."
fi

# Create histogram for GenomeScope2 if it doesn't exist
if [ ! -f "$KMER_HIST" ]; then
    echo "Creating histogram for GenomeScope2..."
    Histex -G $KMER_TABLE > $KMER_HIST
    echo "Histogram created."
fi

# Run GenomeScope2
echo "Running GenomeScope2..."
genomescope2 -i $KMER_HIST -k $KMER -p $PLOIDY -o $GSCOPE_OUT -n $PREFIX
echo "GenomeScope2 completed."

# Run Smudgeplot if smu file doesn't exist
ERR_THRESH=20
if [ ! -f ${SMUDGE_OUT}.smu ]; then
    echo "Running Smudgeplot..."
    smudgeplot hetmers -L $ERR_THRESH -t $CPU -o $SMUDGE_OUT -tmp $TMP_SMUDGE --verbose $KMER_TABLE
    smudgeplot all -o $SMUDGE_OUT ${SMUDGE_OUT}.smu
    echo "Smudgeplot completed."
fi

echo "Genome estimation script finished."
