Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Get-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
