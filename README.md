# RStudio Server on FHIL HPC

This directory contains scripts and configuration for running RStudio Server instances on the FHIL HPC cluster using Apptainer containers.

## Prerequisites

1. **Apptainer Image**: You need an RStudio Server Apptainer image (`.sif` file) placed in the `images/` directory
2. **Directory Structure**: Ensure the following directory structure exists:
   ```
   rstudio-server-launcher/
   ├── images/
   │   └── rstudio_server.sif
   └── users/
       └── $USER/
           └── rstudio_config/
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
1. Close all RStudio sessions and stop R processes
2. Cancel the SLURM job:
   ```bash
   scancel -f $SLURM_JOB_ID
   ```

## Configuration

The script automatically:
- Allocates 8 CPUs and 32GB RAM (configurable in SLURM directives)
- Sets a 5-day time limit
- Creates a temporary working directory
- Generates a random port using `fhfreeport`
- Mounts necessary directories (`/home`, `/fh`)
- Configures RStudio Server for remote access

## Customization

### Resource Allocation
Modify the SLURM directives at the top of `launch_rstudio_server.sh`:
```bash
#SBATCH --cpus-per-task=4    # Increase CPU cores
#SBATCH --mem-per-cpu=8G     # Increase memory per CPU
#SBATCH --time=7-00:00:00    # Increase time limit
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
- Edit `build_image.def` and uncomment needed system libraries
- Rebuild the image when system dependencies change

### Image Path
Update `FILE_BASE` and `IMAGE_NAME` variables to point to your specific RStudio Server image.

## Building Custom Images

### Customize an Image

You can directly [edit the Apptainer `.def`](https://apptainer.org/docs/user/1.0/build_a_container.html#building-containers-from-apptainer-definition-files) file to add dependencies. Once the definition file is updated, build the `.sif`. Try to use semantic versioning to record versions.

```bash
apptainer build rstudio_FHIL.X.Y.Z.sif rstudio_FHIL.X.Y.Z.def
```

### Converting Dockerfile to Definition File

If Apptainer definition file syntax is challenging, you can write a Dockerfile and convert it with [Singularity Python](https://singularityhub.github.io/singularity-cli/recipes).

```bash
ml fhPython
spython recipe ./rstudio_FHIL.4.4.3.dockerfile > rstudio_FHIL.4.4.3.def
```

## Dependencies

- SLURM job scheduler
- Apptainer/Singularity
- `fhfreeport` utility (FHIL-specific)
- RStudio Server Apptainer image 