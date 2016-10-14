# escape=`
FROM microsoft/windowsservercore
MAINTAINER brycem@microsoft.com
LABEL Readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md"
LABEL Description="This Dockerfile will install and build the latest nighly PS build on WindowsServerCore."
#ENTRYPOINT ["C:\Program Files\PowerShell\PowerShell.exe", "-NoExit", "-c Write-Host Thanks's for trying our Alpha!"]

ARG fork=PowerShell
ARG branch=BryceM-NightlyDockerFiles

# Overriding default 'cmd /S /C <run>' shell command
SHELL ["powershell.exe", "-command"]

#Prepare shell environment
RUN [ScriptBlock]$Pref= `
    {`
      function Prompt `
      { `
        [String]$('['+(Get-Date -Format g)+'] PS '+ `
        $($executionContext.SessionState.Path.CurrentLocation)+ `
        $('>'*($nestedPromptLevel+1))+' ') `
      } ; $ErrorActionPreference='Stop'; `
      $ConfirmPreference='None'; `
      $VerbosePreference='Continue'; `
      $Env:chocolateyUseWindowsCompression = 'false' ; `
      $Env:Path+='`;"$Env:ProgramFiles\Git\cmd"' ; `
      <#StartLogging#> `
        Start-Transcript -path C:\Dockerfile.log -append -IncludeInvocationHeader ; `
        $PSVersionTable | Write-Output ; `
        $RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' ; `
        $BuildString = $(Get-ItemProperty -Path $RegPath).BuildLabEx ; `
        $EditionId   = $(Get-ItemProperty -Path $RegPath).EditionId ; `
        $ProductName = $(Get-ItemProperty -Path $RegPath).ProductName ; `
        $InstallationType = $(Get-ItemProperty -Path $RegPath).InstallationType ; `
        Write-Output -InputObject $('FullBuildString: '+$BuildString) ; `
        Write-Output -InputObject $('OperatingSystem:  '+$ProductName+' '+$EditionId+' '+$InstallationType) `
      <#EndLogging#> `
    } ; Write-Output $Pref | Out-File $(New-Item -Path $PROFILE -ItemType File -Force).FullName -Encoding utf8 -NoNewline ;

#Install NuGet, Chocolatey, Git, & MSBuild
RUN Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force ; `
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted ; `
    Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) ; `
    choco install -v -y `
      git `
      netfx-4.6.1-devpack `
      microsoft-build-tools `
      cmake ;

#Install Windows SDK 10 - Uses installer policy workaround for "Exit code was '-2147023293'" issue
RUN $RegKey ='HKLM:\Software\Policies\Microsoft\Windows\Installer'; `
    New-Item -Path $RegKey -Force ; `
    New-ItemProperty -Path $RegKey -Name DisableRollback -PropertyType DWord -Value 1 -Force ; `
    choco install windows-sdk-10.0 -v -y --allow-empty-checksums ;

#Setup PowerShell Repo at C:\PowerShell
ENV fork=$fork
ENV branch=$branch
RUN git clone -v --recursive https://github.com/$Env:fork/PowerShell.git -b $Env:branch ; `
    Test-Path -Path 'C:\PowerShell\Build.psm1' ;

RUN Set-Location C:\PowerShell\ ; `
    Import-Module ./build.psm1 ; `
    Start-PSBootstrap ; `
    Start-PSBuild -Clean -CrossGen -Runtime win10-x64 -Configuration Release ; `
    Start-PSPackage -Type msi ; `
    Start-Process -FilePath msiexec.exe -ArgumentList '-qn','-i "$env:FullOutput\*.msi"','-norestart' -wait ; 

#Restore Installation Policy settings to default and clean up the $PROFILE
RUN Set-ItemProperty -Path $RegKey -Name DisableRollback -Value 0 -Force ; `
    Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted; `
    $prof=(Get-Content $PROFILE).Replace(' Start-Trans','<#Start-Trans') ; `
    $prof=$prof.Replace('<#StartLogging#>','<#StartLogging ') ; `
    $prof=$prof.Replace('<#EndLogging#>',' EndLogging#>') ; `
    $prof| Out-File $PROFILE -Encoding utf8 -NoNewline ;

CMD ["cmd","/s","/c","ping -t localhost >null"]