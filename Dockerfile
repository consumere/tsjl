# Use the official Julia image as the base image
FROM julia:latest
# FROM consumere/shinyapps:japp

# Set the working directory inside the container
WORKDIR /app

# Copy the Julia Project.toml and Manifest.toml files to the container
# COPY Project.toml Manifest.toml /app/

RUN julia -e 'using Pkg; Pkg.add.(["CSV", "DataFrames", "Dash", "PlotlyJS","Base64","Dates","Statistics"])'

#RUN julia -e 'using Pkg; Pkg.add.(["CSV", "DataFrames", "Dash","Plots", "PlotlyJS","Base64","Dates","Statistics"])'

# Install the Julia packages
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.update("."); Pkg.instantiate();'

# Copy the rest of the application files to the container
COPY . /app

# CMD ["julia", "appts.jl"]
# CMD ["julia", "dpr_dash.jl"]

EXPOSE 8050

#CMD ["julia --optimize=3 --math-mode=fast", "dpr_dash.jl"]

CMD ["julia","--optimize=3","--math-mode=fast","dpr_dash.jl"]


#docker build -t consumere/shinyapp:dprjs .
#docker run -p 8080:8050 consumere/shinyapp:dprjs
#docker build -t consumere/shinyapps:dprjs .
#docker run -p 8050:8050 consumere/shinyapps:dprjs