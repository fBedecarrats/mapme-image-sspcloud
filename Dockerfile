# Start with the base image for R
ARG BASE_IMAGE=rocker/verse:4.4.1
FROM $BASE_IMAGE

LABEL maintainer="InseeFrLab <innovation@insee.fr>"
LABEL org.opencontainers.image.title="mapme-spatial" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.source="https://github.com/mapme.initiative/mapme-docker" \
      org.opencontainers.image.vendor="MAPME Initiative" \
      org.opencontainers.image.description="A build of spatial libraries for use within MAPME" \
      org.opencontainers.image.authors="Darius Görgen <info@dariusgoergen.com>"

# Set environment variables
ARG R_VERSION="4.4.2"
ENV R_VERSION=${R_VERSION}
ENV R_HOME="/usr/local/lib/R"
ENV JAVA_VERSION="17"
ENV JAVA_HOME="/usr/lib/jvm/java-$JAVA_VERSION-openjdk-amd64"
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV CRAN="https://packagemanager.posit.co/cran/__linux__/jammy/latest"
ARG PROJ_VERSION=9.5.0
ARG GEOS_VERSION=3.13.0
ARG GDAL_VERSION=3.9.2
ARG NCPUS=-1

USER root

# Install dependencies, libraries, and configure environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        wget \
        build-essential \
        libcurl4-openssl-dev \
        libxml2-dev \
        libssl-dev \
        software-properties-common \
        openjdk-$JAVA_VERSION-jdk \
        cmake && \
    # Install R using Rocker's scripts
    git clone --branch R${R_VERSION} --depth 1 https://github.com/rocker-org/rocker-versioned2.git /tmp/rocker-versioned2 && \
    cp -r /tmp/rocker-versioned2/scripts/ /rocker_scripts/ && \
    /rocker_scripts/install_R_source.sh && \
    # Set up R with additional libraries and configure system for R packages
    /rocker_scripts/setup_R.sh && \
    /opt/install-system-libs.sh && \
    /opt/install-system-libs-R.sh && \
    # Install key R packages
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
    # Install duckdb extensions
    Rscript /opt/install-duckdb-extensions.R && \
    # Install Shiny Server and additional package bundles
    /rocker_scripts/install_shiny_server.sh && \
    /rocker_scripts/install_tidyverse.sh && \
    /rocker_scripts/install_geospatial.sh && \
    # Install spatial libraries
    wget https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz && \
    wget https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 && \
    wget https://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz && \
    tar -xvf proj-${PROJ_VERSION}.tar.gz && cd proj-${PROJ_VERSION} && ./configure && make -j${NCPUS} && make install && cd .. && \
    tar -xvf geos-${GEOS_VERSION}.tar.bz2 && cd geos-${GEOS_VERSION} && ./configure && make -j${NCPUS} && make install && cd .. && \
    tar -xvf gdal-${GDAL_VERSION}.tar.gz && cd gdal-${GDAL_VERSION} && ./configure && make -j${NCPUS} && make install && cd .. && \
    # Clean up
    rm -rf /tmp/* /var/lib/apt/lists/* && \
    chown -R ${USERNAME}:${GROUPNAME} ${HOME} ${R_HOME}

USER 1000

CMD ["R"]
