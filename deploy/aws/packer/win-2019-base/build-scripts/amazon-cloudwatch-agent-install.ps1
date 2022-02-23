Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

# Download and Install service
Invoke-WebRequest -Uri 'https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi' -OutFile amazon-cloudwatch-agent.msi
Start-Process msiexec.exe -Wait -ArgumentList  '/i amazon-cloudwatch-agent.msi /quiet'

# Prevent Service from automatic start - will need configuration first on initial bootup via user-data script
Set-Service -Name AmazonCloudWatchAgent -StartupType Manual
Stop-Service -Name AmazonCloudWatchAgent

xcopy "C:\Users\Administrator\amazon-cloudwatch-agent.json" "C:\ProgramData\Amazon\AmazonCloudWatchAgent\"
