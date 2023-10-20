#!/bin/bash

fetch_and_store_data() {
    json_url="https://earthview.withgoogle.com/_api/photos.json"
    response=$(curl -s "$json_url")

    if [ $? -eq 0 ]; then
        echo "$response" > "photoData.json"
        echo "Data fetched and stored successfully."
    else
        echo "Failed to retrieve JSON data. Status code: $?"
    fi
}

fetch_and_store_data
