# RStudio Server on FHIL HPC

This directory contains scripts and configuration for running RStudio Server instances on the FHIL HPC cluster using Apptainer containers.

## Prerequisites

1. **Apptainer Image**: You need an RStudio Server Apptainer image (`.sif` file) placed in the `images/` directory, OR you can use cloud-hosted SIF files directly
2. **Directory Structure**: Ensure the following directory structure exists:
   ```
   rstudio-server-launcher/
   ├── images/
   │   └── rstudio-server-FHIL.sif  # Local image (optional)
   └── users/
       └── $USER/
           └── .Rprofile            # Custom R profile (optional)
           └── .Renviron            # Custom R environment (optional)
   ```
3. **Package Management**: The image uses minimal packages and is intended more for tracking system dependencies. R packages are managed with `renv`.

## Usage

### 1. Submit the SLURM Job

```bash
sbatch launch_rstudio_server.sh
```

### 2. Monitor the Job

Check the job status and output:
```bash
squeue -u $USER
tail -f /home/$USER/rstudio-server.job.$SLURM_JOB_ID.out
```

### 3. Access RStudio Server

Once the job is running, you'll see connection information in the stdout:
- URL: `http://<hostname>.fhcrc.org:<port>`
- Username: Your FHIL username
- Password: The generated password (if using password authentication)

### 4. Terminate the Job

When you're done:
1. Exit the RStudio Session ("power" button in the top right corner of the RStudio window)
2. Cancel the SLURM job:
   ```bash
   scancel -f ${SLURM_JOB_ID}
   ```

## Configuration

The script automatically:
- Allocates 2 CPUs and 8GB RAM (configurable in SLURM directives)
- Sets a 4-day time limit (configurable)
- Creates a temporary working directory
- Generates a random port using `fhfreeport`
- Mounts necessary directories (`/home`, `/fh`)
- Configures RStudio Server for remote access

## Container Image Options

### Option 1: Local SIF File (Recommended for Offline/Performance)
```bash
# Use a local SIF file in the images directory
export IMAGE_PATH="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/images/rstudio-server-FHIL.sif"
```

### Option 2: Cloud-Hosted SIF (Recommended for Latest Versions)
```bash
# Use the packaged cloud SIF from this repository
export IMAGE_PATH="oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:latest"
```

## Customization

### Resource Allocation
Modify the SLURM directives at the top of `launch_rstudio_server.sh`:
```bash
#SBATCH --cpus-per-task=4    # Increase CPU cores
#SBATCH --mem-per-cpu=8G     # Increase memory per CPU
#SBATCH --time=7-00:00:00    # Increase time limit
```

### Container Image Selection
Modify the `IMAGE_PATH` variable in `launch_rstudio_server.sh`:
```bash
# For local files
export IMAGE_PATH="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/images/rstudio-server-FHIL.sif"

# For cloud-hosted SIFs (recommended)
export IMAGE_PATH="oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:latest"
```

### Package Management

The image is designed to be minimal and lightweight. Package management is handled at runtime:

#### R Packages
- Use `renv` for reproducible R environments:
  ```r
  install.packages("renv")
  renv::init()
  renv::install(c("tidyverse", "ggplot2"))
  ```

#### System Libraries
- Edit `rstudio-server-FHIL.def` and uncomment needed system libraries
- Rebuild the image when system dependencies change

## Building Custom Images

### Customize an Image

You can directly [edit the Apptainer `.def`](https://apptainer.org/docs/user/1.0/build_a_container.html#building-containers-from-apptainer-definition-files) file to add dependencies. Once the definition file is updated, build the `.sif`. Try to use semantic versioning to record versions.

```bash
apptainer build rstudio-server-FHIL.sif rstudio-server-FHIL.def
```

### Converting Dockerfile to Definition File

If Apptainer definition file syntax is challenging, you can write a Dockerfile and convert it with [Singularity Python](https://singularityhub.github.io/singularity-cli/recipes).

```bash
ml fhPython
spython recipe ./rstudio-server-FHIL.dockerfile > rstudio-server-FHIL.def
```

## Cloud Container Registry

### GitHub Container Registry (GHCR)

This repository includes pre-built SIF files hosted on GHCR:

- **Latest**: `oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:latest`
- **Versioned**: `oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:0.0.3`

### Pulling Images Manually

If you want to download and store images locally:

```bash
# Pull the latest version
apptainer pull rstudio-server-FHIL.sif oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:latest

# Pull a specific version
apptainer pull rstudio-server-FHIL.sif oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:0.0.3
```

## Dependencies

- SLURM job scheduler
- Apptainer/Singularity
- `fhfreeport` utility (FHIL-specific)
- RStudio Server Apptainer image (local or cloud-hosted) 