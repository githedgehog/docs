# Virtual Machines

!!! warning "Not officially supported"
    Hedgehog does not officially support running control or gateway nodes as
    virtual machines.

The examples on this page use libvirt/QEMU. The underlying requirements — UEFI
without secure boot, VirtIO devices, and PCI passthrough for gateway data-plane
NICs — apply to any hypervisor.

## Common Settings

These apply to both control and gateway nodes.

- Use the `q35` machine type with `efi` firmware. Only UEFI boot is supported.
- Disable secure boot:

    ```xml
    <os firmware='efi'>
      <firmware>
        <feature enabled='no' name='secure-boot'/>
      </firmware>
    </os>
    ```

- Use VirtIO devices wherever possible.
- Attach a console device.
- Enable autostart so the VM starts with the host.
- The QEMU guest agent is built into the Flatcar image. To use it, add a
  virtio-serial port named `org.qemu.guest_agent.0`. See the
  [Flatcar documentation](https://www.flatcar.org/docs/latest/os-config/network/acpi/?highlight=guest#qemu-guest-agent)
  for details.

## Control Node

- Size the VM to meet or exceed [the control node requirements](./requirements.md#control-node).
- Configure both NICs as `virtio`: one for the outside world, one for the
  out-of-band management network of the fabric switches.

## Gateway Node

- There are no minimum performance guarantees when the gateway is in a VM.
- Size the VM to meet or exceed [the gateway node requirements](./requirements.md#gateway-node).
- Configure the management NIC as `virtio`.
- Use PCI passthrough — not SR-IOV — for the data-plane NICs. Passthrough
  usually requires host-side configuration (IOMMU, driver binding) before the
  device can be attached:
    - [RHEL passthrough documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_managing_linux_virtual_machines/attaching-host-devices-to-virtual-machines#attaching-pci-devices-to-virtual-machines-by-using-the-command-line)
    - [Ubuntu passthrough documentation](https://ubuntu.com/server/docs/how-to/virtualisation/libvirt/#device-passthrough-hotplug)
