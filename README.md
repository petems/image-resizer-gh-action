# img-resizer-inplace

A GitHub action to resize your images within the folder they are.

```yml
- name: Image Resizer Inplace
  uses: xprilion/img-resizer@v1
  with:
    # Folder in which images are stored
    target: # default is images
    # New resolution for images
    dimensions: # default is 500x
```

### Sample usage

Check out a sample of how to use this action - 

[here](https://github.com/dsc-x/dsc-x.github.io/blob/dev/.github/workflows/main.yml)
