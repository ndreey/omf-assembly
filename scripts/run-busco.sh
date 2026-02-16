#!/bin/bash

#SBATCH --job-name=busco
#SBATCH --output=slurm-logs/busco/slurm-%j-busco.out
#SBATCH --error=slurm-logs/busco/slurm-%j-busco.err
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal 
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16GB
#SBATCH --time=1:00:00


# Source .bashrc so mamba is added to PATH and then activate environment
source /home/gfr152/.bashrc
mamba activate busco

# Parse argument flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --fasta)        FASTA_F="$2"; shift ;;
        --lineage)      LINEAGE="$2"; shift ;;
        --outdir)       OUTDIR="$2"; shift ;;
        --prefix)       PREFIX="$2"; shift ;;
        -h|--help)
            echo "Usage: $0 --fasta FILE --lineage DATASET --outdir DIR --prefix STRING"
            exit 0 ;;
        *) echo "[ERROR] Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required arguments
if [[ -z $FASTA_F || -z $LINEAGE || -z $OUTDIR || -z $PREFIX ]]; then
    echo "[ERROR] Missing required arguments."
    echo "Usage: $0 --fasta FILE --lineage DATASET --outdir DIR --prefix STRING"
    exit 1
fi

# Check if required files actually exist
if [ ! -s "$FASTA_F" ]; then
    echo "[ERROR] FASTA file not found or empty: $FASTA_F"
    exit 1
fi

echo "$(date) [START]       Starting run-busco.sh script"

# Remove trailing slash from --outdir, if present
OUTDIR="${OUTDIR%/}"

# Run BUSCO
busco \
    --in $FASTA_F \
    --lineage_dataset $LINEAGE \
    --mode genome \
    --out $PREFIX \
    --metaeuk \
    --out_path $OUTDIR \
    --cpu 8


echo "$(date) [FINISH]       run-busco.sh Finished"
