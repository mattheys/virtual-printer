#!/bin/bash

FILE_PATH="$1"

if [ -f "$FILE_PATH" ]; then
    # Extract the directory and the filename without the .pdf extension
    DIR=$(dirname "$FILE_PATH")
    BASENAME=$(basename "$FILE_PATH" .pdf)
    
    # Generate the timestamp (Format: YYYY-MM-DD_HH-MM-SS)
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    
    # Construct the new path and rename the file
    NEW_PATH="${DIR}/${BASENAME}_${TIMESTAMP}.pdf"
    mv "$FILE_PATH" "$NEW_PATH"
fi
