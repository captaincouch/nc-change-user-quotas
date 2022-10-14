#!/bin/bash
# UpdateAllUserQuotas.sh
# Version: 1.0.0
# Written By: CaptCouch (captcouch@captcouch.xyz)
# Created On: Oct. 14 2022
# Last Modified: Oct. 14 2022
# Purpose: Update all Nextcloud user quotas based on an inputted parameter.
# Usage: ./UpdateAllUserQuotas.sh ([0-9]MB|[0-9]GB) [-d]

# Get the desired quota size from user parameter input.
quotasize=$1

# Evaluate and validate the user's input.
function evaluate_input {

    # If the user didn't provide a quota size, error and quit.
    if [ -z "$quotasize" ]
    then
        echo "ERROR 1: No quota size provided."; printf "\n"
        echo "Please provide a quota size."
        echo "Examples: ./UpdateAllUserQuotas.sh 10GB"
        echo "          ./UpdateAllUserQuotas.sh default"
        echo "          ./UpdateAllUserQuotas.sh unlimited"
        exit 1

    # Check the first character of $quotasize. See if it's a number.
    # If it's not, check to see if $quotasize is "default" or "unlimited."
    # If it's not, meaning the user provided either a not-number or not-"default/unlimited", error and quit.
    elif ! [[ ${quotasize::1} =~ ^[0-9] ]] && ! [[ ${quotasize} =~ ^(default|unlimited)$ ]]
    then
        echo "ERROR 2: Invalid quota size provided."
        echo "Provided Value: $quotasize"; printf "\n"
        echo "Please provide a valid quota size."
        echo "Examples: ./UpdateAllUserQuotas.sh 10GB"
        echo "          ./UpdateAllUserQuotas.sh default"
        echo "          ./UpdateAllUserQuotas.sh unlimited"
        exit 2

    # Check the last three characters of $quotasize and see if they end in "(number)GB" or "(number)MB".
    # If they don't, meaning the user did not provide GB/MB units or "default/unlimited", error and quit.
    elif ! [[ ${quotasize:0-3:3} =~ ^([0-9]GB|[0-9]MB)$ ]] && ! [[ ${quotasize} =~ ^(default|unlimited)$ ]]
    then
        echo "ERROR 3: Invalid size unit or no size unit provided."
        echo "Provided Value: $quotasize"; printf "\n"
        echo "Please provide the quota size in MB or GB."
        echo "Examples: ./UpdateAllUserQuotas.sh 10GB"
        echo "          ./UpdateAllUserQuotas.sh default"
        echo "          ./UpdateAllUserQuotas.sh unlimited"
        exit 3

    # Confirm the user's input.
    else
        # Report the provided quota size and expected result.
        echo "You provided a quota value of: $quotasize"
        echo -e "This would result in the quota for ALL users being set to $quotasize.\n"

        # Confirm that the user would like to continue or exit.
        while true; do
            read -p "Would you like to continue? (y/n): " yn
            case $yn in
                [Yy]* ) printf "\n"; break;;
                [Nn]* ) exit 0;;
                * ) echo -e "\nInvalid input. Please try again.\n";;
            esac
        done

        # If the user inputted a 0MB/0GB quota size, confirm that this is REALLY what they want.
        if [[ ${quotasize} =~ ^(0GB|0MB)$ ]]
        then
            echo "WARNING: This will set the quota for ALL USERS to ZERO!"
            echo -e "This will prevent users from being allowed to upload new files to Nextcloud.\n"

            while true; do
                read -p "Are you sure you would like to continue? (y/n): " yn
                case $yn in
                    [Yy]* ) break;;
                    [Nn]* ) exit 0;;
                    * ) echo -e "\nInvalid input. Please try again.\n";;
                esac
            done

            while true; do
                read -p "Are you REALLY, REALLY sure you would like to continue? (y/n): " yn
                case $yn in
                    [Yy]* ) echo -e "\nOkay, doing it. You have been warned.\n"; break;;
                    [Nn]* ) exit 0;;
                    * ) echo -e "\nInvalid input. Please try again.\n";;
                esac
            done
        fi
    fi

}

# Execute the desired changes to user quotas.
function change_quotas {

    # Export the list of users with OCC.
    # Use `apache` instead of `www-data` if your distro needs it.
    sudo -u www-data php /var/www/html/nextcloud/occ user:list --no-ansi --no-interaction | \

    # Pipe the OCC output to the below `while...do` loop.
    # The loop executes once per each user in the list.
    # The loop will execute while there are still list items to read.
    while read line
    do
        # Use `awk` to trim extra chars and tidy up the username.
        user=`awk -F: '{print $1}' <<< "${line}" | awk -F"- " '{print $2}'`;

        # Set the quota for the user.
        sudo -u www-data php /var/www/html/nextcloud/occ user:setting $user files quota $quotasize > /dev/null 2>&1;
        echo "Set quota for $user to $quotasize."
        
    done

}

# Perform a dryrun for debugging purposes.
function change_quotas_dryrun {

    # Export the list of users with OCC.
    # Use `apache` instead of `www-data` if your distro needs it.
    sudo -u www-data php /var/www/html/nextcloud/occ user:list --no-ansi --no-interaction | \

    # Pipe the OCC output to the below `while...do` loop.
    # The loop executes once per each user in the list.
    # The loop will execute while there are still list items to read.
    while read line
    do
        # Use `awk` to trim extra chars and tidy up the username.
        user=`awk -F: '{print $1}' <<< "${line}" | awk -F"- " '{print $2}'`;

        # Tell the user that the quota was set without actually setting the quota.
        echo "Set quota for $user to $quotasize."
        
    done

}

# function main {

evaluate_input

# If `-d` isn't passed for a dryrun, run normally.
if ! [[ $2 == "-d" ]]
then
    change_quotas
else
    change_quotas_dryrun
fi

#change_quotas
#change_quotas_dryrun

#}
