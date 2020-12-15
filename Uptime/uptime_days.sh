#! /bin/sh

# WE're only concerned with a days output that's an integer
# if $4 from `uptime` is "mins," then the system has been up for less than an hour. 
# We set $timeup to the output of $3, appending only "m".
timechk=`uptime | awk '{ print $4 }'`

# if result is minutes than we return 0 integer
if [ $timechk = "mins," ]; then
        timeup="0"

# if $4 is "days," then we pull just the integer of days
elif [ $timechk = "days," ]; then

                timeup=`uptime | awk '{ print $3 }'`

# otherwise, probably seconds ago so it will generate 0.
else

                timeup="0"

fi

echo "<result>$timeup</result>"