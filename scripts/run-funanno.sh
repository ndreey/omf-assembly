#!/bin/bash

#SBATCH --job-name=funannotate
#SBATCH --output=slurm-logs/funannotate/slurm-%j.out
#SBATCH --error=slurm-logs/funannotate/slurm-%j.err
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal 
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=15
#SBATCH --mem=64gb
#SBATCH --time=23:59:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=andre.bourbonnais@sund.ku.dk


# Source .bashrc so mamba is added to PATH and then activate environment
source /home/gfr152/.bashrc
mamba activate funanno

# Load in signalp
ml load signalp/6h

# Export paths
export GENEMARK_PATH=/projects/conshologen/people/gfr152/bin/gmes_linux_64_4
export PATH=$GENEMARK_PATH:$PATH
export FUNANNOTATE_DB=/maps/projects/conshologen/people/gfr152/db/funannotate_db
export PATH=$FUNANNOTATE_DB:$PATH

# Define memory and CPU settings
CPU=15

# Define directories and input files
ASM=$1
#ASM=08-comp-assemblies/tula/tula.001.fasta
#ASM=08-comp-assemblies/cerat/cerat1.001.fasta
#ASM=08-comp-assemblies/cerat/cerat2.001.fasta

PREFIX=$2
#PREFIX=tula
#PREFIX=cerat1
#PREFIX=cerat2

SPECIES=$3
#SPECIES=Tulasnella
#SPECIES=Ceratobasidium



OUTDIR=13-funanno

mkdir -p $OUTDIR/$PREFIX

SORTED=$OUTDIR/$PREFIX/$PREFIX.sorted.fasta
MASKED=$OUTDIR/$PREFIX/$PREFIX.masked.fasta

# Sort and rename
funannotate sort \
    --input $ASM \
    --out $SORTED \
    --base $PREFIX \
    --minlen 1500


# Repeat Masking the assemblies
funannotate mask \
    --input $SORTED \
    --out $MASKED \
    --cpus $CPU 

# Gene Prediction
funannotate predict \
    --input $MASKED \
    --out $OUTDIR/$PREFIX \
    --species $SPECIES \
    --ploidy 2 \
    --cpus $CPU \
    --busco_seed_species coprinus
#
## Running InterProScan
##funannotate iprscan \
##    --input $OUTDIR/$PREFIX \
##    --method local \
##    --cpus $CPU 
#
##funannotate remote \
##    --input $OUTDIR/$PREFIX \
##    --methods antismash \
##    --email andbou95@gmail.com \
##    --out $OUTDIR/$PREFIX 

## Functional annotation
funannotate annotate \
    --input $OUTDIR/$PREFIX \
    --cpus $CPU







