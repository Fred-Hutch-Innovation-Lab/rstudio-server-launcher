#!/bin/sh
#SBATCH --job-name=rstudio-server
#SBATCH --time=4-00:00:00   # days-hours:minutes:seconds
#SBATCH --ntasks=1          
#SBATCH --cpus-per-task=2   # per sciwiki, use CPUs to inform mem. 1 CPU = 4 Gb
#SBATCH --mem-per-cpu=4G
#SBATCH --output=/home/%u/rstudio-server.job.%j.out
#SBATCH --error=/home/%u/rstudio-server.job.%j.err
# customize --output path as appropriate (to a directory readable only by the user!)

# Create temporary directory to be populated with directories to bind-mount in the container
# where writable file systems are necessary. Adjust path as appropriate for your computing environment.

# Select a more secure password if desired
export APPTAINERENV_PASSWORD="gizmo_rstudio" # $(openssl rand -base64 15)
export IMAGE_NAME="rstudio-server-FHIL.sif"

export FILE_BASE="/fh/fast/_IRC/FHIL/grp/inhouse_computational_resources/rstudio-server-launcher"
# Found in $FILE_BASE/images/

export USER_FILE_BASE="${FILE_BASE}/user/${USER}"
workdir=$(mktemp -d)
export APPTAINERENV_USER=$(id -un)


# Set R_LIBS_USER to an existing path specific to rocker/rstudio to avoid conflicts with
# personal libraries from any R installation in the host environment

cat > ${workdir}/rsession.sh <<"END"
#!/bin/sh
export R_LIBS_USER=${USER_FILE_BASE}/R/${IMAGE_NAME}
mkdir -p "${R_LIBS_USER}"
## custom Rprofile & Renviron (default is $HOME/.Rprofile and $HOME/.Renviron)
export R_PROFILE_USER=$USER_FILE_BASE/.Rprofile ## comment these out if you don't have these files
export R_ENVIRON_USER=$USER_FILE_BASE/.Renviron
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
# ${APPTAINERENV_PASSWORD}
cat 1>&2 <<END
RStudio Server is starting up...

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
END

singularity exec --cleanenv \
                 --scratch /run,/var/lib/rstudio-server \
                 --workdir $(mktemp -d) \
                 ${FILE_BASE}/images/${IMAGE_NAME} \
   rserver --www-address=$(hostname) \
           --www-port $PORT \
           --auth-none=0 \
           --auth-pam-helper-path=pam-helper \
           --auth-stay-signed-in-days=30 \
           --auth-timeout-minutes=0 \
           --server-user=$(whoami)