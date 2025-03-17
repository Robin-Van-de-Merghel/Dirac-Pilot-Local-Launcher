# Certificates

We have to configure certificates so that the request won't be refused, and also so that `SSL` can verify our own certificate.

To do it, we have to fetch everything from the [`lxplus` server](https://abpcomputing.web.cern.ch/computing_resources/lxplus/).

```bash
# In your first terminal
ssh <username>@lxplus.cern.ch

rsync -a <username>@lxplus.cern.ch:/cvmfs/lhcb.cern.ch/etc/grid-security/ cvmfs/etc/grid-security/
```

After doing every commands, you can close your `SSH` connection, and continue. Your `/grid-security/` folder will be filled with:

- `/certificates/` to let `SSL` verify your certificate chain
- `/vomsdir/` and `/vomses/`, TODO: