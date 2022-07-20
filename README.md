# img-resizer-inplace-limit

A GitHub action to resize your images within a given folder they are if they are over a certain size limit

```yml
- name: Resize images above 1024 width
  id: resize-images
  uses: petems/image-resizer-gh-action@master
  with:
    target: images/ # directory to look for images in
    dimensions: 70% # parameter to change size, passed to mogrify as ``
    widthLimit: 1024 # max width to check
    heightLimit: 768 # max height to check
```

This action uses `mogrify` at its core for resizing. 

To understand more about the tool and how to define dimensions read this [guide on mogrify](https://imagemagick.org/script/mogrify.php)

### Resize paremeter

The `dimensions` parameter is passed to the command line for the [resize cli option for mogrify](https://imagemagick.org/script/command-line-options.php#resize).

Some examples:

> * -resize '200%' bigWiz.png
> * -resize '200x50%' longShortWiz.png
> * -resize '100x200' notThinWiz.png
> * -resize '100x200^' biggerNotThinWiz.png
> * -resize '100x200!' dochThinWiz.png


### Sample usage

Since Github actions can be built together, you could put several steps together to do the following:

* Resize images on pull-request above 1024 width and 768 height
* Reduce them to 90%
* Commit them to the PR 
* Comment on the PR with the resizing changes:

```yaml
name: Resize images

on:
  pull_request:
    paths:
      - 'images/**.jpg'
      - 'images/**.jpeg'
      - 'images/**.png'

jobs:
  build:
    name: Image Resizer Inplace Limit
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repo
        uses: actions/checkout@master

      - name: Compress Images
        id: resize-images
        uses: petems/image-resizer-gh-action@master
        with:
          target: images/ # directory to look for images in
          dimensions: 90% # parameter to change size
          widthLimit: 1024 # max width to check
          heightLimit: 768 # max height to check
      - name: Commit changes
        uses: EndBug/add-and-commit@v4
        with:
          add: 'images/'
          author_name: "github-actions[bot]"
          author_email: "github-actions@users.noreply.github.com"
          message: |
            Images Reszied by Github action\n
            ```
            ${{steps.resize-images.outputs.images_changed}}
            ```
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - uses: mshick/add-pr-comment@v1
        with:
          message: |
            **Hello, I resized images for you!**:
            ${{steps.csv-table-output.outputs.images_changed}}
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          repo-token-user-login: 'github-actions[bot]' # The user.login for temporary GitHub tokens
          allow-repeats: true
```

You should then see something like this:

![PR Comment](https://user-images.githubusercontent.com/1064715/93666213-34f76400-fa74-11ea-8baa-5ca35636e923.png)

I also made a Github action to convert CSV into markdown, so you can take the CSV output and post it to the pull-request as a Markdown table:

```yaml
name: Resize images

on:
  pull_request:
    paths:
      - 'images/**.jpg'
      - 'images/**.jpeg'
      - 'images/**.png'

jobs:
  build:
    name: Image Resizer Inplace Limit
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repo
        uses: actions/checkout@master
      - name: Compress Images
        id: resize-images
        uses: petems/image-resizer-gh-action@master
        with:
          target: images/ # directory to look for images in
          dimensions: 90% # parameter to change size
          widthLimit: 1024 # max width to check
          heightLimit: 768 # max height to check
      - name: Commit changes
        uses: EndBug/add-and-commit@v4
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          add: 'images/'
          author_name: "github-actions[bot]"
          author_email: "github-actions@users.noreply.github.com"
          message: |
            Images Reszied by Github action\n
            ```
            ${{steps.resize-images.outputs.images_changed}}
            ```
      - name: Convert to Markdown Table
        uses: petems/csv-to-md-table-action@master
        id: csv-table-output
        with:
          csvinput: ${{steps.resize-images.outputs.csv_images_changed}}
      - uses: mshick/add-pr-comment@v1
        with:
          message: |
            **Hello, I resized images for you!**:
            ${{steps.csv-table-output.outputs.markdown-table}}
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          repo-token-user-login: 'github-actions[bot]' # The user.login for temporary GitHub tokens
          allow-repeats: true
```

Which creates a markdown table in the pull-request like so:

![Table PR Comment](https://user-images.githubusercontent.com/1064715/94340746-ec9fef00-fffb-11ea-82a5-5de5372563f2.png)

My testing repo is here: https://github.com/petems/action-test-repo

My testing repo is here: https://github.com/petems/action-test-repo

### Testing and Development

#### VM Testing

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

#### Spec Testing with Docker

```
$ bundle exec rspec spec/

Dockerfile
  entrypoint.sh with valid file
    Command "mkdir -p images/ && convert -size 32x32 xc:black ./images/black-box-32.jpg"
      exit_status
        is expected to eq 0
    File "./images/black-box-32.jpg"
      is expected to exist
      size
        is expected to eql 165
    Command "bash -x ./entrypoint.sh 31 31 ./images/ 50%"
      stdout
        is expected to match "::set-output name=images_changed::<br />./images/black-box-32.jpg - old size: 32 x 32, new size: 16 x 16"
      exit_status
        is expected to eq 0
    File "./images/black-box-32.jpg"
      size
        is expected to eql 162

Finished in 0.79154 seconds (files took 0.40993 seconds to load)
6 examples, 0 failures
```

#### Inspiration

This was inspired by https://github.com/calibreapp/image-actions and existing actions like https://github.com/sharadcodes/img-resizer.
