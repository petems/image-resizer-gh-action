#!/bin/sh -l
limitWidth=$1
limitHeight=$2

echo "Width Limit: $1"
echo "Height Limit: $2"
echo "Given directory: $3"

imagecount=$(find -E $3 -regex '.*\.(jpg|png|jpeg|gif)' | wc -l)

echo "Image count in directory: $imagecount"

if [ "$imagecount" -eq "0" ]; then
   echo "No images found in $3";
   exit 1;
fi

imagearray=($(find -E $3 -regex '.*\.(jpg|png|jpeg|gif)'))

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
    images_changed="$images_changed" + " $f"
  else 
    echo "Image $f is not Oversized, no mogrify needed"
  fi
done