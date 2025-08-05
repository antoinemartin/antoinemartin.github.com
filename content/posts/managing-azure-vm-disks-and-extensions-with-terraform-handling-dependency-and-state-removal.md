---
title:
    'Managing Azure VM Disks and Extensions with Terraform: Handling Dependency
    and State Removal'
date: 2025-08-05
description:
    'How to optimize the Terraform destroy process of Azure VMs with extensions
    and data disk attachments, including practical techniques for managing
    dependencies and bulk state removals.'
tags:
    [
        'Terraform',
        'Azure',
        'VM',
        'Disks',
        'Extensions',
        'Infrastructure as Code',
    ]
toc:
    enable: true
---

When managing Azure Virtual Machines (VMs) with Terraform, especially Windows
VMs with extensions and attached data disks, it’s common to encounter challenges
around the order of resource destruction and avoiding unnecessary delays. This
post summarizes practical solutions to these issues, with example commands and
configuration snippets derived from a real-world scenario.

## The Problem: Terraform Deletes Extensions and Disks Before the VM

By default, Terraform tracks each Azure VM extension
(`azurerm_virtual_machine_extension`) and each data disk attachment
(`azurerm_virtual_machine_data_disk_attachment`) as independent resources. When
running `terraform destroy`, Terraform deletes these extensions and disk
attachments one by one **before** deleting the VM.

This sequence can slow down the destroy process and sometimes cause failures if
the VM or disks are not in the expected state. In Azure itself, deleting a VM
automatically deletes extensions attached to it, making explicit extension
destruction redundant.

Similarly, Terraform attempts to delete data disk attachments before the VM,
which would cause the disk to be actually unattached from the running VM, with
possible unexpected results.

## Solution Overview: Managing Dependencies and Terraform State

### 1. Remove Extensions and Disk Attachments from Terraform State

To avoid Terraform explicitly deleting extensions and attachments, you can
**remove these resources from Terraform state**, so Terraform forgets about them
and lets Azure handle deletion cascades when the VM is deleted.

Use shell commands like these to bulk-remove all extensions or data disk
attachments from your state:

```bash
# Remove all VM extensions from state
terraform state rm $(terraform state list | grep azurerm_virtual_machine_extension)

# Remove all data disk attachments from state
terraform state rm $(terraform state list | grep azurerm_virtual_machine_data_disk_attachment)
```

> **Note:** Always back up your Terraform state file before performing bulk
> state removals.

{{< admonition type=tip title="Backup & restore the terraform state" open=false >}}
Before performing any bulk state operations, it's crucial to create a backup of
your Terraform state file. Here is the recommended approach:

```bash
# Pull current state to a local backup file
terraform state pull > terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# Verify the backup contains your resources
terraform show terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
```

**To restore from backup if needed:**

```bash
# For remote state, push the backup back
terraform state push terraform.tfstate.backup.20250105_143000
```

{{< /admonition >}}

### 2. Enforce Disk-VM Destroy Ordering Using `depends_on`

Simply removing disk attachments from state can cause Terraform to try deleting
disks before the VM, which fails if disks are still attached. The reliable fix
is to add explicit dependencies so Terraform destroys resources in the correct
order.

For example, in your VM resource definition, add a `depends_on` block
referencing the disks, ensuring Terraform deletes disks **after** the VM:

```hcl
resource "azurerm_windows_virtual_machine" "vm" {
  # VM configuration...

  depends_on = [
    azurerm_managed_disk.additionnal_disks,
    # add all relevant disk attachment resources here
  ]
}
```

This setup tells Terraform: wait until those disk attachments are destroyed
before deleting the VM, avoiding the race condition that causes failure.

### Why Explicit Dependencies?

Terraform often establishes implicit dependencies through references, but these
sometimes represent only "resource existence," not full "readiness." Azure VM
extensions and disk attachments require the VM to be fully provisioned (or
deprovisioned) before related resources can be managed safely. The `depends_on`
attribute forces Terraform to respect this ordering.

