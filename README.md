# Image converter
A script using ffmpeg to convert images to jpg, preserving their original position
## Dependencies
### [ffmpeg](https://www.gyan.dev/ffmpeg/builds/)
`winget install "FFmpeg (Essentials Build)"`

**OR**

`choco install ffmpeg`
### [Powershell 7](https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
`winget install --id Microsoft.PowerShell --source winget`

**OR**

Download and run the installer found in [Powershell's MSI installers page](https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5#msi)
## Running the script
Open Powershell 7 in the directory containing the script and run the following command :
`pwsh -ExecutionPolicy Bypass -File .\convert_imgs.ps1 -root "[path to the folder containing the images]"`
> the root parameter supports relative paths
