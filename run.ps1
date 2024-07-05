# Define the URL and file path
$url = "https://store4.gofile.io/download/web/0c13270e-b6bf-414b-8096-6f4f7b0f4da7/Adobe.iso"
$filePath = "C:\Path\To\Download\Adobe.iso"

# Download the ISO file
Invoke-WebRequest -Uri $url -OutFile $filePath

# Mount the ISO file
Mount-DiskImage -ImagePath $filePath

# Get the drive letter of the mounted ISO
$driveLetter = (Get-DiskImage -ImagePath $filePath | Get-Volume).DriveLetter

# Run the setup silently
Start-Process -FilePath "$($driveLetter):\Adobe Acrobat Pro\Setup.exe" -ArgumentList "/s" -Wait

# Run the crack file (not silently)
Start-Process -FilePath "$($driveLetter):\Adobe Acrobat Pro\crack.exe" -Wait

# Dismount the ISO file
Dismount-DiskImage -ImagePath $filePath

# Optionally, remove the ISO file after installation
Remove-Item -Path $filePath
