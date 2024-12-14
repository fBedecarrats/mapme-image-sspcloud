# Start from the r-datascience base image
FROM inseefrlab/images-datascience:r-datascience

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV WORK_DIR=/home/onyxia/work
ENV S3_PATH=s3/fbedecarrats/diffusion
ENV R_LIBS_USER=/home/onyxia/R/x86_64-pc-linux-gnu-library/4.1

# Step 1: Update and upgrade the package list
RUN apt-get update && apt-get upgrade -y

# Step 2: Install software-properties-common if not present
RUN apt-get install -y --no-install-recommends software-properties-common

# Step 3: Add the Ubuntugis PPA and update package list
RUN add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && apt-get update

# Step 4: Remove any existing GDAL, GEOS, and PROJ libraries for a clean slate
RUN apt-get remove -y gdal-bin libgdal-dev libgeos-dev libproj-dev || true && \
    apt-get autoremove -y || true

# Step 5: Install the latest versions of GDAL, GEOS, and PROJ libraries from the Ubuntugis PPA
RUN apt-get install -y --no-install-recommends \
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libsqlite0-dev \
    libudunits2-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 6: Remove and reinstall 'sf' and 'terra' R packages
RUN Rscript -e "remove.packages(c('sf', 'terra'))" || true && \
    Rscript -e "
        install.packages(
            c('sf', 'terra'),
            type = 'source',
            repos = 'https://cran.r-project.org'
        )
    "

# Step 7: Install additional R packages for mapme.biodiversity and related dependencies
RUN Rscript -e "
    packages <- c('mapme_impact_training', 'gt', 'geodata', 'babelquarto', 'wdpar',
                  'mapme.biodiversity', 'progressr', 'DiagrammeR', 'rstac', 'tictoc',
                  'exactextractr', 'cowplot', 'stargazer', 'MatchIt', 'cobalt', 'landscapemetrics');
    install.packages(packages, repos = 'https://cran.r-project.org');
    "

# Step 8: Install MinIO Client (mc) for S3 access
RUN curl -O https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x mc && mv mc /usr/local/bin/

# Set working directory and ownership
WORKDIR $WORK_DIR
RUN mkdir -p $WORK_DIR && chown -R onyxia:users $WORK_DIR



