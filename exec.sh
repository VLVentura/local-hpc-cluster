#!/bin/bash

#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1

cd $SLURM_SUBMIT_DIR

mpirun knn -k 5 -d resources/avila_dataset -v
