# Dirac Pilot Tool

## Introduction

To start the pilot tool, you can start it with `start-pilot.sh`. With its proper configuration, you will be able to debug easily.

This tool is based on the following workflow: [Dirac pilot integration workflow](https://github.com/DIRACGrid/Pilot/blob/master/.github/workflows/integration.yml).

## How to use it

### Environment variables configuration

```bash
cp .env.template .env
```

> [!TIP]
> Note: If you want to use the "real" pilot you have to comment the `Dev` environment variables at the end, and configure the environment file as so:

```bash
# Production
PILOT_PATH="../Pilot/"
CUSTOM_PILOT_GIT="https://github.com/DIRACGrid/Pilot"
CUSTOM_GIT_BRANCH="devel"
```

> [!TIP]
> Note: You can also use your own Pilot so you can code and debug at the same time without pushing. You have to comment the `production` variables, and configure yours as so:

```bash
# Cloning your Pilot fork into the testPilot directory
git clone git@github.com:<your-name>/Pilot.git Pilot-code
```

Then in your `.env`:

```bash
# Dev
PILOT_PATH="./Pilot-code"
CUSTOM_PILOT_GIT="./Pilot-code"
CUSTOM_GIT_BRANCH="devel"
```

This will use your local repository with a given branch.

### Certificates configuration

#### Server certificates

We have to configure certificates so that the request won't be refused, and also so that `SSL` can verify our own certificate.

To do it, we can connect with CVMFS (see [here](https://cvmfs.readthedocs.io/)) with the following command:

```bash
docker run -d --rm \
  -e CVMFS_CLIENT_PROFILE=single \
  -e CVMFS_REPOSITORIES=dirac.egi.eu,grid.cern.ch,lhcb.cern.ch \
  --cap-add SYS_ADMIN \
  --device /dev/fuse \
  --volume /cvmfs:/cvmfs:shared \
  --name cvmfs-container \
  registry.cern.ch/cvmfs/service:latest \
  --plaftorm linux/amd64
```

After launching this container, we can link `/cvmfs` to our pilot container.

> [!TIP]
> On mac, it may not work, and output: `fuse: mount failed: Permission denied`. To fix it:

```bash
# Run as root, and add apparmor:unconfined
sudo docker run -d --rm \
  -e CVMFS_CLIENT_PROFILE=single \
  -e CVMFS_REPOSITORIES=dirac.egi.eu,grid.cern.ch,lhcb.cern.ch \
  --cap-add SYS_ADMIN \
  --device /dev/fuse \
  --volume /cvmfs:/cvmfs:shared \
  --security-opt apparmor:unconfined \
  --name cvmfs-container \
  registry.cern.ch/cvmfs/service:latest \
  --platform linux/amd64
```

#### Your certificates

Get a `hostcert.pem` and a `hostkey.pem`, and move them in `./certs`:

```bash
# Create the certs folder
mkdir certs

# Suppose you have both pem files
# Move them to the certs folder
mv /path/to/hostcert.pem certs/
mv /path/to/hostkey.pem certs/
```

### Run the Pilot

We dockerize the Pilot so we are sure that the environment is "clean", and that nothing will interfere.

```bash
chmod +x start-docker.sh

# Start the docker and mamba
./start-docker.sh
```

## Sample

An example of a `pilot.cfg` run can be found [here](./example.cfg).