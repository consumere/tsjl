# Use the official Julia image as the base image
FROM julia:latest
# FROM consumere/shinyapps:japp

# Set the working directory inside the container
WORKDIR /app

# Copy the Julia Project.toml and Manifest.toml files to the container
#COPY Project.toml Manifest.toml /app/

RUN julia -e 'using Pkg; Pkg.add.(["CSV", "DataFrames", "Dash", "PlotlyJS","Base64","Dates","Statistics"])'
# RUN julia -e 'using Pkg; Pkg.add.(["Dash", "PlotlyJS","Base64","Dates","Statistics"])'

# Install the Julia packages
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate();'

# Copy the rest of the application files to the container
COPY . /app

# Set the entry point command to run the Julia script
#CMD ["julia", "apptsum.jl"]

CMD ["julia", "appts.jl"]

#docker run -p 8080:8080 consumere/shinyapp:tsjl-ci
