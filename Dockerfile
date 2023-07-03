# Use the official Julia image as the base image
FROM julia:latest

# Set the working directory inside the container
WORKDIR /app

# Copy the Julia Project.toml and Manifest.toml files to the container
COPY Project.toml Manifest.toml /app/

# Install the Julia packages
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate();'

# Copy the rest of the application files to the container
COPY . /app

# Set the entry point command to run the Julia script
CMD ["julia", "apptsum.jl"]
