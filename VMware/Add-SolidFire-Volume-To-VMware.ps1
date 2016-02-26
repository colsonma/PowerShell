<#
This script file  contains elements that can be used for connecting SolidFire volumes to a VMware vSphere environment.

This is NOT an end to end script with logic, error-handling, and full capabilities.

The contents in this script serves to provide examples of cmdlets required to connect SolidFire volumes to vSphere.

- Script will connect to both VMware and SF environments.
- Creates us an existing SF Cluster Acct
- Add Existing Volumes to AccessGroup
- Gets ESXi iSCSI initiator IQNs
- Checks for the new targets
- Creates VMware datastores based on the SF volume name
- Rescans the HBAs.
#>
#Connect to SF Cluster

Connect-SFCluster -Target "Cluster FQDN" -UserName admin -Password "PW"

#Connect to vCenter

Connect-VIServer -Server "vcenter shortname" -UserName "UserName" -Password "PW"

#Set Account

$account = Get-SFAccount "SF Cluster Admin Acct"


# Get Volumes

$volumes = Get-SFVolume "Existing Vol Name"*

# Get list of ESXi host software initiator IQNs.  
# You can use Get-Cluster prior to Get-VMhost to reduce scope.

$IQNs = Get-VMHost | Select name,@{n="IQN";e={$_.ExtensionData.Config.StorageDevice.HostBusAdapter.IscsiName}}

# Use this if an existing volume access group

Write-Host "Adding Volumes to Volume Access Group" -ForegroundColor Yellow
$vag = Get-SFVolumeAccessGroup -VolumeAccessGroupName "Existing Access Group Name"
$vag | Add-SFVolumeToVolumeAccessGroup -VolumeID $volumes.VolumeID


# Replace Cluster name with the cluster you want to make the changes for.
$hosts = Get-cluster "vCenter Cluster Name" | Get-vmhost

# Check Target to hosts

Write-Host "Showing ISCSI targets post Add" -ForegroundColor Yellow
$hosts = Get-cluster "vCenter Cluster Name" | Get-vmhost | Get-VMhostHba -Type IScsi | Get-IScsiHbaTarget

# Rescan HBAs

Get-cluster "vCenter Cluster Name" | Get-VMhost | Get-VMhostStorage -RescanAllHba -RescanVMFs

# Create Datastore

$hosts = Get-cluster "vCenter Cluster Name" | Get-VMhost | Select -First 1
foreach($volume in $volumes){
$canonicalname = "naa." + $volume.ScsiNAADeviceID
New-Datastore -VMhost $vmhost -Name $volume.VolumeName -Path $canonicalname -Vmfs -FileSystemVersion 5
}


# Rescan HBAs

Get-cluster "vCenter Cluster Name" | Get-VMhost | Get-VMhostStorage -RescanAllHba -RescanVMFs
