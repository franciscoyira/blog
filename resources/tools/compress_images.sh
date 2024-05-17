#!/bin/bash

# Directory containing the images
dir="path"

# Loop through all PNG images in the directory
for img in "$dir"/*.png
do
  # Copy the original image adding the suffix _original.png
  cp "$img" "${img%.png}_original.png"

  # Get the image width
  width=$(identify -format "%w" "$img")

  # If the image width is greater than 1000px, resize it
  if [ "$width" -gt 1000 ]
  then
    convert "$img" -resize 1000x "${img}"
  fi

  # compress the image
  optipng -o6 "$img"
done