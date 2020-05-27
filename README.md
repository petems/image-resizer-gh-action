# img-resizer-inplace

A GitHub action to resize your images within the folder they are.

```yml
- name: Image Resizer Inplace
  uses: xprilion/img-resizer-inplace@v1
  with:
    # Folder in which images are stored
    target: # default is images
    # New resolution for images
    dimensions: # default is 500x
```

This action uses `mogrify` at its core. To understand more about the tool and how to define dimensions read this [guide on mogrify](https://imagemagick.org/script/mogrify.php)

### Sample usage

Check out a sample of how to use this action - 

[here](https://github.com/dsc-x/dsc-x.github.io/blob/dev/.github/workflows/main.yml)
