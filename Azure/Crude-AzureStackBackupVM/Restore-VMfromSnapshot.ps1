[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$OSsnapshotName,    
    [Parameter(Mandatory=$true)]
    [string]$virtualNetworkName,
    [Parameter(Mandatory=$true)]
    [string]$virtualNetworkResourceGroup,
    [Parameter(Mandatory=$true)]
    [string]$virtualMachineName,
    [Parameter(Mandatory=$True)]
    [ValidateSet("Yes","No")]
    [string]$PublicIP,
    [Parameter(Mandatory=$false)]
    [string]$DataSnapshotName1,
    [Parameter(Mandatory=$false)]
    [string]$DataSnapshotName2,
    [Parameter(Mandatory=$false)]
    [string]$virtualMachineSize = 'Standard_DS1',
    [Parameter(Mandatory=$false)]
    [string]$Location = 'East1',
    [Parameter(Mandatory=$false)]
    [string]$DiagnosticAccount
)

$random = Get-Random
$osDiskName = "os-$virtualMachineName-$random"

If(Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue)
{
    Write-Verbose -Message "$ResourceGroupName already exists"
}
else {
    Write-Verbose -Message "$resourceGroupName does not exist, creating in $Location"
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location
}

#Disk and snapshotconfiguration
$OSSnapshot = Get-AzureRmSnapshot  | where{$_.name -eq $OSsnapshotName}
$diskConfig = New-AzureRmDiskConfig -Location $OSsnapshot.Location -SourceResourceId $OSsnapshot.Id -CreateOption Copy
get-date
$OSdisk = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $osDiskName
get-date
#Initialize virtual machine configuration
$VirtualMachine = New-AzureRmVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize
#Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -ManagedDiskId $OSdisk.Id -CreateOption Attach -Windows


If($DataSnapshotName1)
{
    $Datadiskname1 = "data-$VirtualmachineName-01"
    $Snapshot = Get-AzureRmSnapshot  | where{$_.name -eq $DataSnapshotName1}
    $diskConfig = New-AzureRmDiskConfig -Location $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy
    $Datadisk1 = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $Datadiskname1
    $VirtualMachine = Add-AzureRmVMDataDisk -VM $VirtualMachine -ManagedDiskId $Datadisk1.Id -CreateOption Attach -Lun "0"
}
If($DataSnapshotName2)
{
    $Datadiskname2 = "data-$VirtualmachineName-02"
    $Snapshot = Get-AzureRmSnapshot  | where{$_.name -eq $DataSnapshotName2}
    $diskConfig = New-AzureRmDiskConfig -Location $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy
    $Datadisk2 = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $Datadiskname2
    $VirtualMachine = Add-AzureRmVMDataDisk -VM $VirtualMachine -ManagedDiskId $Datadisk2.Id -CreateOption Attach -Lun "1"
}



If($DiagnosticAccount)
{
    Write-Verbose -Message "Enable boot diagnostic on $DiagnosticAccount storage account"
    $VirtualMachine = Set-AzureRmVMBootDiagnostics -VM $VirtualMachine -StorageAccountName $DiagnosticAccount -Enable:$true -ResourceGroupName $resourceGroupName
}
else {
    Write-Verbose "Creating storage account for diagnostic"
    $StorageaccountName = ($Location+"diag"+$random).ToLower()
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $StorageaccountName -SkuName Standard_LRS -Location $Location -Kind Storage
    $VirtualMachine = Set-AzureRmVMBootDiagnostics -VM $VirtualMachine -StorageAccountName $StorageaccountName -Enable:$true -ResourceGroupName $resourceGroupName
}
#$VirtualMachine = Set-AzureRmBootDiagnostic -VM $VirtualMachine -StorageAccountName "hejsan"
If($PublicIP -eq "Yes")
{
	#Create a public IP for the VM
	$publicIp = New-AzureRmPublicIpAddress -Name ($VirtualMachineName.ToLower()+'_ip') -ResourceGroupName $resourceGroupName -Location $Location -AllocationMethod Dynamic
}

#Get the virtual network where virtual machine will be hosted
$vnet = Get-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $virtualNetworkResourceGroup

# Create NIC in the first subnet of the virtual network
$nic = New-AzureRmNetworkInterface -Name ($VirtualMachineName.ToLower()+'_nic') -ResourceGroupName $resourceGroupName -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

#Create the virtual machine with Managed Disk
New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $Location