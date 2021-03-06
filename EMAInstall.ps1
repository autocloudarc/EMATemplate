###################################################################################################
#                                        
#  Author: Adriana Solano                
#  Company: Intel Corporation                   
#  Date: 11/13/2020                      
#         
#  The following script is intended to install Intel Endpoint Management Assistant (EMA) in your 
#  virtual machine. Please follow the steps below and complete any updates required.
#
###################################################################################################
#
#  Copyright 2021 Intel Corporation.
#
#  This software and the related documents are Intel copyrighted materials, and your use of them is 
#  governed by the express license under which they were provided to you ("License"). Unless the 
#  License provides otherwise, you may not use, modify, copy, publish, distribute, disclose or 
#  transmit this software or the related documents without Intel's prior written permission.
#
#  This software and the related documents are provided as is, with no express or implied warranties, 
#  other than those that are expressly stated in the License.                    
#                                        
###################################################################################################

$hostname = $args[0]
$dbserver = $args[1]
$dbname = "emadb"
$guser =  $args[2]
$gpass =  $args[3]

# Verify if temp path exists. If it doesn't exist, create C:\Temp path

$path = "C:\Temp"
If(!(test-path $path)){
    New-Item -ItemType Directory -Force -Path $path
    Write-Host "Temp folder has been created"
}

# Download EMA Install file from GitLab

$url = "https://downloadmirror.intel.com/28994/eng/Ema_Install_Package_1.3.3.1.exe"
$output = "C:\Temp\EMAInstall.zip"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $output)

# Extract EMA Install file

add-type -AssemblyName System.IO.Compression.FileSystem
[system.io.compression.zipFile]::ExtractToDirectory('C:\Temp\EMAInstall.zip','C:\Temp\EMAInstall')

$currentTime = Get-Date
Write-Host "Pausing 120 seconds to ensure database is ready... $currentTime"
Start-Sleep -s 120

# Provide local system account that is running this script with permissions needed to create EMA database

NET STOP MSSQLSERVER
NET START MSSQLSERVER /mSQLCMD 

Write-Host "Enabling system account to create Intel EMA database... "
SQLCMD -Q "EXEC master..sp_addsrvrolemember @loginame = N'NT AUTHORITY\SYSTEM', @rolename = N'sysadmin'" 

NET STOP MSSQLSERVER
NET START MSSQLSERVER

# Run EMA Installer.exe

try{
$args = @("FULLINSTALL","--host=$hostname","--dbserver=$dbserver","--db=$dbname","--guser=$guser","--gpass=$gpass","--verbose","--autoexit","--accepteula")
$currentTime = Get-Date
Write-Host "EMA install starting... $currentTime"
Start-Process -Filepath "C:\Temp\EMAInstall\EMAServerInstaller.exe" -ArgumentList $args -WorkingDirectory "C:\Temp\EMAInstall" -Wait 
$currentTime = Get-Date
Write-Host "EMA install process complete.  $currentTime"
}
catch {Write-Host "An error ocurred! Please try again..."}

# Clean up permissions
Write-Host "Restoring database permissions... "
SQLCMD -Q "EXEC master..sp_dropsrvrolemember @loginame = N'NT AUTHORITY\SYSTEM', @rolename = N'sysadmin'" 

