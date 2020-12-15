#! /bin/sh

# WE're only concerned with a days output that's an integer
# any other result, ie. minutes or seconds results in 0
# This allows us to create integer based smart groups ie. greater than/less than

timechk=`uptime | awk '{ print $4 }'`

# if result is minutes than we return 0 integer
if [ $timechk = "mins," ]; then
        timeup="0"

# if $4 is "days," then we pull just the integer of days
elif [ $timechk = "days," ]; then

                timeup=`uptime | awk '{ print $3 }'`

# otherwise, it will generate 0.
else

                timeup="0"

fi

echo "<result>$timeup</result>"