# imports
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import io
import stat
import tempfile
import sys
import shutil
import base64
import bz2
import logging
import time
import tarfile
import hashlib
# for remote logging
import subprocess
import json
import os
import urllib
import ssl
import shlex
from uuid import uuid1

try:
    # For Python 3.0 and later
    from urllib.request import urlopen, HTTPError, URLError
    from urllib.parse import urlencode
except ImportError:
    # Fall back to Python 2's urllib2
    from urllib2 import urlopen, HTTPError, URLError
    from urllib import urlencode

try:
  from cStringIO import StringIO
except ImportError:
  from io import StringIO

# formatting with microsecond accuracy, (ISO-8601)

class MicrosecondFormatter(logging.Formatter):
  def formatTime(self, record, datefmt=None):
    ct = self.converter(record.created)
    if datefmt:
        s = time.strftime(datefmt, ct)
    else:
        t = time.strftime("%Y-%m-%dT%H:%M:%S", ct)
        s = "%s,%06dZ" % (t, (record.created - int(record.created)) * 1e6)
    return s

# setting up the logging
# formatter = logging.Formatter(fmt='%(asctime)s UTC %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
formatter = MicrosecondFormatter('%(asctime)s %(levelname)-8s [%(name)s] %(message)s')
logging.Formatter.converter = time.gmtime
try:
  screen_handler = logging.StreamHandler(stream=sys.stdout)
except TypeError:  # python2.6
  screen_handler = logging.StreamHandler(strm=sys.stdout)
screen_handler.setFormatter(formatter)

# add a string buffer handler
sio = StringIO()
buffer = logging.StreamHandler(sio)
buffer.setFormatter(formatter)

logger = logging.getLogger('pilotLogger')
logger.setLevel(logging.DEBUG)
logger.addHandler(screen_handler)
logger.addHandler(buffer)

# just logging the environment as first thing
logger.debug('===========================================================')
logger.debug('Environment of execution host\n')
for key, val in getattr(os, "environb", os.environ).items():
  # Clean the environment of non-utf-8 characters
  try:
    key = key.decode("utf-8")
    val = val.decode("utf-8")
  except UnicodeDecodeError as e:
    logger.error("Dropping %s=%s due to: %s", key, val, e)
    del os.environ[key]
    continue
  logger.debug(key + '=' + val)
logger.debug('===========================================================\n')

logger.debug(sys.version)

# putting ourselves in the right directory
pilotExecDir = ''
if not pilotExecDir:
  pilotExecDir = os.getcwd()
pilotWorkingDirectory = tempfile.mkdtemp(suffix='pilot', prefix='DIRAC_', dir=pilotExecDir)
pilotWorkingDirectory = os.path.realpath(pilotWorkingDirectory)
os.chdir(pilotWorkingDirectory)
logger.info("Launching dirac-pilot script from %s" %os.getcwd())

# Getting the pilot files
logger.info("Getting the pilot files from LOCATION")

location = 'LOCATION'.replace(' ', '').split(',')

# we try from the available locations
locs = [os.path.join('https://', loc) if not loc.startswith(('file:', 'https:')) else loc for loc in location]
locations = locs + [os.path.join(loc, 'pilot') for loc in locs]
# adding also the cvmfs locations
locations += "LOCATION_CVMFS"

for loc in locations:
  print('Trying %s' % loc)

  # Getting the json, tar, and checksum file
  try:

    # urllib is different between python 2 and 3
    if sys.version_info < (3,):
      from urllib2 import urlopen as url_library_urlopen
      from urllib2 import URLError as url_library_URLError
    else:
      from urllib.request import urlopen as url_library_urlopen
      from urllib.error import URLError as url_library_URLError

    # ---------------------------  GET 3 FILES FROM URL ---------------------------
    for fileName in ['checksums.sha512', 'pilot.json', 'pilot.tar']:
      # needs to distinguish whether urlopen method contains the 'context' param
      # in theory, it should be available from python 2.7.9
      # in practice, some prior versions may be composed of recent urllib version containing the param
      if 'context' in url_library_urlopen.__code__.co_varnames:
        import ssl
        context = ssl._create_unverified_context()
        remoteFile = url_library_urlopen(os.path.join(loc, fileName),
                                         timeout=10,
                                         context=context)

      else:
        remoteFile = url_library_urlopen(os.path.join(loc, fileName),
                                         timeout=10)

      localFile = open(fileName, 'wb')
      localFile.write(remoteFile.read())
      localFile.close()

      if fileName != 'pilot.tar':
        continue
      try:
        pt = tarfile.open('pilot.tar', 'r')
        pt.extractall()
        pt.close()
      except Exception as x:
        print("tarfile failed with message (this is normal!) %%s" % repr(x), file=sys.stderr)
        logger.error("tarfile failed with message (this is normal!) %%s" % repr(x))
        logger.warn("Trying tar command (tar -xvf pilot.tar)")
        res = os.system("tar -xvf pilot.tar")
        if res:
          logger.error("tar failed with exit code %%d, giving up (this is normal!)" % int(res))
          print("tar failed with exit code %%d, giving up (this is normal!)" % int(res), file=sys.stderr)
          raise
    # if we get here we break out of the loop of locations
    break
  except (url_library_URLError, Exception) as e:
    print('%%s unreacheable (this is normal!)' % loc, file=sys.stderr)
    logger.error('%%s unreacheable (this is normal!)' % loc)
    logger.exception(e)

else:
  print("None of the locations of the pilot files is reachable", file=sys.stderr)
  logger.error("None of the locations of the pilot files is reachable")
  sys.exit(-1)

# download was successful, now we check checksums
if os.path.exists('checksums.sha512'):
  checksumDict = {}
  chkSumFile = open('checksums.sha512', 'rt')
  for line in chkSumFile.read().split('\\n'):
    if not line.strip():  ## empty lines are ignored
      continue
    expectedHash, fileName = line.split('  ', 1)
    if not os.path.exists(fileName):
      continue
    logger.info('Checking %%r for checksum', fileName)
    fileHash = hashlib.sha512(open(fileName, 'rb').read()).hexdigest()
    if fileHash != expectedHash:
      print('Checksum mismatch for file %%r' % fileName, file=sys.stderr)
      print('Expected %%r, found %%r' %(expectedHash, fileHash), file=sys.stderr)
      logger.error('Checksum mismatch for file %%r', fileName)
      logger.error('Expected %%r, found %%r', expectedHash, fileHash)
      sys.exit(-1)
    logger.debug('Checksum matched')

# now finally launching the pilot script (which should be called dirac-pilot.py)
# get the setup name an -z, if present to get remote logging in place
opt = ""
# try to get a pilot stamp from the environment:
UUID =  os.environ.get('DIRAC_PILOT_STAMP')
if UUID is None:
    UUID = str(uuid1())
opt = opt + " --pilotUUID " + UUID

args = opt.split()

# let's see if we have remote logging enabled (-z), if not run the pilot script with os.system, as before

logger.info("dirac-pilot.py  will be called: with %s " % args)

# call dirac-pilot.py and pass log records accumulated so far as a standard input. A decision to use the buffer
# in a remote logger is made later in dirac-pilot.py script

proc = subprocess.Popen(shlex.split("$py dirac-pilot.py " + opt), bufsize = 1, stdin = subprocess.PIPE,
                        stdout=sys.stdout, stderr=sys.stderr, universal_newlines = True)
proc.communicate(buffer.stream.getvalue())
ret = proc.returncode
# and cleaning up
buffer.stream.close()
shutil.rmtree(pilotWorkingDirectory)

# did it fail?
if ret:
  sys.exit(1)
