
# Troubleshooting: Recovering SONiC Installation on a Switch  

This document outlines the steps taken to successfully boot into NOS (SONiC) install mode on a switch after a boot failure.

---

## **Issue**  
The switch failed to boot into SONiC due to a missing or corrupted bootloader. Symptoms included:  
- Stuck in **GRUB rescue mode** with `error: file /boot/grub/normal.mod not found`.  
- Unable to load the kernel directly from the GRUB shell.  
- EFI bootloader files (`bootx64.efi`, `grubx64.efi`) were present but not loading properly.  

---

## **Root Cause**  
- The GRUB bootloader was either misconfigured or corrupted.  
- The switch's boot order and EFI configuration were not correctly aligned with the installed SONiC image.  
- The ONIE boot partition was not properly mounted, preventing direct boot into SONiC.  

---

## **Resolution**  

### **Step 1: Enter BIOS and Adjust Boot Order**  
1. Power cycle the switch.  
2. Enter the BIOS setup by pressing **DEL** or **ESC** during boot.  
3. Navigate to the **Boot Override** section.  
4. Select `UEFI: Built-in EFI Shell` to enter the EFI shell.  

---

### **Step 2: Load the Bootloader Manually from EFI Shell**  
1. From the EFI shell, list available file systems:  
```bash
map -r
```
Example output:
```
fs0 :HardDisk - Alias hd17a65535a1 blk0 
fs1 :HardDisk - Alias hd17a65535a2 blk1
```

2. Mount the EFI partition:
```bash
fs0:
```

3. List available bootloader files:
```bash
ls EFI/BOOT
```
Example output:
```
bootx64.efi
grubx64.efi
fbx64.efi
grub.cfg
```

4. Attempt to load the default bootloader:
```bash
EFI/BOOT/BOOTX64.EFI
```

---

### **Step 3: Select ONIE Install Option in GRUB**  
1. After loading `bootx64.efi`, the GRUB menu appeared with ONIE options:  
   - `ONIE: Install OS`  
   - `ONIE: Rescue`  
   - `ONIE: Uninstall OS`  

2. Selected **"ONIE: Install OS"** to trigger the installer.

---

### **Step 4: ONIE Network-Based Recovery**  
1. ONIE attempts to discover the network-based installer from the control node:
```text
ONIE: Discovering installer...
```

2. The installer is detected and executed:
```text
ONIE: Executing installer: http://172.30.0.1:32000/onie
```

3. ONIE downloads and prepares the SONiC image:
```text
NOS: Verifying image checksum ... OK.
NOS: Preparing image archive ... OK.
NOS: Installing SONiC in ONIE
```

---

### **Step 5: Partition Repair and Installation**  
1. ONIE attempts to repair and recreate partition tables:
```text
NOS: Partition #3 is available
NOS: Creating new SONiC-OS partition /dev/sda3 ...
```
2. ONIE successfully creates the partition:
```text
NOS: The operation has completed successfully.
```

3. ONIE formats and mounts the partition:
```text
NOS: Creating filesystem with 7588935 4k blocks and 1900544 inodes
```

4. SONiC files are extracted and installed:
```text
NOS: inflating: boot/vmlinuz-5.10.0-21-amd64
NOS: inflating: boot/initrd.img-5.10.0-21-amd64
NOS: inflating: platform-modules-ag9032v2a_1.1_amd64.deb
```

---

### **Step 6: Finalize Installation**  
1. ONIE reported successful installation:
```text
NOS: Installed SONiC base image SONiC-OS successfully
```
2. ONIE rebooted the switch:
```text
ONIE: NOS install successful: http://172.30.0.1:32000/onie
ONIE: Rebooting...
```

---

### **Step 7: Verify Successful Boot**  
1. After reboot, GRUB listed the installed SONiC image:
```
* SONiC-OS-4.4.1-Enterprise_Base
  ONIE
```

2. Booted into SONiC:
```text
Debian GNU/Linux 11 sonic ttyS1
System is ready
```
