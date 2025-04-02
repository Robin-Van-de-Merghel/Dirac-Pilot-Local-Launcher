#!/bin/bash

# Create the Docker network if it doesn't exist
if ! docker network ls | grep -q pilot-network; then
    docker network create pilot-network
fi

# Build the pilot image
docker build -t pilot .

# Run the pilot container
docker run --rm \
  --name pilot-container \
  --network pilot-network \
  --link cvmfs-container:cvmfs \
  --volume /cvmfs:/cvmfs:shared \
  pilot bash /pilot-tester/start-pilot.sh

# Check if the pilot container finished successfully
PILOT_STATUS=$?

if [ $PILOT_STATUS -eq 0 ]; then
    echo "Pilot container finished successfully."
else
    echo "Pilot container encountered an error."
fi
