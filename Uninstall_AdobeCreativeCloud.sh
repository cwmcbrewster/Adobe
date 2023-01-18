#!/bin/zsh

# uninstall adobe cc apps
# loosly based on: https://maclabs.jazzace.ca/2020/11/01/unistalling-adobe-apps.html
# and https://helpx.adobe.com/enterprise/admin-guide.html/enterprise/using/uninstall-creative-cloud-products.ug.html

uninstallDir="/Library/Application Support/Adobe/Uninstall"
setup="/Library/Application Support/Adobe/Adobe Desktop Common/HDBox/Setup"

function removeAdobeApps {

  if [[ -d "${uninstallDir}" ]] && [[ -f "${setup}" ]]; then
    adobeAppList=$(find "${uninstallDir}" -type f -maxdepth 1 -name "*.adbarg")

    for i in ${(f)adobeAppList}; do
      if [[ -f "${i}" ]]; then
        appName=$(echo "${i}" | awk -F "/" '{print $NF}' | cut -d "." -f 1)
        echo "Attempting to uninstall ${appName}"
        sapCode=$(grep -e "^--sapCode=" "${i}" | awk -F "=" '{print $2}')
        echo "sapCode: ${sapCode}"
        prodVer=$(grep -e "^--productVersion=" "${i}" | awk -F "=" '{print $2}')
        echo "prouctVersion: ${prodVer}"
        "${setup}" --uninstall=1 --sapCode="${sapCode}" --productVersion="${prodVer}" --platform=osx10-64 --deleteUserPreferences=false
      fi
    done

  else
    echo "No Adobe apps found to uninstall"
  fi

}

# Start

echo "Start first try..."
removeAdobeApps

echo "Start second try..."
removeAdobeApps

# Uninstall Acrobat DC 15
if [[ -f "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Helpers/Acrobat Uninstaller.app/Contents/MacOS/RemoverTool" ]]; then
  echo "Attempting to uninstall Acrobat DC 15"
  "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Helpers/Acrobat Uninstaller.app/Contents/MacOS/RemoverTool" "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Helpers/Acrobat Uninstaller.app/Contents/MacOS/RemoverTool" "/Applications/Adobe Acrobat DC/Adobe Acrobat.app"
 fi 

# Uninstall Acrobat DC 18+
if [[ -f "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Helpers/Acrobat Uninstaller.app/Contents/Library/LaunchServices/com.adobe.Acrobat.RemoverTool" ]]; then
  echo "Attempting to uninstall Acrobat DC"
  "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Helpers/Acrobat Uninstaller.app/Contents/Library/LaunchServices/com.adobe.Acrobat.RemoverTool" "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Helpers/Acrobat Uninstaller.app/Contents/MacOS/Acrobat Uninstaller" "/Applications/Adobe Acrobat DC/Adobe Acrobat.app"
fi

# Uninstall the Creative Cloud Desktop app
if [[ -f "/Applications/Utilities/Adobe Creative Cloud/Utils/Creative Cloud Uninstaller.app/Contents/MacOS/Creative Cloud Uninstaller" ]]; then
  echo "Attempting to uninstall Creative Cloud Desktop"
  "/Applications/Utilities/Adobe Creative Cloud/Utils/Creative Cloud Uninstaller.app/Contents/MacOS/Creative Cloud Uninstaller" -u
fi

exit 0
