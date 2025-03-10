#!/bin/bash

# Directory containing the images
IMAGE_DIR="images"
# JSON file with image references
JSON_FILE="_data/talks.json"

# Create a backup of the JSON file
cp "$JSON_FILE" "${JSON_FILE}.bak"

# Function to convert a filename to lowercase with dashes
to_lowercase_dashed() {
  # Replace underscores with dashes, spaces with dashes, and convert to lowercase
  echo "$1" | sed 's/_/-/g' | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]'
}

# Process each image file
find "$IMAGE_DIR" -type f -not -name ".*" | while read -r file; do
  filename=$(basename "$file")
  extension="${filename##*.}"
  basename="${filename%.*}"
  
  # Skip if already in the correct format (all lowercase with dashes)
  if [[ "$filename" == "$(to_lowercase_dashed "$filename")" ]]; then
    echo "Skipping $filename (already in correct format)"
    continue
  fi
  
  # Generate the new filename
  new_basename=$(to_lowercase_dashed "$basename")
  new_filename="${new_basename}.${extension}"
  new_path="$IMAGE_DIR/$new_filename"
  
  # Check if the new filename already exists
  if [[ -f "$new_path" ]]; then
    echo "Warning: $new_path already exists, skipping rename of $file"
    continue
  fi
  
  echo "Renaming: $filename -> $new_filename"
  
  # Rename the file
  mv "$file" "$new_path"
  
  # Generate sed command to update references in the JSON file
  old_path="/images/$filename"
  new_path="/images/$new_filename"
  
  # Update the JSON file
  sed -i '' "s|$old_path|$new_path|g" "$JSON_FILE"
  
  echo "Updated references in $JSON_FILE: $old_path -> $new_path"
  
  # Also check for references in _posts directory
  grep -l "$old_path" _posts/*.md 2>/dev/null | while read -r post_file; do
    sed -i '' "s|$old_path|$new_path|g" "$post_file"
    echo "Updated references in $post_file: $old_path -> $new_path"
  done
done

echo "Image renaming and reference updates completed!"
echo "A backup of the original JSON file was saved as ${JSON_FILE}.bak" 