#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
  echo "Please provide all variables"
  exit 1;
fi

limitWidth=$1
limitHeight=$2
imagesdir=$3
resizeparam=$4

echo "Width Limit: $1"
echo "Height Limit: $2"
echo "Given directory: $3"

imagecount=$(find "$imagesdir" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | wc -l | tr -d ' ')

if [ -d "$imagesdir" ]; then
  true
else
  echo "Error: ${imagesdir} does not exist"
  exit 1
fi

echo "Image count in directory: $imagecount"

if [ "$imagecount" -eq "0" ]; then
   echo "No images found in $imagesdir";
   exit 1;
fi

imagearray=()
while IFS= read -r file; do
  imagearray+=("$file")
done < <(find "$imagesdir" -name "*.jpg" -o -name "*.jpeg" -o -name "*.png")



roughOutput=""
csvOutput="Image path, Old size, New size"
changedCount=0

for f in "${imagearray[@]}"; do
  echo "Image Name: $f"
  imageWidth=$(identify -format "%w" "$f")
  imageHeight=$(identify -format "%h" "$f")

  if [ "$imageWidth" -gt "$limitWidth" ] || [ "$imageHeight" -gt "$limitHeight" ]; then
    echo "Image $f is Oversized: $imageWidth x $imageHeight"
    echo "mogrifying comand will be: mogrify -resize $resizeparam $f"
    mogrify -resize "$resizeparam" "$f"
    newimageWidth=$(identify -format "%w" "$f")
    newimageHeight=$(identify -format "%h" "$f")
    echo "mogrify complete, new size: $newimageWidth x $newimageHeight"
    roughOutput="${roughOutput}<br />${f} - old size: $imageWidth x $imageHeight, new size: $newimageWidth x $newimageHeight"
    csvOutput="${csvOutput}\n${f}, $imageWidth x $imageHeight, $newimageWidth x $newimageHeight"
    changedCount=$((changedCount+1))
  else
    echo "Image $f is not Oversized, no mogrify needed"
  fi
done

if [ "$changedCount" -gt 0 ]; then
  echo "images_changed=${roughOutput}" >> "$GITHUB_OUTPUT"
else
  echo "images_changed='No Images Changed'" >> "$GITHUB_OUTPUT"
fi

# Workaround until https://github.community/t/set-output-truncates-multiline-strings/16852/7#M8539 is resolved
csvOutput=$(echo -e "$csvOutput)")
csvOutput="${csvOutput//'%'/'%25'}"
csvOutput="${csvOutput//$'\n'/'%0A'}"
csvOutput="${csvOutput//$'\r'/'%0D'}"

echo "csv_images_changed=${csvOutput}" >> "$GITHUB_OUTPUT"
