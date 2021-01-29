﻿Configuration Net48Install
{
    node "localhost"
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        Script Install_Net_4.8
        {
            SetScript = {

                $path = "C:\Temp"
                If(!(test-path $path)){
                New-Item -ItemType Directory -Force -Path $path
                Write-Host "Temp folder has been created"
                }

                ## Download .NET 4.8 Installer from MS
 
                $url = "https://go.microsoft.com/fwlink/?linkid=2088631"
                $output = "C:\Temp\ndp48-x86-x64-allos-enu.exe"
 
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($url, $output)
 
                # Pause
 
                $currentTime = Get-Date
                Write-Host "Pausing 20 seconds... $currentTime"
                Start-Sleep -s 20
 
                ## Run .NET 4.8 Installer from MS
 
                try{
                $args = @('/q',"/norestart")
                $currentTime = Get-Date
                Write-Host ".Net 4.8 install starting... $currentTime"
                Start-Process -Filepath "C:\Temp\ndp48-x86-x64-allos-enu.exe" -ArgumentList $args -WorkingDirectory "C:\Temp" -Wait 
                $currentTime = Get-Date
                Write-Host ".Net 4.8 install complete.  $currentTime"
                }
                catch {Write-Host "An error occurred! Please try again..."}
            }

            TestScript = {
                [int]$NetBuildVersion = 528040

                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    [int]$CurrentRelease = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    if ($CurrentRelease -lt $NetBuildVersion)
                    {
                        Write-Verbose "Current .Net build version is less than 4.8 ($CurrentRelease)"
                        return $false
                    }
                    else
                    {
                        Write-Verbose "Current .Net build version is the same as or higher than 4.8 ($CurrentRelease)"
                        return $true
                    }
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return $false
                }
            }

            GetScript = {
                if (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | %{$_ -match 'Release'})
                {
                    $NetBuildVersion =  (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full').Release
                    return $NetBuildVersion
                }
                else
                {
                    Write-Verbose ".Net build version not recognised"
                    return ".Net 4.8 not found"
                }
            }
        }
    }
}

Net48Install -OutputPath $env:SystemDrive:\DSCconfig
Set-DscLocalConfigurationManager -ComputerName localhost -Path $env:SystemDrive\DSCconfig -Verbose
Start-DscConfiguration -ComputerName localhost -Path $env:SystemDrive:\DSCconfig -Verbose -Wait -Force