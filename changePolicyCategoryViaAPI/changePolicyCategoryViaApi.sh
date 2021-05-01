#!/bin/bash
## Script written by Johan Guzman can be tweaked to find policies that meet criteria and their categories or any other setting changed.
# As an example this will find Disabled/enabled policies and assign them a category based on this.

#First Some Logistics
#Check if we have location to store script if not create the location in /usr/local

if [[ ! -d /usr/local/changeCategory ]]
then
	/bin/mkdir -p /usr/local/changeCategory
fi

#Check if script already exists if it doesn't tee out the script

if [[ ! -f /usr/local/changeCategory/policyCategories.sh ]]
then
	/usr/bin/tee /usr/local/changeCategory/policyCategories.sh  << "adminScript"
#!/bin/bash

# Update credentials (base64) and JamfPRO Url in script
credentials=""
jamfProURL=""

#Policy Not Enabled Portion/ finds disabled policies and adds them to category "Disabled Policies"
# You must obtain the category id from your JAMF instance and tweak the put command below
#Get all Policy IDs
policyIDX=$(/usr/bin/curl -s -H "Authorization: Basic $credentials" -H "accept: text/xml" "$jamfProURL/JSSResource/policies" -X GET | /usr/bin/xmllint --format -| awk -F '[<>]' '/<id>/{print $3}')

for policyID in $policyIDX
do 
	dirtyPolicyRecord=$(/usr/bin/curl -s -H "Authorization: Basic $credentials" -H "Accept: text/xml" -X GET "$jamfProURL/JSSResource/policies/id/$policyID")
	enabledStatus=$(echo $dirtyPolicyRecord | /usr/bin/xmllint --xpath '/policy/general/enabled/text()' -)
	if [[ $enabledStatus =~ false ]]
	then 
	/usr/bin/curl -H "Authorization: Basic $credentials" -H "Content-Type: application/xml" "$jamfProURL/JSSResource/policies/id/$policyID" -X PUT -d '<policy><general><category><id>5</id></category></general></policy>' 	
	fi
done 


#Policy Enable and scoped to All computers Portion/ finds enabled policies and adds them to a category "Enabled Policies"
# You must obtain the category id from your JAMF instance and tweak the put command below
#Get all Policy IDs
policyIdxScope=$(/usr/bin/curl -s -H "Authorization: Basic $credentials" -H "accept: text/xml" "$jamfProURL/JSSResource/policies" -X GET | /usr/bin/xmllint --format -| awk -F '[<>]' '/<id>/{print $3}')

for policyID in $policyIdxScope
do 
	dirtyPolicyRecordScope=$(/usr/bin/curl -s -H "Authorization: Basic $credentials" -H "Accept: text/xml" -X GET "$jamfProURL/JSSResource/policies/id/$policyID")
	enabledStatusScope=$(echo $dirtyPolicyRecordScope | /usr/bin/xmllint --xpath '/policy/general/enabled/text()' -)
	scopedToAllStatus=$(echo $dirtyPolicyRecordScope | /usr/bin/xmllint --xpath '/policy/scope/all_computers/text()' -)
	
	if [[ ("$enabledStatusScope" =~ true) && ("$scopedToAllStatus" =~ true) ]]
	then 
		/usr/bin/curl -H "Authorization: Basic $credentials" -H "Content-Type: application/xml" "$jamfProURL/JSSResource/policies/id/$policyID" -X PUT -d '<policy><general><category><id>6</id></category></general></policy>' 	
	fi
done 
adminScript
	
fi

# fix script permissions
/usr/sbin/chown root:wheel /usr/local/changeCategory/policyCategories.sh
/bin/chmod +x /usr/local/changeCategory/policyCategories.sh



#CREATING LaunchDaemon Task

# Ignore if the LaunchDaemon already exists
if [[ -f /Library/LaunchDaemons/com.changeCategory.policyCategories.plist ]]
then
	echo "LaunchDaemon already present"
else 
	# Writeout the File using tee
	/usr/bin/tee /Library/LaunchDaemons/com.changeCategory.policyCategories.plist << LaunchDaemon
<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict> 
	<key>Label</key> 
	<string>com.changeCategory.policyCategories</string> 
	<key>ProgramArguments</key> 
	<array> 
		<string>/usr/local/changeCategory/policyCategories.sh</string> 
	</array> 
	<key>StartCalendarInterval</key>
	<dict>
		<key>Hour</key>
		<integer>21</integer>
		<key>Minute</key>
		<integer>15</integer>
	</dict>
</dict> 
</plist>

LaunchDaemon
	
	#  Check permissions & Load the file
	/bin/chmod 644 /Library/LaunchDaemons/com.changeCategory.policyCategories.plist
	/usr/sbin/chown root:wheel /Library/LaunchDaemons/com.changeCategory.policyCategories.plist
	/bin/launchctl bootstrap system /Library/LaunchDaemons/com.changeCategory.policyCategories.plist
	
fi