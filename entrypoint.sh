#!/bin/sh -l
limitWidth=$1
limitHeight=$2

echo "Width Limit: $1"
echo "Height Limit: $2"

echo "Changing to given directory: $3"
cd $3
for f in $FILES
do
  echo "Image Name: $f"
  imageWidth=$(identify -format "%w" "$f")
  imageHeight=$(identify -format "%h" "$f")

  if [ "$imageWidth" -gt "$limitWidth" ] || [ "$imageHeight" -gt "$limitHeight" ]; then
    mogrify -resize $4 $f
  fi
done