# Dirac Pilot Tool

## Introduction

To start the pilot tool, you can start it with `start-pilot.sh`. With its proper configuration, you will be able to debug easily.

This tool is based on the following workflow: [Dirac pilot integration workflow](https://github.com/DIRACGrid/Pilot/blob/master/.github/workflows/integration.yml).

## How to use it

1. Configure your environment variables and edit it.

```bash
cp .env.template .env
```

2. Import CERN certificates, see [this document](./cvmfs/etc/grid-security/README.md)

3. Get a `hostcert.pem` and a `hostkey.pem`, and move them in `./certs`:

```bash
# Create the certs folder
mkdir certs

# Suppose you have both pem files
# Move them to the certs folder
mv /path/to/hostcert.pem certs/
mv /path/to/hostkey.pem certs/
```

4. Now, start the script.

```bash
./start-pilot.sh
```