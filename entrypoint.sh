#!/bin/sh -l
minimumWidth=$1
minimumHeight=$2

cd $3
for f in $files
do
  imageWidth=$(identify -format "%w" "$f")
  imageHeight=$(identify -format "%h" "$f")

  if [ "$imageWidth" -gt "$minimumWidth" ] || [ "$imageHeight" -gt "$minimumHeight" ]; then
      mogrify -resize $4 $f
  fi
done