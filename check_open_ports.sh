#!/bin/bash

# Check if the input file is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <url_file>"
  exit 1
fi

URL_FILE=$1
OUTPUT_FILE="open_ports.csv"

# Check if the input file exists
if [ ! -f "$URL_FILE" ]; then
  echo "File not found: $URL_FILE"
  exit 1
fi

# Initialize the output CSV file
echo "IP,PORT" > $OUTPUT_FILE

# Function to extract the domain from a URL
extract_domain() {
  local url=$1
  local domain=$(echo $url | sed -E 's|https?://([^/]+).*|\1|')
  echo $domain
}

# Function to extract IP from nmap output
extract_ip() {
  local domain=$1
  local ip=$(nmap -sn $domain | grep "scan report" | awk '{print $5}')
  echo $ip
}

# Function to check if a URL is live
check_url_live() {
  local url=$1
  local response=$(curl -o /dev/null -s -w "%{http_code}\n" $url)
  if [[ "$response" -ge 200 && "$response" -lt 400 ]]; then
    echo "live"
  else
    echo "not_live"
  fi
}

# Loop through each URL in the file
while IFS= read -r url; do
  # Trim leading/trailing whitespace
  url=$(echo $url | xargs)
  
  # Skip empty lines
  if [ -z "$url" ]; then
    continue
  fi

  domain=$(extract_domain "$url")
  
  if [ -n "$domain" ]; then
    live_status=$(check_url_live "$url")
    
    if [ "$live_status" = "live" ]; then
      echo "Scanning $domain for open ports..."
      nmap_output=$(nmap -Pn $domain)
      ip=$(extract_ip "$domain")

      # Parse nmap output for open ports
      echo "$nmap_output" | grep "open" | while read -r line ; do
        port=$(echo $line | awk '{print $1}')
        echo "$ip,$port" >> $OUTPUT_FILE
      done
    else
      echo "URL is not live: $url"
    fi
  else
    echo "Invalid URL: $url"
  fi

done < "$URL_FILE"

echo "Port scanning completed. Results saved to $OUTPUT_FILE."
