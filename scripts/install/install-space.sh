#!/bin/bash

rm -r "${basedir}"/freeciv-space
rm -r "${basedir}"/freeciv/freeciv/data/amplio2
git clone https://github.com/AlexusBlack/freeciv-space-tileset.git "${basedir}"/freeciv-space
# Replacing Amplio2 tileset with Space tileset with minimum code changes
cp "${basedir}"/freeciv-space/space.tilespec "${basedir}"/freeciv/freeciv/data/amplio2.tilespec
cp -r "${basedir}"/freeciv-space/space "${basedir}"/freeciv/freeciv/data/
cp -r "${basedir}"/freeciv-space/space "${basedir}"/freeciv/freeciv/data/amplio2
