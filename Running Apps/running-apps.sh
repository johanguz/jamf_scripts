#!/bin/sh

# Set the variables
proc=("$4")
runningProc=$(ps axc | grep -i "$proc" | awk '{print $1}')

#Check to see if parameter defined processes are running
    runningProc=$(ps axc | grep -i "$proc" | awk '{print $1}')
    if [[ $runningProc ]]; then
        echo "$proc is running with PID: ${runningProc}"
    else
         sudo jamf policy -action $5
    fi
done
