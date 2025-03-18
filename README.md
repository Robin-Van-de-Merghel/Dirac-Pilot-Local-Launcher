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
CUSTOM_GIT_BRANCH="adding-jwt-support"
```

This will use your local repository with a given branch.

### Certificates configuration

#### Server certificates

We have to configure certificates so that the request won't be refused, and also so that `SSL` can verify our own certificate.

To do it, we have to fetch everything from the [`lxplus` server](https://abpcomputing.web.cern.ch/computing_resources/lxplus/).

```bash
# Creating the filesystem used for certificates
mkdir -p cvmfs/etc/grid-security

# Fetching lxplus certificates
rsync -a <username>@lxplus.cern.ch:/cvmfs/lhcb.cern.ch/etc/grid-security/ cvmfs/etc/grid-security/
```

After doing every commands, your `/grid-security/` folder will be filled with:

- `/certificates/` to let `SSL` verify your certificate chain
- `/vomsdir/` and `/vomses/`, TODO:

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
# Build the image, run it with the name `pilot`, and --rm for auto deleting it
docker build . -t pilot && docker run --name pilot --rm -it pilot
```

## Sample

An example of a `pilot.cfg` run can be found [here](./example.cfg).