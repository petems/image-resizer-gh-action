# img-resizer-inplace-limit

A GitHub action to resize your images within the folder they are if they are over a certain size limit

```yml
- name: Image Resizer Inplace Limit
  uses: petems/img-resizer-inplace@v1
  with:
    # Folder in which images are stored
    target: # default is images
    # New resolution for images
    dimensions: # default is 70%
    widthLimit: 1024 
    heightLimit: 768
```

This action uses `mogrify` at its core. To understand more about the tool and how to define dimensions read this [guide on mogrify](https://imagemagick.org/script/mogrify.php)

### Sample usage

Check out a sample of how to use this action - 

### Testing

#### Script

Run vagrant then run the script:

```
alpine:/vagrant# bash entrypoint.sh 1024 1800 ./images/ 50%
Width Limit: 1024
Height Limit: 1800
Given directory: ./images/
Image count in directory: 2
Image Name: ./images/cat.jpg
Image ./images/cat.jpg is not Oversized, no mogrify needed
Image Name: ./images/cat-over-1024.jpg
Image ./images/cat-over-1024.jpg is Oversized: 1310 x 983
mogrifying comand will be: mogrify -resize 50% ./images/cat-over-1024.jpg
mogrify complete, new size: 655 x 492
::set-output name=images_changed::\n./images/cat-over-1024.jpg - new size: 655 x 492
```