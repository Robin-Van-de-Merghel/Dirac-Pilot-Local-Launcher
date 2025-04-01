# Adapted from https://github.com/DIRACGrid/Pilot/blob/master/.github/workflows/integration.yml
#!/bin/bash

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
source .env
echo "" > pilot.out

if test -d $PILOT_PATH; then
    echo "🥹 Pilot exists, no need to import it."
else
    echo "🤕 Pilot doesn't exists, cloning it..."
    
    git clone $CUSTOM_PILOT_GIT $PILOT_PATH
fi


currentDir=$PWD
    
cd $PILOT_PATH
git checkout $CUSTOM_GIT_BRANCH
cd $currentDir


echo "© Copying the schema and cfg..."
cp $PILOT_PATH/tests/CI/pilot_newSchema.json pilot.json
# cp $PILOT_PATH/tests/CI/PilotLoggerTest.cfg pilot.cfg

echo "✏️ Filling the data..."
sed -i "s/VAR_JENKINS_SITE/$JENKINS_SITE/g" pilot.json
sed -i "s/VAR_JENKINS_CE/$JENKINS_CE/g" pilot.json
sed -i "s/VAR_JENKINS_QUEUE/$JENKINS_QUEUE/g" pilot.json
sed -i "s/VAR_DIRAC_VERSION/$DIRAC_VERSION/g" pilot.json
sed -i "s#VAR_CS#$CONFIGURATION_SERVER#g" pilot.json
sed -i "s#VAR_USERDN#/DC=ch/DC=cern/OU=Organic Units/OU=Users/CN=${CERN_USERNAME}/CN=${CERN_USERID}/CN=${CERN_FULL_NAME}#g" pilot.json
sed -i "s#VAR_USERDN_GRIDPP#$DIRACUSERDN_GRIDPP#g" pilot.json


echo "🚀 Launching the pilot !"
python3 $PILOT_PATH/Pilot/dirac-pilot.py \
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
  --debug \
  --CVMFS_locations="$CVMFS_LOCATION/" \
  --diracXServer="$DIRACX_SERVER" \
  --pilotSecret="$DIRACX_PILOT_SECRET"

echo "Python script exit status: $?"

echo "Done."
