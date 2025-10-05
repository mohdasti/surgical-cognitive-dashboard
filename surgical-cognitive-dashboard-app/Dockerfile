FROM rocker/shiny:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /srv/shiny-server/app

# Copy application files
COPY . /srv/shiny-server/app

# Install R packages using renv
RUN R -e "if(!requireNamespace('renv', quietly=TRUE)) install.packages('renv'); renv::restore(prompt=FALSE)"

# Copy configuration files
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx and shiny-server
CMD service nginx start && /usr/bin/shiny-server
