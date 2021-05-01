#!/bin/bash
# Written by Johan Guzman
# This script can be deployed via Self Service and will lookup mobile device information when provided with Asset Tag inputted by User

#Define Script Variables
# Credentials should be in base64
credentials=""
jamfProURL=""
finalMessage="/tmp/finalMessage.txt"
deviceData="/tmp/deviceInfo.csv"
searchResults="/Users/Shared/Search Results.txt"

#Get Asset Tag from User
assetTagUserInput=$(/usr/bin/osascript << AppleScript
tell application "System Events" to text returned of (display dialog "Please enter the Mobile Device's Asset Tag" default answer "#####" buttons {"OK"} default button 1 with icon {"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.ipod-touch.icns"})
AppleScript
)


/bin/cat > /tmp/stylesheet.xslt << EOF
<?xml version="1.0" encoding="UTF-8"?> 
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"> 
<xsl:output method="text"/> 
<xsl:template match="/mobile_devices"> 
<xsl:for-each select="mobile_device"> 
<xsl:value-of select="id"/> 
<xsl:text>,</xsl:text> 
<xsl:value-of select="username"/> 
<xsl:text>,</xsl:text> 
<xsl:value-of select="building"/> 
<xsl:text>,</xsl:text> 
<xsl:value-of select="department"/> 
<xsl:text>&#xa;</xsl:text> 
</xsl:for-each> 
</xsl:template> 
</xsl:stylesheet> 
EOF

#Create CSV With this info
/usr/bin/curl -s -X GET -H "Accept: text/xml" -H "Authorization: Basic $credentials" "$jamfProURL/JSSResource/mobiledevices/match/$assetTagUserInput" | /usr/bin/xsltproc /tmp/stylesheet.xslt - > $deviceData

#Generate Final Message 

numberOfAssetTagsFound=$(/usr/bin/curl -s -X GET -H "Accept: text/xml" -H "Authorization: Basic $credentials" "$jamfProURL/JSSResource/mobiledevices/match/$assetTagUserInput" | /usr/bin/xmllint --xpath '/mobile_devices/size/text()' -)

echo "There were $numberOfAssetTagsFound users found, they are as follows:" > $finalMessage

IFS=,

while read id username building department
do
	echo "$username in the $department department, they can be found in the $building building"
done < $deviceData >> $finalMessage

#Display results and allow user to export results

finalPrompt=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper\
	-windowType hud\
	-description "$(/bin/cat $finalMessage). Would you like to Output these results to '/Users/Shared/Search Results.txt'?"\
	-button1 "Yes"\
	-button2 "No")

if [[ "$finalPrompt" -eq 0 ]]
then
	echo "$(/bin/cat $finalMessage)" > $searchResults
fi

#Clean up files and allow users to delete search results
/bin/rm -rf $finalMessage
/bin/rm -rf $deviceData 
if [[ -f $searchResults ]]
then
/bin/chmod 755 $searchResults
fi
