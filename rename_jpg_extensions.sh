#!/bin/bash

# Directory containing the images
IMAGE_DIR="images"
# JSON file with image references
JSON_FILE="_data/talks.json"

# Create a backup of the JSON file
cp "$JSON_FILE" "${JSON_FILE}.bak2"

# Process each JPG file
find "$IMAGE_DIR" -type f -name "*.JPG" | while read -r file; do
  filename=$(basename "$file")
  dirname=$(dirname "$file")
  new_filename="${filename%.JPG}.jpg"
  new_path="$dirname/$new_filename"
  
  echo "Renaming: $filename -> $new_filename"
  
  # Rename the file
  mv "$file" "$new_path"
  
  # Generate sed command to update references in the JSON file
  old_path="/images/${filename}"
  new_path="/images/${new_filename}"
  
  # Update the JSON file
  sed -i '' "s|$old_path|$new_path|g" "$JSON_FILE"
  
  echo "Updated references in $JSON_FILE: $old_path -> $new_path"
  
  # Also check for references in _posts directory
  grep -l "$old_path" _posts/*.md 2>/dev/null | while read -r post_file; do
    sed -i '' "s|$old_path|$new_path|g" "$post_file"
    echo "Updated references in $post_file: $old_path -> $new_path"
  done
done

echo "JPG extension renaming and reference updates completed!"
echo "A backup of the original JSON file was saved as ${JSON_FILE}.bak2" 