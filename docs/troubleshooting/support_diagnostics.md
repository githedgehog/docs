# Support Diagnostics

If the steps in the rest of this section don't resolve the issue, collect the
following before reaching out to support. The more of this is included up
front, the faster the issue can be localized.

## What to include

- Your `hhfab`/`hhfabctl` version and a summary of your topology (gateway
  present, external peering, VPCs in use).
- A plain description of the symptom and roughly when it started.
- Anything that changed around that time - a config push, upgrade, reboot,
  or node/server move - even if you're not sure it's related.
- Which specific switches or nodes are affected, if you've already narrowed
  it down.
- Any diagnostics you've already collected yourself. Include the raw output
  rather than a summary, so we don't have to re-derive what you've already
  found.

## Collecting a support bundle

`hhfabctl` is installed on the control node as a `kubectl` plugin, so it's
invoked as `kubectl hhfab`, not as a standalone command:

```console
core@control-1 ~ $ kubectl hhfab support dump -y
```

This produces a single timestamped `.hhs` file containing cluster resources
(Fabricator, Agent, Connection, VPC, and related objects) and pod logs.
Secrets are redacted, but the bundle still reflects your deployment's real
topology and state.

## Switch-level diagnostics

For issues that look like a dataplane or hardware problem rather than a
control-plane one (for example, traffic not forwarding despite correct BGP/EVPN
state), support may also ask for a `show techsupport` capture from specific
switches. This is a per-device SONiC command - if asked, run it only on the
switches identified as relevant rather than the whole fabric, both to keep
the capture a manageable size and because a comparison against a switch that
*is* behaving correctly is often the most useful artifact.

!!! note
    Support bundles and switch dumps reflect your real deployment and should
    be treated as confidential. Share them only through the channel your
    support contact provides, not in a public issue or channel.
