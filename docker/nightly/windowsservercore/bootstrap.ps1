# This is intended to be used inside Docker containers

[string]$LogFile = $Env:SystemDrive + '\' + ($MyInvocation.MyCommand.Name.ToString()) + ".log"
Start-Transcript -path $LogFile -append -IncludeInvocationHeader
$PSVersionTable | Write-Output
$BuildString = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").BuildLabEx 
$EditionId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID').EditionId
$BuildInfo = $BuildString.ToLower().Split(".")
$Ver = $BuildInfo[0]
$SubVer = $BuildInfo[1]
$Flavor = $BuildInfo[2]
  $FlavorType=$Flavor.ToCharArray()|select -last 3;$FlavorType=-join $FlavorType
  $FlavorArch=$Flavor.TrimEnd($FlavorType)
$BuildDate = $BuildInfo[4]
$Branch = $BuildInfo[3]
$FullVer = "$Ver.$SubVer.$BuildDate"
Write-Host ('BuildString='+$BuildString)
Set-Variable -Name $ErrorActionPreference -Value 'Stop'
Set-Variable -Name $DebugPreference -Value 'Continue'
Set-Variable -Name $VerbosePreference -Value 'Continue'

#Install Git
Invoke-WebRequest -Uri $Env:Git7zip -OutFile C:\Git64_7z.exe -UseBasicParsing
if ((Get-FileHash C:\Git64_7z.exe -Algorithm sha256).Hash -ne $env:GitSha256) {Throw "SHA256 mismatch!"} 
Start-Process -FilePath C:\Git64_7z.exe -ArgumentList '-y -gm2 -om2 -sd1 -InstallPath="C:\Git"' -Wait
$mPath=Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'|Select Path -ExpandProperty Path
$mPath='C:\Git\cmd;'+$mPath
setx /m Path "$mPath"
$Env:Path+=';C:\Git\cmd'

#Prepare shell environment
[ScriptBlock]$ProfileScript={
  function Prompt {"[$env:COMPUTERNAME] PS "+$(Get-Location)+"> "}
  $ConfirmPreference='None'
  $env:chocolateyUseWindowsCompression = 'false'
  write-verbose ($Profile+' loaded.')
} 
Write-output $ProfileScript | out-file (New-Item -Path $PROFILE -ItemType File -Force).FullName
. $profile

#Install Chocolatey
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force 
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted 
Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) 

#Build PS
git clone --recursive https://github.com/$Env:fork/PowerShell.git -b $Env:branch
Set-Location C:\PowerShell
Import-Module ./build.psm1
try {
  Start-PSBootstrap
} catch {
  get-item "${env:ProgramFiles(x86)}\Windows Kits\10\bin\x64\mc.exe" -ea ignore
  choco install microsoft-build-tools -y
  get-item -Path ($env:ProgramFiles(x86)+"\Windows Kits\10\bin\x64\mc.exe")
  $vcVarsPath = (Get-Item(Join-Path -Path "$env:VS140COMNTOOLS" -ChildPath '../../vc')).FullName
  get-item -Path $vcVarsPath\vcvarsall.bat
  Start-PSBootstrap
}
Start-PSBuild -Clean -CrossGen -Runtime win10-x64 -Configuration Release
Start-PSPackage -Type msi

#Cleanup
Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted 