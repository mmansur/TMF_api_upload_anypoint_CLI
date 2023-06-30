#!/bin/bash

# Function to split camel case into separate words
split_camel_case() {
    echo $1 | sed -r 's/([a-z])([A-Z])/\1 \2/g'
}


# Define your Anypoint Platform login credentials and organization details
username=""
password=""
organization="0adae3f1-99ef-4049-b776-874174fc88d1"
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

                # Generate a proper name for the sample
                beautiful_name=$(split_camel_case "$name")
                beautiful_name=$(echo "$beautiful_name" | sed 's/-/ - /')
                echo "Beautiful name: $beautiful_name"

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

                # Use the Anypoint CLI to publish the API to the exchange
                echo "Publishing the API to the exchange"
                echo "Publishing $name API: $file with version: $version and with assetIdentifier: $assetIdentifier"
                
                sleep 1
                anypoint-cli-v4 exchange:asset:upload --host $host --username $username --password $password --organization $organization --name "$beautiful_name" --description "$full_detail" --tags "$tag" --type "rest-api"   --properties='{"apiVersion":"'"$version"'", "mainFile": "'"$file"'"}' --files='{"oas.json":"'"$file"'"}' $assetIdentifier


                echo "$(pwd)"

                # Navigate to the "samples" subfolder and create a page for each sample file
                if [ -d "../samples" ]; then
                    cd "../samples"
                    for sample in *.example.json; do
                        # Generate a proper name for the sample
                        sample_name=${sample%%.example.json*}
                        sample_name=$(split_camel_case "$sample_name")
                        # Create a page for the sample in Anypoint Exchange
                        echo "Creating a page for the sample in Anypoint Exchange"
                        echo "Sample name $sample_name  Filename $sample"  
                        
                        sleep 1
                        anypoint-cli-v4 exchange:asset:page:upload --host $host --username $username --password $password --organization $organization $assetIdentifier "JSON Example $sample_name" $sample

                    done
                fi        
                echo "$(pwd)"
                cd ../swaggers
                echo "$(pwd)"

                # Navigate to the "documentation/diagrams" subfolder, upload each PNG file as a resource, and create a page for each resource
                if [ -d "../documentation/diagrams" ]; then
                    cd "../documentation/diagrams"
                    for diagram in *.png; do
                        # Extract the diagram name and format it
                        diagram_name=${diagram#Resource_}; diagram_name=${diagram_name%%.png}
                        readable_diagram=$(echo $diagram_name | sed -r 's/([a-z])([A-Z])/\1 \2/g')
                        readable_diagram=$(echo "$readable_diagram" | tr -d '%@*+/_\\')



                        echo "Resource name $readable_diagram"
                        # Upload the PNG file as a resource in Anypoint Exchange
                        
                        # Upload the diagram as a resource and capture the output
                        echo "Uploading the diagram as a resource and capture the output"
                        upload_output=$(anypoint-cli-v4 exchange:asset:resource:upload --host $host --username $username --password $password --organization $organization $assetIdentifier $diagram)

                        echo "Result from the resource upload: $upload_output"

                        # Extract the last line starting with "![Resource_Alarm]" from the output and store it in a variable
                        last_line=$(echo "$upload_output" | tail -n 1)
                        echo "Link to the resource: $last_line"

                        # Create a temporary file
                        temp_file=$(mktemp)

                        # Write the content of the variable "resource_markdown_code" to the temporary file
                        echo "$last_line" > "$temp_file"

                        # Print the name of the temporary file
                        echo "The temporary file is located at: $temp_file"

                        # Create a page for the resource in Anypoint Exchange
                        echo "Creating a page for the resource in Anypoint Exchange"
                        sleep 1
                        anypoint-cli-v4 exchange:asset:page:upload --host $host --username $username --password $password --organization $organization $assetIdentifier "Diagram $readable_diagram" $temp_file

                        # Delete the temporary file
                        rm "$temp_file"
                    done
                    cd ../../swaggers
                fi
                echo "$(pwd)"
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

