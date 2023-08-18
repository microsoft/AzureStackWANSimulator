#!/bin/sh

# Generate pre-defined profile testing results.
## 1. Define a template function
## 2. Define common profiles
## 3. Output standard result with detail log files

function valid_ip()
{
    # From https://www.linuxjournal.com/content/validating-ip-address-bash-script
	local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}