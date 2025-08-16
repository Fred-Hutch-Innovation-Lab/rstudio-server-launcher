#!/bin/bash
#SBATCH --job-name=rstudio-server
#SBATCH --time=5-00:00:00   # days-hours:minutes:seconds
#SBATCH --ntasks=1          
#SBATCH --cpus-per-task=8   # per sciwiki, use CPUs to inform mem. 1 CPU = 4 Gb
#SBATCH --mem-per-cpu=4G
#SBATCH --output=rstudio-server.job.out
#SBATCH --error=rstudio-server.job.err

module purge
module load Apptainer

# Select a more secure password if desired
export APPTAINERENV_PASSWORD="gizmo_rstudio" # $(openssl rand -base64 15)

## Container image path - local SIF file or GHCR image
## local
# export IMAGE_PATH="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/images/rstudio-server-FHIL.sif"
## or use apptainer pull to download the image from GHCR
## use 'ORAS' protocol for SIFs, and 'docker' for Docker images
export IMAGE_PATH="oras://ghcr.io/fred-hutch-innovation-lab/rstudio-server-launcher:0.0.3"

workdir=$(mktemp -d)
export APPTAINERENV_USER=$(id -un)


# Set R_LIBS_USER to an existing path specific to rocker/rstudio to avoid conflicts with
# personal libraries from any R installation in the host environment

cat > ${workdir}/rsession.sh <<"END"
#!/bin/sh
# export R_LIBS_USER=/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/users/${USER}/R/${IMAGE_NAME}
# mkdir -p "${R_LIBS_USER}"
## custom Rprofile & Renviron (default is $HOME/.Rprofile and $HOME/.Renviron)
export R_PROFILE_USER=/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/users/${USER}/.Rprofile ## comment these out if you don't have these files
export R_ENVIRON_USER=/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher/users/${USER}/.Renviron
exec /usr/lib/rstudio-server/bin/rsession "${@}"
END

chmod +x ${workdir}/rsession.sh

export APPTAINER_BIND="${workdir}/rsession.sh:/etc/rstudio/rsession.sh"

# Do not suspend idle sessions.
# Alternative to setting session-timeout-minutes=0 in /etc/rstudio/rsession.conf
# https://github.com/rstudio/rstudio/blob/v1.4.1106/src/cpp/server/ServerSessionManager.cpp#L126
export APPTAINERENV_RSTUDIO_SESSION_TIMEOUT=0

# Get an available port
export PORT=$(fhfreeport)

cat 2>&1 <<END
RStudio Server is starting up...

Container Information:
- Image: ${IMAGE_PATH}

Connection Information:
- URL: http://$(hostname).fhcrc.org:${PORT}
- Username: ${APPTAINERENV_USER}
- Password: ${APPTAINERENV_PASSWORD}

Once the server is running, you can access it directly from your browser at the URL above.
Make sure you're connected to the VPN if accessing from outside the network.

When done using RStudio Server, terminate the job by:

1. Exit the RStudio Session ("power" button in the top right corner of the RStudio window)
2. Issue the following command on the login node:

      scancel -f ${SLURM_JOB_ID}

Note that if the server is not available despite the job running, it may be because
the image is being downloaded. Check the error log to see if it's still pulling.
END

# Launch RStudio Server with Apptainer
apptainer exec --cleanenv \
                 --scratch /run,/var/lib/rstudio-server \
                 --workdir $(mktemp -d) \
                 --bind /home:/home \
                 --bind /fh:/fh \
                 ${IMAGE_PATH} \
   rserver --www-address=$(hostname) \
           --www-port $PORT \
           --auth-none=0 \
           --auth-pam-helper-path=pam-helper \
           --auth-stay-signed-in-days=30 \
           --auth-timeout-minutes=0 \
           --server-user=$(whoami)