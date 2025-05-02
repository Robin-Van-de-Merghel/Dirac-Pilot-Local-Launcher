# Adapted from https://github.com/DIRACGrid/Pilot/blob/master/.github/workflows/integration.yml
#!/bin/bash
source .env

conda create -n pilot-dev python=$PYTHON_VERSION -c conda-forge -y

conda activate pilot-dev
conda info

if ! python --version &>/dev/null; then
  echo "'python' command not found, defaulting to 'python3'"
  alias python=python3
fi

python --version

# Wait until /cvmfs/lhcb.cern.ch is mounted (i.e., the directory exists and is accessible)
echo "🧹 Waiting for /cvmfs/lhcb.cern.ch to be mounted..."
until mount | grep -q '/cvmfs/lhcb.cern.ch'; do
  echo "⏳ /cvmfs/lhcb.cern.ch is not yet mounted, retrying..."
  sleep 5
done

echo "✅ /cvmfs/lhcb.cern.ch is mounted, proceeding with the pilot."

# Continue with the rest of the start-pilot.sh script
echo

echo "🧹 Getting the environment variables and cleaning pilot.out..."
echo "" >pilot.out

if test -d $PILOT_PATH; then
  echo "🥹 Pilot exists, no need to import it."
else
  echo "🤕 Pilot doesn't exists, cloning it..."

  git clone $CUSTOM_PILOT_GIT $PILOT_PATH

  currentDir=$PWD
  cd $PILOT_PATH
  git checkout $CUSTOM_GIT_BRANCH
  cd $currentDir
fi

echo "✏️ Filling the data..."
sed -i "s/VAR_JENKINS_SITE/$JENKINS_SITE/g" pilot.json
sed -i "s/VAR_JENKINS_CE/$JENKINS_CE/g" pilot.json
sed -i "s/VAR_JENKINS_QUEUE/$JENKINS_QUEUE/g" pilot.json
sed -i "s/VAR_DIRAC_VERSION/$DIRAC_VERSION/g" pilot.json
sed -i "s#VAR_CS#$CONFIGURATION_SERVER#g" pilot.json
sed -i "s#VAR_USERDN#/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=${CERN_USERNAME}/CN=${CERN_USERID}/CN=${CERN_FULL_NAME}#g" pilot.json
sed -i "s#VAR_USERDN_GRIDPP#$DIRACUSERDN_GRIDPP#g" pilot.json

echo "🚀 Launching the pilot !"
# Warning: PilotSecret and DiracX flags may not exist depending on your pilot version
# You can just comment them
python $PILOT_PATH/Pilot/dirac-pilot.py \
  --modules https://github.com/DIRACGrid/DIRAC.git:::DIRAC:::integration \
  -M 1 \
  -S "$SETUP" \
  -N "$CENAME" \
  -Q "$JENKINS_QUEUE" \
  -n "$JENKINS_SITE" \
  --cert \
  --certLocation=$CERT_LOCATION \
  --wnVO="$WNVO" \
  --pilotUUID="${PILOT_UUID}" \
  --preinstalledEnvPrefix="/cvmfs/lhcb.cern.ch/lhcbdirac" \
  --debug \
  --CVMFS_locations="$CVMFS_LOCATION/" \
  --diracx_URL="$DIRACX_SERVER" \
  --pilotSecret="$DIRACX_PILOT_SECRET"
echo "Python script exit status: $?"

echo "Done."
