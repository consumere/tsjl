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
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.update(); Pkg.instantiate();'

# Copy the rest of the application files to the container
COPY . /app

# CMD ["julia", "appts.jl"]
# CMD ["julia", "dpr_dash.jl"]

EXPOSE 8050

#/usr/local/bin/docker-entrypoint.sh: 11: exec: julia --optimize=3 --math-mode=fast: not found 
#CMD ["julia --optimize=3 --math-mode=fast", "dpr_dash.jl"]

CMD ["julia", "--math-mode=fast","dpr_dash.jl"]

#mit dem push wird das image in dockerhub geladen: (via circleci)
#docker run -p 8088:8050 consumere/shinyapp:tsjl-ci 

# a=consumere/shinyapps:dprjs  
# b=consumere/shinyapp:tsjl-ci 
# docker commit $b $a
# docker push $a


#docker build -t consumere/shinyapp:dprjs .
#docker run -p 8080:8050 consumere/shinyapp:dprjs
#docker build -t consumere/shinyapps:dprjs .
#docker run -p 8050:8050 consumere/shinyapps:dprjs