#!/bin/bash
#SBATCH --job-name=apptainer-build
#SBATCH --time=02:00:00   # 1 hr
#SBATCH --ntasks=1          
#SBATCH --cpus-per-task=4   
#SBATCH --mem-per-cpu=4G
#SBATCH --output=images/apptainer_build.out
#SBATCH --error=images/apptainer_build.err

# Submit with: sbatch build_image.sh

set -e

# Check if we're running in SLURM
if [ -z "${SLURM_JOB_ID}" ]; then
    echo "Warning: This script is designed to run as a SLURM job, mainly for tmpdir access."
    echo "Consider submitting with: sbatch $0"
    echo "Continuing anyway..."
fi

## Choose your image names here
IMAGE_NAME="rstudio-server-FHIL.sif"
DEF_FILE="rstudio-server-FHIL.def"
BASE_DIR="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/images"

# Check if TMPDIR exists, otherwise use /tmp
if [ -z "${TMPDIR}" ] || [ ! -d "${TMPDIR}" ]; then
    BUILD_DIR="/tmp"
    echo "TMPDIR not set or invalid. Consider running this script on an interactive node to autoset the TMPDIR. Now attempting to use a different build dir."
else
    BUILD_DIR="${TMPDIR}"
    echo "Using TMPDIR: ${BUILD_DIR}"
fi

echo "Building RStudio Server Apptainer image..."
echo "Image will be saved as: ${IMAGE_NAME}"
echo "Build directory: ${BUILD_DIR}"

# Create build directory
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Copy definition file
cp "${BASE_DIR}/${DEF_FILE}" .

# Build the image
echo "Starting build process..."
apptainer build "${IMAGE_NAME}" "${DEF_FILE}"
#--fakeroot 

# Move to images directory
if [ -d "${BASE_DIR}" ]; then
    mv "${IMAGE_NAME}" "${BASE_DIR}"
    echo "Image built successfully and moved to ${BASE_DIR}/${IMAGE_NAME}"
else
    echo "Warning: ${BASE_DIR} directory not found. Image remains in ${BUILD_DIR}"
fi

# Cleanup
cd "${BASE_DIR}"
# rm -rf "${BUILD_DIR}"

echo "Build complete!"
echo "You can now use launch_rstudio_server.sh to run RStudio Server"
