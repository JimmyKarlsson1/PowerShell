<#
#>

[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    [Parameter(Mandatory=$True)]
    [string]$virtualMachineName
)

$date = Get-Date -Format yyyyMMdd-HHmmm
$vm = get-AzureRMVM -ResourceGroupName $resourceGroupName -Name $virtualMachineName
$collection = @()
$snapshot =  New-AzureRMSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $vm.Location -CreateOption copy
New-AzureRMSnapshot -Snapshot $snapshot -SnapshotName "Backup-$($VM.Name)-$($vm.StorageProfile.OsDisk.Name)-$($Date)" -ResourceGroupName $resourceGroupName
If($vm.StorageProfile.DataDisks -ne 'null')
    {
        foreach($i in $vm.StorageProfile.DataDisks){
            Write-Verbose -Message "Doing snapshot on $($i.Name) $(Get-Date)"
            $DataSnapShot =New-AzureRMSnapshotConfig -SourceUri $i.ManagedDisk.Id -Location $vm.Location -CreateOption copy
            New-AzureRMSnapshot -Snapshot $DataSnapshot -SnapshotName "Backup-$($VM.Name)-$($i.Name)-$($Date)" -ResourceGroupName $resourceGroupName
        }
    }
else {
    Write-Verbose -Message "No Data disks are attached to the VM"
}