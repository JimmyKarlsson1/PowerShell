If(!((Get-WmiObject Win32_Processor).VirtualizationFirmwareEnabled))
{
    Write-Output "Virtualization is not enabled, please enable"
    exit
}

#Start-Process Powershell -verb Runas
Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -All
Enable-WindowsOptionalFeature -Online -FeatureName "Containers"
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker-desktop  -ProviderName Chocolatey -Force -Confirm:$false
Restart-Computer -Force
#Login DockerID (nessesary?)
#Linux/Windowscontainer /Tray
