$outDirectory = ".\UZDoom\"
$tempDirectory = ".\temp\"
$tempFileName = "uzdoom.zip"
$repo = "uzdoom/uzdoom"
$fileToDate = "uzdoom.exe"
$assetNameRegex = "^Windows"

$includeDrafts = $false
$includePrerelease = $false

function Write-TwoCols {
  param (
    [string]$leftColText,
    [string]$rightColText,
    [int]$minTotalWidth,
    [System.ConsoleColor]$color
  )

  $lengths = $minTotalWidth, $leftColText.Length + $rightColText.Length + 1 | Measure-Object -Maximum

  $paddingAmount = $lengths.Maximum - $leftColText.Length
  
  Write-Host $leftColText $rightColText.PadLeft($paddingAmount) -ForegroundColor $color

}

function Perform-Upgrade {
  param (
    $asset,
    $tempDirectory,
    $outDirectory
  )

  # Setup variables
  $tempZipFile = Join-Path $tempDirectory $tempFileName;
  $expandedFilesDir = Join-Path $tempDirectory "latest";

  # Setup temp folder
  if ((Test-Path -Path $tempDirectory)) {
    Remove-Item -Path $tempDirectory -Recurse
  }
  [void](New-Item -Path $tempDirectory -ItemType "directory")

  # Download new zip
  Write-Host " Downloading..." -ForegroundColor Magenta
  $url = $asset.browser_download_url
  Invoke-WebRequest -Uri $url -OutFile $tempZipFile

  # Extract zip
  Write-Host " Extracting..." -ForegroundColor Magenta
  Expand-Archive $tempZipFile -DestinationPath $expandedFilesDir

  # Copy/Overwrite what is in the emulator folder
  Write-Host " Copying..." -ForegroundColor Magenta
  Copy-item -Force -Recurse $expandedFilesDir -Destination $outDirectory

  # Delete downloaded temp files when done to prep for next version
  Write-Host " Cleaning up..." -ForegroundColor Magenta
  Remove-Item -Path $tempDirectory -recurse

  Write-Host " DONE" -ForegroundColor Magenta
}

# Get latest release info
$jsonResponse = Invoke-RestMethod -Uri ("https://api.github.com/repos/" + $repo + "/releases")

# Find first valid response
$validRelease = ($jsonResponse | Where-Object { 
  ($_.draft -eq $false -or $includeDrafts -eq $true) -and
  ($_.prerelease -eq $false -or $includePrerelease -eq $true)
} | Select-Object -First 1)

$validAsset = ($validRelease.assets | Where-Object {
  $_.name -match $assetNameRegex
} | Select-Object -First 1)


# Get dates
$exeLastUpdatedDate = if (Test-Path (Join-Path $outDirectory $fileToDate)) {(Get-Item (Join-Path $outDirectory $fileToDate)).LastWriteTime} else {Get-Date -Date "1970-01-01 00:00:00Z"}
$lastReleaseDate = [datetime]$validAsset.updated_at

# Compare dates
Write-TwoCols " Local file date:" $exeLastUpdatedDate.Date.ToString("yyyyMMdd") 35 Green
Write-TwoCols " Latest release:" $lastReleaseDate.Date.ToString("yyyyMMdd") 35 Green

if ($lastReleaseDate.Date -gt $exeLastUpdatedDate.Date) {
  Write-Host " New version detected!"

  Perform-Upgrade $validAsset $tempDirectory $outDirectory
}
else {
  Write-Host "No new version detected"
}

# Read-Host -Prompt "Press Enter to exit"