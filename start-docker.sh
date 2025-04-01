if [[ -f "./Miniforge3.sh" ]]; then
    echo "Miniforge is already installed"
else
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O Miniforge3.sh
fi

# Build the image, run it with the name `pilot`, and --rm for auto deleting it
# And link /cvmfs to our cvmfs service (see in #Server certificates)
docker build --platform=linux/amd64 -t pilot . && docker run --rm \
  --link cvmfs-container:cvmfs \
  --volume /cvmfs:/cvmfs:shared \
  --name pilot-container \
  --platform linux/amd64 \
  pilot bash /pilot-tester/start-pilot.sh