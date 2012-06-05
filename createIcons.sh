#!/bin/bash
# According to https://developer.apple.com/library/ios/#qa/qa1686/_index.html
# Install ImageMagick with MacPort: sudo port install ImageMagick
convert $1 -resize 512x512  iTunesArtwork.png  # Ad Hoc iTunes
convert $1 -resize 144x144  Icon-72@2x.png     # Home screen for "The New iPad"
convert $1 -resize 114x114  Icon@2x.png        # Home screen for Retina display iPhone/iPod
convert $1 -resize 72x72    Icon-72.png        # App Store and Home screen on iPad
convert $1 -resize 58x58    Icon-Small@2x.png  # Spotlight and Settings for Retina display
convert $1 -resize 57x57    Icon.png           # Home screen on non-Retina iPhone/iPod
convert $1 -resize 50x50    Icon-Small-50.png  # Spotlight on iPad 1/2
convert $1 -resize 29x29    Icon-Small.png     # Settings on iPad and iPhone, and Spotlight on iPhone

