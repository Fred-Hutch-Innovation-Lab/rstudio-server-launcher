# RStudio Server on FHIL HPC

This directory contains scripts and configuration for running RStudio Server instances on the FHIL HPC cluster using Apptainer containers. This repository automatically publishes SIF files to GitHub Container Registry on tagged releases:

`oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:latest` 

## Quick Start

```bash
sbatch launch_rstudio_server.sh
```

The script will automatically pull the container image from this repo, set up the resource and port allocation, launch RStudio Server with sensible defaults, and show you the connection URL, username, and password in the SLURM stdout file (created in the directory you launch the script from).

When you're done, exit the RStudio Session ("power" button in the top right corner of the RStudio window) and Cancel the SLURM job
```bash
scancel -f ${SLURM_JOB_ID}
```

## Advanced Usage

### Container Image Options

**Option 1: Use Cloud Image (Default - Recommended)**
```bash
# Uses the latest image from GitHub Container Registry
export IMAGE_PATH="oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:0.0.3"
```

**Option 2: Use Local SIF File**
```bash
# Use a local SIF file in the images directory
export IMAGE_PATH="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/images/rstudio-server-FHIL.sif"
```

### Resource Allocation

Modify the SLURM directives at the top of `launch_rstudio_server.sh`:
```bash
#SBATCH --cpus-per-task=4    # Increase CPU cores
#SBATCH --mem-per-cpu=8G     # Increase memory per CPU
#SBATCH --time=7-00:00:00    # Increase time limit
```

### User Configuration Files
Place custom R configuration files in the `users/$USER/` directory:
- `.Rprofile` for R startup configuration
- `.Renviron` for R environment variables

### Package Management
The image is designed to be minimal and lightweight. Package management is handled by the user within the environment. Use `renv` for reproducible R environments:

```r
install.packages("renv")
renv::init()
renv::install(c("tidyverse", "ggplot2"))
```

### Building Custom Images
Edit `rstudio-server-FHIL.def` to add system dependencies, then either:
- Build manually: `apptainer build rstudio-server-FHIL.sif rstudio-server-FHIL.def`
- Or create a tagged release to trigger automatic GitHub build and publishing

You can directly [edit the Apptainer `.def`](https://apptainer.org/docs/user/1.0/build_a_container.html#building-containers-from-apptainer-definition-files) file to add dependencies. Once the definition file is updated, build the `.sif`. Try to use semantic versioning to record versions.

```bash
apptainer build rstudio-server-FHIL.sif rstudio-server-FHIL.def
```

#### Converting Dockerfile to Definition File

If Apptainer definition file syntax is challenging, you can write a Dockerfile and convert it with [Singularity Python](https://singularityhub.github.io/singularity-cli/recipes).

```bash
ml fhPython
spython recipe ./rstudio-server-FHIL.dockerfile > rstudio-server-FHIL.def
```
