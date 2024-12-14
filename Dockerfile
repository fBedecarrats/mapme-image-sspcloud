# Base image
ARG BASE_IMAGE=rocker/verse:4.4.1
FROM $BASE_IMAGE

LABEL maintainer="InseeFrLab <innovation@insee.fr>"

# Set environment variables
ARG R_VERSION="4.4.2"
ARG JAVA_VERSION="17"
ARG PROJ_VERSION=9.5.0
ARG GEOS_VERSION=3.13.0
ARG GDAL_VERSION=3.9.2
ARG NCPUS=-1

ENV R_VERSION=${R_VERSION} \
    JAVA_VERSION=${JAVA_VERSION} \
    JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64" \
    PATH="${JAVA_HOME}/bin:${PATH}"

# Copy and prepare installation scripts
COPY scripts/install_sysdeps.sh /rocker_scripts/install_sysdeps.sh
COPY scripts/install_rspatial.sh /rocker_scripts/install_rspatial.sh

RUN chmod +x /rocker_scripts/install_sysdeps.sh && \
    chmod +x /rocker_scripts/install_rspatial.sh

# Install system dependencies for geospatial libraries
RUN bash /rocker_scripts/install_sysdeps.sh -proj $PROJ_VERSION -geos $GEOS_VERSION -gdal $GDAL_VERSION -ncpus $NCPUS

# Install R and additional libraries
RUN git clone --branch R${R_VERSION} --depth 1 https://github.com/rocker-org/rocker-versioned2.git /tmp/rocker-versioned2 && \
    cp -r /tmp/rocker-versioned2/scripts/ /rocker_scripts/ && \
    chown -R ${USERNAME}:${GROUPNAME} /rocker_scripts/ && \
    chmod -R 700 /rocker_scripts/ && \
    /rocker_scripts/install_R_source.sh && \
    /rocker_scripts/setup_R.sh && \
    # Reinstall removed system libs and additional dependencies
    /opt/install-system-libs.sh && \
    /opt/install-system-libs-R.sh && \
    install2.r --error \
        arrow \
        aws.s3 \
        devtools \
        DBI \
        duckdb \
        lintr \
        paws \
        quarto \
        renv \
        RPostgreSQL \
        styler \
        targets \
        vaultr && \
    Rscript /opt/install-duckdb-extensions.R && \
    /opt/install-java.sh && \
    /opt/install-quarto.sh && \
    /rocker_scripts/install_shiny_server.sh && \
    /rocker_scripts/install_tidyverse.sh && \
    /rocker_scripts/install_geospatial.sh && \
    bash /rocker_scripts/install_rspatial.sh -n $NCPUS && \
    chown -R ${USERNAME}:${GROUPNAME} ${HOME} ${R_HOME} && \
    rm -rf /var/lib/apt/lists/*

# Fix permissions and clean up
USER 1000

CMD ["R"]
