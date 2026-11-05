# Fabric Controller

Every time a new version of the fabric controller starts, e.g. after an [upgrade](../install-upgrade/upgrade.md), it
initializes before doing anything else: it refreshes all stored objects (VPCs, Connections, Switches, etc.) with the
defaults of the new version and validates them. Until the initialization is complete, the fabric controller is
**locked**:

- nothing is deployed, switches and gateways keep running their current configuration
- changes to the Fabric API objects are refused with an error like:

```console
Error from server (ServiceUnavailable): fabric controller is locked, see kubectl get fabriccontrollers -A
```

The initialization usually takes seconds to a few minutes, depending on the number of objects.

## Checking the State

The state of the fabric controller is in the `FabricController` object named `default` in the `fab` namespace:

```console
core@control-1 ~ $ kubectl get fabriccontrollers -A
NAMESPACE   NAME      READY   VERSION    INITIALIZED   STATE         MESSAGE       MAINTENANCE   AGE
fab         default   True    v0.144.1   v0.144.1      Initialized   operational   <none>        2d2h
```

`READY` is `True` once the running version (`VERSION`) has been initialized (`INITIALIZED`). `STATE` is one of:

- `Initializing`: the initialization is running, or retrying after an error shown in `status.error`
- `Failed`: the refresh found objects it couldn't fix, listed in `status.problems`
- `Maintenance`: [maintenance mode](#maintenance-mode) is on
- `Initialized`: the fabric controller is unlocked and working normally

`kubectl fabric inspect fabric` also shows the state, together with the objects that keep it locked, whenever the
fabric controller isn't ready.

## Objects the Refresh Couldn't Fix

If the refresh finds objects it can't fix, the fabric controller stays locked in the `Failed` state and lists the first
ones in `status.problems`, with the counts per kind in `status.refresh.kinds`:

```bash
kubectl -n fab get fabriccontroller default -o yaml
```

Each problem has one of the following reasons:

- `Rejected`: the update with the new defaults was refused, e.g. by the CRD schema
- `Stale`: the object still doesn't carry the new defaults after retries, e.g. as something else keeps writing it back
- `Invalid`: the object fails the validation of the new version

Once the fabric controller is `Failed`, it only initializes again when it restarts or when its spec changes, e.g. when
leaving maintenance mode after fixing the objects.

## Maintenance Mode

As changes are refused while the fabric controller is locked, maintenance mode is the way to fix the objects that keep
it locked:

- all changes to the objects are accepted, validation errors only come back as warnings
- nothing is deployed, the same as while locked

!!! warning
    Maintenance mode is dangerous. Leaving it initializes the fabric controller again, which validates every object on
    its own only: a conflict between objects or the deletion of an object still in use, made in maintenance mode,
    goes unnoticed and gets deployed. Only use it to fix the objects listed in `status.problems`.

1. Turn maintenance mode on:

    ```bash
    kubectl -n fab patch fabriccontroller default --type merge -p '{"spec":{"maintenance":true}}'
    ```

1. Fix or delete the objects listed in `status.problems`; every change returns a warning that the fabric controller is
   in maintenance

1. Turn maintenance mode off, which starts the initialization again:

    ```bash
    kubectl -n fab patch fabriccontroller default --type merge -p '{"spec":{"maintenance":false}}'
    ```

1. Check that the fabric controller is `Ready` with `kubectl get fabriccontrollers -A`
