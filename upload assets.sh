#!/bin/bash
# Define your Anypoint Platform login credentials and organization details
username="user"
password="pass"
organization="824821a1-2e2d-4087-93c8-dba3762e8838"
host="eu1.anypoint.mulesoft.com"


# Log in to Anypoint Platform
echo "Starting..."



# Navigate to the directory containing the cloned repository
cd Open_Api_And_Data_Model/apis
echo "Navigating to APIs directory..."

# Iterate over each API folder
for dir in */
do
    echo "Processing API directory: $dir"
    # Check if the swagger directory exists
    if [ -d "$dir"/swaggers ]; then
        # Navigate to the swagger folder of each API
        cd "$dir"/swaggers
        # Check if the directory has any JSON files
        if [ "$(ls *.json 2>/dev/null)" ]; then
            # Iterate over each swagger file in the directory
            for file in *.json
            do
                
                # Extract the version from the filename
                version="${file#*-v}"
                version="${version%.swagger.json}"

                # Extract the name from the filename
                name="${file%-v*}"

                # Set the description
                description="${file%-v*}"

                # Set the tag
                tag="TMF"

                # Extract the full_detail from the JSON file
                full_detail=$(jq -r '.info.description' "$file")

                # Truncate the full_detail to a maximum of 240 characters
                full_detail=$(echo $full_detail | cut -c 1-240)


                # Construct the assetIdentifier
                assetIdentifier="${organization}/${name}/${version}"

                echo "Publishing $name API: $file with version: $version and with assetIdentifier: $assetIdentifier"
                # Use the Anypoint CLI to publish the API to the exchange
                
                anypoint-cli-v4 exchange:asset:upload --host $host --username $username --password $password --organization $organization --name "$name" --description "$full_detail" --tags "$tag" --type "rest-api"   --properties='{"apiVersion":"'"$version"'", "mainFile": "'"$file"'"}' --files='{"oas.json":"'"$file"'"}' $assetIdentifier
                
            done
        else
            echo "No YAML files found in $dir/swaggers."
        fi
        # Navigate back to the main directory
        cd ../..
    else
        echo "Swagger directory does not exist for $dir. Skipping..."
    fi
done
echo "All APIs processed."

