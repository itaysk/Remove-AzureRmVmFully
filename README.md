When you create a simple VM in Azure, it is created with many additional components (like Network, Storage, etc).  
When you delete a VM in Azure, only the compute resource is removed, and the rest of it's dependencies remain.   
Some advise to delete the resource group, but that's a problem if you use the resource group for other stuff as well.  
This a helper PS function that I wrote, that can remove the VM including all the junk that it leaves after.

The supported scenario at the moment is that of a new VM via the portal with all the defaults. This means:

- 1 Compute resource
- 1 OS disk
- 0 data disks
- 1 diagnostics storage account (optional)
- 1 disk storage account
- VNET and subnet (optional)
- NIC
- NSG
- Public IP

The function witll expect and remove these. All resources are expected to be in the same resource group.  
Future versions will be smarter (PR welcome!)
