#!/bin/zsh

# Automatically download and install the latest Acrobat Reader

# Variables
#currentVersion=$(curl -LSs "https://get.adobe.com/reader" | grep "id=\"buttonDownload1\"" | awk -F '\\?installer=' '{print $NF}' | awk -F "Reader_DC" '{print $NF}' | awk -F "_" '{print $2}' | sed 's/\.//g')
currentVersion=$(curl -LSs "https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/acrobat/current_version.txt" | sed 's/\.//g')
currentVersionShort=${currentVersion: -10}
appName="Adobe Acrobat Reader.app"
appPath="/Applications/${appName}"
appProcessName="AdobeReader"
dmgName="AcroRdrDC_${currentVersionShort}_MUI.dmg"
dmgVolumePath="/Volumes/AcroRdrDC_${currentVersionShort}_MUI"
downloadUrl="https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${currentVersionShort}"
pkgName="AcroRdrDC_${currentVersionShort}_MUI.pkg"

cleanup () {
  if [[ -f "${tmpDir}/${dmgName}" ]]; then
    if rm -f "${tmpDir}/${dmgName}"; then
      echo "Removed file ${tmpDir}/${dmgName}"
    fi
  fi
  if [[ -d "${tmpDir}" ]]; then
    if rm -R "${tmpDir}"; then
      echo "Removed directory ${tmpDir}"
    fi
  fi
  if [[ -d "${dmgVolumePath}" ]]; then
    if hdiutil detach "${dmgVolumePath}" -quiet; then
      echo "Unmounted DMG"
    fi
  fi
}

createTmpDir () {
  if [ -z ${tmpDir+x} ]; then
    tmpDir=$(mktemp -d)
    echo "Temp dir set to ${tmpDir}"
  fi
}

processCheck () {
  if pgrep -x "${appProcessName}" > /dev/null; then
    echo "${appProcessName} is currently running"
    echo "Aborting install"
    cleanup
    exit 0
  else
    echo "${appProcessName} not currently running"
  fi
}

tryDownload () {
  if curl -Ss "${downloadUrl}/${dmgName}" -o "${tmpDir}/${dmgName}"; then
    echo "Download successful"
    tryDownloadState=1
  else
    echo "Download unsuccessful"
    tryDownloadCounter=$((tryDownloadCounter+1))
  fi
}

versionCheck () {
  if [[ -d "${appPath}" ]]; then
    echo "${appName} version is $(defaults read "${appPath}/Contents/Info.plist" CFBundleShortVersionString)"
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

# List version
versionCheck

# Download dmg file into tmp dir (60 second timeout)
echo "Starting download"
tryDownloadState=0
tryDownloadCounter=0
while [[ ${tryDownloadState} -eq 0 && ${tryDownloadCounter} -le 60 ]]; do
  processCheck
  createTmpDir
  tryDownload
  sleep 1
done

# Check for successful download
if [[ ! -f "${tmpDir}/${dmgName}" ]]; then
  echo "Download unsuccessful"
  cleanup
  exit 1
fi

# Mount dmg file
if hdiutil attach "${tmpDir}/${dmgName}" -nobrowse -quiet; then
  echo "Mounted DMG"
else
  echo "Failed to mount DMG"
  cleanup
  exit 1
fi

# Check for expected dmg path
if [[ ! -d "${dmgVolumePath}" ]]; then
  echo "Could not locate ${dmgVolumePath}"
  cleanup
  exit 1
fi

# Install package
echo "Starting install"
installer -pkg "${dmgVolumePath}/${pkgName}" -target /

# Remove tmp dir and downloaded dmg file
cleanup

# List version and exit with error code if not found
versionCheck
if [[ ${versionCheckStatus} -eq 0 ]]; then
  exit 1
fi