## Summary Table: Terraform Destroy Behavior for Azure VM Components

| Resource Type         | Default Terraform Behavior  | Recommended Action                                          |
| --------------------- | --------------------------- | ----------------------------------------------------------- |
| VM Extensions         | Destroyed first, then VM    | Remove from state before VM destroy, or leave as is if okay |
| Data Disk Attachments | Destroyed before VM         | Use `depends_on` in VM to depend on disk attachments        |
| Managed Disks         | Destroyed after attachments | Generally safe with proper dependencies                     |
| VM                    | Destroy last                | Ensure all dependencies cleared or ordered correctly        |

## Final Recommendations

-   When destroying VMs with extensions, **remove extensions from Terraform
    state** to speed up destroy and rely on Azure's automatic cleanup.
-   For disks, **do not remove disk attachments or disks from state blindly**.
    Instead, add explicit `depends_on` dependencies in the VM resource to ensure
    Terraform respects the correct destroy order.
-   Always **backup your Terraform state** before any bulk operations.
-   For quick environment cleanup, consider deleting the whole resource group
    which cascades deletes in Azure.

Terraform allows robust, repeatable management of complex Azure infrastructures,
but some manual steps and explicit dependency handling are necessary to optimize
operations involving VMs with extensions and attached data disks.

The approach described here — combining state resource removals and dependency
declarations — has proven reliable in practice for ensuring clean, efficient VM
destruction workflows.

### Complete Example for Explicit Disk Dependency

```hcl
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_1" {
  managed_disk_id    = azurerm_managed_disk.data_disk_1.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun               = 0
  caching           = "ReadOnly"
}

resource "azurerm_windows_virtual_machine" "vm" {
  # VM configuration...

  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.data_disk_1
  ]
}
```

Using these techniques will help you avoid errors during destruction and save
time by preventing Terraform from destroying extensions and disk attachments
needlessly.

If you have questions or want to share more tips on Terraform with Azure, feel
free to comment below!

---

## References and Further Reading

For additional information on the topics covered in this post, consider these
resources:

**Terraform Azure Provider Documentation**

-   [Virtual Machine Data Disk Attachment Resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment.html) -
    Official documentation for managing disk attachments
-   [Azure Terraform Developer Guide](https://learn.microsoft.com/en-us/azure/developer/terraform/) -
    Microsoft's comprehensive guide to using Terraform with Azure

**Dependency Management Best Practices**

-   [Mastering Dependencies in Azure Terraform](https://iamachs.com/blog/azure-terraform/part-5-mastering-dependencies/) -
    In-depth guide on handling complex resource dependencies
-   [Understanding Terraform depends_on](https://spacelift.io/blog/terraform-depends-on) -
    Comprehensive explanation of explicit dependency management

**Community Solutions and Examples**

-   [Azure VM Module with Managed Disks](https://github.com/Azure/terraform-azurerm-avm-res-compute-virtualmachine/blob/main/main.disks.tf) -
    Production-ready example from Azure's official VM module
-   [Data Disk Configuration Discussion](https://stackoverflow.com/questions/55344773/terraform-azure-how-to-configure-type-of-data-disks-when-vm-is-provisioned-from) -
    Community solutions for VM provisioning with data disks

**Advanced Topics**

-   [Terraform Azure Disk Encryption Module](https://library.tf/modules/Azure/diskencrypt/azurerm/latest) -
    For implementing disk encryption at rest
-   [Terraform Azure VM Dependencies Tutorial](https://www.youtube.com/watch?v=fj261U4tK2A) -
    Video walkthrough of dependency management

**Known Issues and Workarounds**

-   [Azure Provider Issue #28887](https://github.com/hashicorp/terraform-provider-azurerm/issues/28887) -
    Tracking ongoing improvements to VM resource management
