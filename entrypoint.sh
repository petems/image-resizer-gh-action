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

imagecount=$(find $3 -regextype posix-extended -regex '.*\.(jpg|png|jpeg|gif)' | wc -l)

echo "Image count in directory: $imagecount"

if [ "$imagecount" -eq "0" ]; then
   echo "No images found in $3";
   exit 1;
fi

imagearray=($(find $3 -regextype posix-extended -regex '.*\.(jpg|png|jpeg|gif)'))

roughOutput=""
changedCount=0

for f in ${imagearray[@]}; do
  echo "Image Name: $f"
  imageWidth=$(identify -format "%w" "$f")
  imageHeight=$(identify -format "%h" "$f")

  if [ "$imageWidth" -gt "$limitWidth" ] || [ "$imageHeight" -gt "$limitHeight" ]; then
    echo "Image $f is Oversized: $imageWidth x $imageHeight"
    echo "mogrifying comand will be: mogrify -resize $4 $f"
    mogrify -resize $4 $f
    newimageWidth=$(identify -format "%w" "$f")
    newimageHeight=$(identify -format "%h" "$f")
    echo "mogrify complete, new size: $newimageWidth x $newimageHeight"
    roughOutput="${roughOutput}<br />${f} - old size: $imageWidth x $imageHeight, new size: $newimageWidth x $newimageHeight"
    changedCount=$((changedCount+1))
  else
    echo "Image $f is not Oversized, no mogrify needed"
  fi
done

if [ "$changedCount" -gt 0 ]; then
  echo "::set-output name=images_changed::${roughOutput}"
else
  echo "::set-output name=images_changed::'No Images Changed'"
fi
