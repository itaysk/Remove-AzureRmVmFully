Function Remove-AzureRmVmFully {
    <#
    .SYNOPSIS
    Removes an Azure VM including it's dependencies
    .DESCRIPTION
    Removes an Azure VM including it's dependencies
    .EXAMPLE
    Remove-AzureRmVmFully -ResourceGroupName "rg1" -Name "vm1" -RemoveStorageDiag -RemoveStorageOsDisk -RemoveStorageDataDisk -RemoveNics -RemoveNSG -RemovePip -RemoveVnet
    .PARAMETER ResourceGroupName
    The name of the resource group the VM and it's dependencies are in
    .PARAMETER Name
    The name of the VM
    #>
    [cmdletbinding(DefaultParameterSetName="SelectToRemove")]
    Param(
        [Parameter(ParameterSetName="SelectToRemove",
            Mandatory=$true)]
        [string]
        $ResourceGroupName,
        [Parameter(ParameterSetName="SelectToRemove",
            Mandatory=$true)]
        [string]
        $Name,
        [Parameter(ParameterSetName="SelectToRemove")]
        [switch]
        $RemoveStorageDiag,
        [Parameter(ParameterSetName="SelectToRemove")]
        [switch]
        $RemoveStorageOsDisk,
        [Parameter(ParameterSetName="SelectToRemove")]
        [switch]
        $RemoveStorageDataDisk,
        [Parameter(ParameterSetName="SelectToRemove")]
        [switch]
        $RemoveNics,
        [Parameter(ParameterSetName="SelectToRemove")]
        [switch]
        $RemoveNSG,
        [Parameter(ParameterSetName="SelectToRemove")]
        [switch]
        $RemovePip,
        [Parameter(ParameterSetName="SelectToRemove")]
        [switch]
        $RemoveVnet
    )
    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction Stop
    $vm | Remove-AzureRmVM -Force -ErrorAction SilentlyContinue -ErrorVariable +err
    $rgName = $vm.ResourceGroupName

        
    if ($RemoveStorageDiag) {
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name ([Uri]$vm.DiagnosticsProfile.BootDiagnostics.StorageUri).Host.Split('.')[0] -Force -ErrorAction SilentlyContinue -ErrorVariable +err
    }
    if ($RemoveStorageDisk) {
        Remove-AzureRmStorageAccount -ResourceGroupName $rgName -Name ([Uri]$vm.StorageProfile.OsDisk.Vhd.Uri).Host.split('.')[0] -Force -ErrorAction SilentlyContinue -ErrorVariable +err
    }
    if ($RemoveStorageDataDisk) {
        #$vm.StorageProfile.DataDisks[0]
    }
    if ($RemoveNics) {
        $nics = $vm.NetworkProfile.NetworkInterfaces | ForEach-Object {Get-AzureRmNetworkInterface -ResourceGroupName $rgName -Name $_.Id.split('/')[-1] -ErrorAction SilentlyContinue -ErrorVariable +err}            
        Foreach ($nic in $nics) {
            if ($RemoveNics) {
                $nic | Remove-AzureRmNetworkInterface -Force -ErrorAction SilentlyContinue -ErrorVariable +err        
            }
            if ($RemoveNSG) {
                Remove-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Name $nic.NetworkSecurityGroup.Id.split('/')[-1] -Force -ErrorAction SilentlyContinue -ErrorVariable +err
            }
            if ($RemovePip) {
                $nic.IpConfigurations | Where-Object { $_.PublicIpAddress -ne $null } | ForEach-Object {Remove-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name $_.PublicIpAddress.Id.Split('/')[-1] -Force -ErrorAction SilentlyContinue -ErrorVariable +err}
            }
            if ($RemoveVnet) {
                $vnetName = $nic.IpConfigurations[0].Subnet.Id.split('/')[-3] #assuming single nic?
                Remove-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -Force -ErrorAction SilentlyContinue -ErrorVariable +err
            }
        }
    }

    $err
    
}