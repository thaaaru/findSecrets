#!/bin/bash

# Function to check if a host is live
check_live_host() {
    local host=$1
    if ping -c 1 -W 1 "$host" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check OCSP status for a given URL
check_ocsp() {
    local url=$1
    local found_successful=0
    local timeout_duration=2
    
    for i in $(seq 1 40); do
        echo "Checking $url (Attempt $i/40)..."
        response=$(timeout $timeout_duration openssl s_client -connect "$url:443" -status < /dev/null 2>/dev/null | awk '/OCSP response:/,/^$/')
        
        if echo "$response" | grep -q "OCSP Response Status: successful"; then
            found_successful=1
            break
        fi
        
        sleep 1
    done
    
    if [ "$found_successful" -eq 1 ]; then
        echo "$url shows OCSP Response Status: successful"
    else
        echo "$url did not show a successful OCSP response within 40 attempts."
    fi
}

# Check if the input CSV file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

csv_file=$1

# Read URLs from CSV file and run the check_ocsp function if the host is live
while IFS=, read -r url; do
    if check_live_host "$url"; then
        echo "$url is live"
        check_ocsp "$url"
    else
        echo "$url is not reachable"
    fi
done < "$csv_file"
