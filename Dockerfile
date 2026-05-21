FROM rocker/shiny:4.5.2

# Системные зависимости
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    # Базовые
    libxml2-dev libcurl4-openssl-dev libssl-dev libcairo2-dev \
    libharfbuzz-dev libfribidi-dev libfreetype6-dev \
    libpng-dev libtiff5-dev libjpeg-dev \
    # Для fs, httpuv, processx
    libuv1-dev cmake \
    # Для гео-пакетов: sf, terra, raster
    libgdal-dev gdal-bin libproj-dev libgeos-dev libudunits2-dev \
    # Для s2
    libabsl-dev \
    # Для V8
    libnode-dev nodejs \
    # Утилиты
    curl git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем renv-файлы
COPY renv.lock ./renv.lock
COPY renv/ ./renv/      
COPY .Rprofile ./.Rprofile 

# Установка renv + восстановление пакетов (одна сессия!)
RUN Rscript -e ' \
    install.packages("renv", repos = "https://cloud.r-project.org"); \
    renv::restore(prompt = FALSE, rebuild = FALSE, clean = TRUE) \
  '

# Код приложения
COPY . .

EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]