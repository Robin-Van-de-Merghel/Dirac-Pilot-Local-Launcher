# Certificates

We have to configure certificates so that the request won't be refused, and also so that `SSL` can verify our own certificate.

To do it, we have to fetch everything from the [`lxplus` server](https://abpcomputing.web.cern.ch/computing_resources/lxplus/). You will need two terminals:

```bash
# In your first terminal
ssh <username>@lxplus.cern.ch

# Then generate your X509 proxy
voms-proxy-init

$ Enter GRID pass phrase for this identity:
$ Created proxy in /tmp/x509up_xXXXXXX.
$ Your proxy is valid until Xxx Xxx XX XX:XX:XX XXX XXXX

# Then wait for the second terminal to have finished, then you'll be able to close this one
# You have to wait because it is in the /tmp directory, or else it will disappear
```

```bash
# In your second terminal, located at the root of this project
rsync -r <username>@lxplus.cern.ch:/cvmfs/lhcb.cern.ch/etc/grid-security/ cvmfs/etc/grid-security/
```

After doing every commands, you can close your `SSH` connection, and continue. Your `/grid-security/` folder will be filled with:

- `/certificates/` to let `SSL` verify your certificate chain
- `/vomsdir/` and `/vomses/`, TODO: