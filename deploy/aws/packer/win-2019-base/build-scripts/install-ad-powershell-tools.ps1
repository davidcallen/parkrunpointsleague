Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

# We need the Active Directory Powershell module for ec2 instance to update AD on 1st bootup with its dns name as a ComputerDescription
Get-WindowsFeature -Name RSAT-AD-PowerShell
Install-WindowsFeature -Name RSAT-AD-PowerShell
Get-WindowsFeature -Name RSAT-AD-PowerShell
