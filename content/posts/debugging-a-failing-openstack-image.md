---
title: Debugging a failing OpenStack image
date: 2023-01-13
slug: 2023/01/13/debugging-a-failing-openstack-image
description: |
  How to debug locally on a windows machine an Openstack image
Categories:
  - Devops
tags:
  - Openstack
  - cloud-init
  - hyper-v
  - wsl
  - windows
toc:
  enable: true
---

## The problem

On my
[alpine-openstack-vm](https://github.com/antoinemartin/alpine-openstack-vm)
project, There is a CI process producing a VM image for OpenStack. The process
involves testing that the machine boots. [The test
fails](https://github.com/antoinemartin/alpine-openstack-vm/actions/runs/3909412713),
but the machine is actually booted. What doesn’t work is the ssh access. As
the machine can only be reached via SSH with a private key for obvious security
reasons, not having access prevents proper debug.

## The objective

The objective is to be able to run the produced VM locally to assess the issue.
As the image in its current form doesn’t work, the VM image needs to be
slightly modified in order to allow access. If the VM is run locally, adding a
root password should be sufficient.

## The tools

- Windows 11
- Hyper-V. Information on installation is
  [here](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v).
  If you are using WSL, you should already be set up or really close.
- PowerShell.
- A Windows Subsystem for Linux (WSL) distribution with `qemu-img` installed.
  You can set it up faster with
  [Powershell-WSL-Manager](https://mrtn.me/PowerShell-Wsl-Manager/).

We need to download your Openstack image locally. Hopefully, it is kept as an
artifact of [our
build](https://github.com/antoinemartin/alpine-openstack-vm/actions/runs/3909412713).

## The steps

### Image conversion

We are going to convert the image from the `qcow2` format to the `vhdx` in order
to be able to use it as the base disk of an Hyper-V VM. This will also allow us
to mount it inside a WSL distribution to modify it.

This is done with the `qemu-img` command:

```bash
❯ qemu-img convert alpine-openstack.qcow2 -O vhdx -o subformat=dynamic alpine-openstack.vhdx
```

### Mounting the image

Now we can mount the image in WSL:

```bash
❯ wsl.exe --mount --vhd alpine-openstack.vhdx
Le disque a été monté en tant que « /mnt/wsl/CUsersAntoineMartinDownloadsalpineopenstackvhdx ».
Remarque : l’emplacement sera différent si vous avez modifié le paramètre automount.root dans /etc/wsl.conf.
Pour démonter et détacher le disque, exécutez « wsl.exe --unmount \\?\C:\Users\AntoineMartin\Downloads\alpine-openstack.vhdx ».
❯
```

### Chrooting inside the image

We can now chroot inside the image to modify it:

```bash
❯ chroot /mnt/wsl/CUsersAntoineMartinDownloadsalpineopenstackvhdx
➜  /
```

### Allowing access to the image

We set a root password in order to be able to login in our VM:

```bash
➜  ~ passwd
New password:
Retype new password:
passwd: password updated successfully
➜  ~
```

in `/etc/ssh/sshd_config`, we enable root login and password authentication:

```bash
# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
PermitRootLogin yes
```

In `/etc/cloud/cloud.cfg`, we allow ssh password authentication:

```yaml
ssh_pwauth:   true
```

At this point, you can also add a `/root/.ssh/authorized_keys` file containing a
public key for ssh authenticiation.

Then you can exit the chroot with the `exit` command.

### Unmounting the image

From windows, type:

```powershell
PS> wsl --unmount  alpine-openstack.vhdx
```

### Creating the Hyper-V VM

{{< admonition warning >}}

To be able to create Hyper-V VMs from the command line, your user needs to be part of the `Hyper-V Administrators` group. You can add your user to this group with the command line:
```powershell
PS> # In a `Run as Administrator` terminal (consider sudo from scoop)
PS> net localgroup "Hyper-V Administrators" <UserName> /add
```

Unfortunately, you will also need to restart your machine 😞
{{< /admonition >}}

Create and start the VM from the command line:

```powershell
# Isolating the VM
PS> mkdir debug
PS> mv alpine-openstack.vhdx debug
PS> cd debug
# Creating the VM
PS> New-VM -Name debug -MemoryStartupBytes 2GB -Path . -BootDevice VHD -VHDPath .\alpine-openstack.vhdx -SwitchName "Default Switch" -Generation 1

Name  State CPUUsage(%) MemoryAssigned(M) Uptime   Status                Version
----  ----- ----------- ----------------- ------   ------                -------
debug Off   0           0                 00:00:00 Fonctionnement normal 11.0

PS> Start-VM -Name debug
```

{{< admonition tip >}}

We use `-Generation 1` here in order to avoid UEFI initialization.
{{< /admonition >}}

Now you can connect to the VM:

```powershell
PS> vmconnect localhost debug
```

And you should be able to see the VM window:

![image](/images/57d67816-b3f8-491d-b681-aa56e4be79f1.png)

The actual issue appears clearly in the image above. You should be able to
connect as root with the password you entered before:

![image](/images/f3769ee0-7eba-4322-aef9-9cab9d0b0001.png)

And look at the issues that created the error.

You can also connect with ssh. To find the IP address of the machine, you can
type the following command on Powershell:

```powershell
PS> Get-NetNeighbor -LinkLayerAddress 00-15-5d-*

ifIndex IPAddress                                          LinkLayerAddress      State       PolicyStore
------- ---------                                          ----------------      -----       -----------
60      172.26.137.156                                     00-15-5D-25-05-1D     Reachable   ActiveStore
29      172.20.68.230                                      00-15-5D-00-3F-24     Permanent   ActiveStore
```

Here the address of the machine would be the second one, the one marked with
Permanet. You can connect to it:

```powershell
PS> ssh root@172.20.68.230
Warning: Permanently added '172.20.68.230' (ED25519) to the list of known hosts.
root@172.20.68.230's password:
Welcome to Alpine!

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <https://wiki.alpinelinux.org/>.

You can setup the system with the command: setup-alpine

You may change this message by editing /etc/motd.

➜  ~
```

On the terminal window as well as with ssh, you are now able to find the issue
with your image.

Once the reason of the issue is found, you can delete the VM:

```powershell
PS> Stop-VM debug
PS> Remove-VM debug -Force
PS>
```

## Final thoughts

The above procedure is interesting not only for debugging non working images but
also to run any image as long as the image format can be handled by qemu. Having
WSL at hand is also handy to mount and hack the image.
