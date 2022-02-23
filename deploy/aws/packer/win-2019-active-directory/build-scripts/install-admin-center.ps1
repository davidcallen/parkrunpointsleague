Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

wget "http://aka.ms/WACDownload" -outfile "WindowsAdminCenterCurrent.msi"
Start-Process msiexec.exe -Wait -ArgumentList  '/i WindowsAdminCenterCurrent.msi /qn /L*v log.txt SME_PORT=443 SSL_CERTIFICATE_OPTION=generate'