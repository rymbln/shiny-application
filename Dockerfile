# Base image https://hub.docker.com/u/rocker/
FROM rocker/shiny:4.5.2

# system libraries of general use
## install debian packages
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libsqlite3-dev \
    libpq-dev \
    libssh2-1-dev \
    unixodbc-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libgdal-dev

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

# copy necessary files
## renv.lock file
COPY ./renv.lock ./renv.lock
## app folder
COPY . ./app

# install renv & restore packages
RUN Rscript -e 'install.packages("renv", repos = "https://cloud.r-project.org")' && \
    Rscript -e 'renv::restore(prompt = FALSE, rebuild = FALSE)'

# expose port
EXPOSE 3838

# run app on container start
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]