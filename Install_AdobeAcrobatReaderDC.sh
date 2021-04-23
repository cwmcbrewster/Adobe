#!/bin/bash

# Automatically download and install the latest Acrobat Reader DC

# Variables
currentVersion=$(curl -LSs "https://get.adobe.com/reader" | grep "id=\"buttonDownload1\"" | awk -F '\\?installer=' '{print $NF}' | awk -F "Reader_DC" '{print $NF}' | awk -F "_" '{print $2}' | sed 's/\.//g')
#currentVersion=$(curl -LSs "https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/acrobat/current_version.txt" | sed 's/\.//g')
currentVersionShort=${currentVersion: -10}
appName="Adobe Acrobat Reader DC.app"
appProcessName="AdobeReader"
dmgName="AcroRdrDC_${currentVersionShort}_MUI.dmg"
dmgVolumePath="/Volumes/AcroRdrDC_${currentVersionShort}_MUI"
downloadUrl="https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${currentVersionShort}"
pkgName="AcroRdrDC_${currentVersionShort}_MUI.pkg"

processCheck () {
  if [[ -n $(pgrep -x "${appProcessName}") ]]; then
    echo "${appProcessName} is currently running"
    echo "Aborting install"
    exit 0
  else
    echo "${appProcessName} not currently running"
  fi
}

tryDownload () {
  curl -LSs "${downloadUrl}/${dmgName}" -o "${tmpDir}/${dmgName}"
  if [[ $? -eq 0 ]]; then
    echo "Download successful"
    tryDownloadState=1
  else
    echo "Download unsuccessful"
    tryDownloadCounter=$((tryDownloadCounter+1))
  fi
}

versionCheck () {
  appPath="/Applications/${appName}"

  if [[ -d "${appPath}" ]]; then
    echo "${appName} version is $(defaults read "${appPath}"/Contents/Info.plist CFBundleShortVersionString)"
    versionCheckStatus=1
  else
    echo "${appName} not installed"
    versionCheckStatus=0
  fi
}

# Start

# Validate currentVersion variable contains 10 digits.
echo "Current version: ${currentVersionShort}"
if [[ ! ${currentVersionShort} =~ ^[0-9]{10}$ ]]; then
  echo "Current version does not appear to match the 10 digit format expected"
  exit 1
fi

tmpDir=$(mktemp -d)
echo "Temp dir set to ${tmpDir}"

# List version
versionCheck

# Download DMG file into tmpDir (60 second timeout)
echo "Starting download"
tryDownloadState=0
tryDownloadCounter=0
while [[ ${tryDownloadState} -eq 0 && ${tryDownloadCounter} -le 60 ]]; do
  processCheck
  tryDownload
  sleep 1
done

# Check for successful download
if [[ ! -f "${tmpDir}/${dmgName}" ]]; then
    echo "Download failed"
    exit 1
fi

# Mount DMG File
hdiutil attach "${tmpDir}/${dmgName}" -nobrowse

# Install package
echo "Starting install"
installer -pkg "${dmgVolumePath}/${pkgName}" -target /

# Unmount DMG file
hdiutil detach "${dmgVolumePath}"

# Remove downloaded DMG file
rm -f "${tmpDir}/${dmgName}"

# List version and exit with error code if not found
versionCheck
if [[ ${versionCheckStatus} -eq 0 ]]; then
  exit 1
fi
