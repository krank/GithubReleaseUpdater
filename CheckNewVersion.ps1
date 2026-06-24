$tempFileName = "tmp.zip"
$tempDirectory = ".\temp\"

#TODO: Support for flattening; if the downloaded zip contains a single directory, move contents to tempdir and delete it

# READ CONFIG
#region Config

# Find the config file
$ConfigJsonFilename = ""
if (($args.Count -gt 0) -and (Test-Path $args[0])) {
  $ConfigJsonFilename = $args[0]
}
elseif ((Get-ChildItem *.json).Length -gt 0) {
  $ConfigJsonFilename = Get-ChildItem *.json | Select-Object -First 1
}
else {
  Write-Host "No config file found!"
  Exit
}

# Get the contents as JSON
$JSON = Get-Content $ConfigJsonFilename -Raw | ConvertFrom-Json

#endregion

# HELPER FUNCTIONS
#region Helper functions

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

#endregion

# UPDATE FUNCTIONS
#region Update functions

function DownloadAndExpandAsset {
  param (
    $asset
  )

  # Setup variables
  $tempZipFile = Join-Path $tempDirectory $tempFileName;
  $newFilesDirectory = Join-Path $tempDirectory "latest";

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
  Expand-Archive $tempZipFile -DestinationPath $newFilesDirectory
}

function CheckIfAssetIsNewer {
  param (
    $JSON,
    $validAsset
  )

  # Get dates
  $fileToDateFullpath = Join-Path $JSON.out_directory $JSON.file_to_date
  $exeLastUpdatedDate = if (Test-Path $fileToDateFullpath) { 
    (Get-Item $fileToDateFullpath).LastWriteTime 
  }
  else { 
    Get-Date -Date "1970-01-01 00:00:00Z" 
  }
  $lastReleaseDate = [datetime]$validAsset.updated_at

  # Compare dates
  Write-TwoCols " Local file date:" $exeLastUpdatedDate.Date.ToString("yyyyMMdd") 35 Green
  Write-TwoCols " Latest release:" $lastReleaseDate.Date.ToString("yyyyMMdd") 35 Green

  return $lastReleaseDate.Date -gt $exeLastUpdatedDate.Date

}

function MoveNewFilesToTargetDir {
  param (
    $JSON
  )
  $newFilesDirectory = Join-Path $tempDirectory "latest";

  # Copy/Overwrite what is in the target folder
  Write-Host " Copying..." -ForegroundColor Magenta
  Copy-item -Force -Recurse $newFilesDirectory -Destination $JSON.out_directory

  # Delete downloaded temp files when done to prep for next version
  Write-Host " Cleaning up..." -ForegroundColor Magenta
  Remove-Item -Path $tempDirectory -recurse

  Write-Host " DONE" -ForegroundColor Magenta
}

function Update {
  param (
    $JSON
  )

  Write-host ("Looking for updates to " + $JSON.name)

  # Get latest release info
  $jsonResponse = Invoke-RestMethod -Uri ("https://api.github.com/repos/" + $JSON.repo + "/releases")

  # Find first valid release & asset
  $validRelease = ($jsonResponse | Where-Object { 
      ($_.draft -eq $false -or $JSON.include_drafts -eq $true) -and
      ($_.prerelease -eq $false -or $JSON.include_prerelease -eq $true)
    } | Select-Object -First 1)

  $validAsset = ($validRelease.assets | Where-Object {
      $_.name -match $JSON.asset_name_regex
    } | Select-Object -First 1)

  if (-not $validAsset)
  {
    Write-Host " No valid asset found!"
    return
  }

  $IsNewer = CheckIfAssetIsNewer $JSON $validAsset

  if ($IsNewer) {
    Write-Host " New version detected!"

    DownloadAndExpandAsset $validAsset
    MoveNewFilesToTargetDir $JSON
  }
  else {
    Write-Host "No new version detected"
  }
}

#endregion



# MAIN SCRIPT
#region Main script

if ($JSON -is [Array]) {
  Write-Host "Multiple configs detected"

  foreach ($JSONsub in $JSON) {
    Update $JSONsub
  }

}
else {

  Write-Host "Single config detected"
  Update $JSON
}


Read-Host -Prompt "Press Enter to exit"

#endregion