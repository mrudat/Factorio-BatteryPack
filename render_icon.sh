#!/bin/bash
# -------------------------------------------------------------------------
#
#  renders a POV-Ray scene in different variants
#  and combines them to an icon with transparency
#
#   Usage:
#
#     render_icon.sh Scene Image Render_Options
#
#   where 'Scene' is the name of the scene
#   and 'Image the prefix for the images to generate
#
#   requires ImageMagick tools
#
# -------------------------------------------------------------------------

SCENE="$1"
IMAGE="$2"
TYPE="$3"
OPTIONS="$4"

tempdir=$(mktemp -d)
trap "rm -rf $tempdir" EXIT

technology_size="+H128 +W128"
icon_size="+H64 +W64"

set -x
set -e

case "$TYPE" in
  technology)
    povray +I${SCENE} $OPTIONS $technology_size -o${tempdir}/alpha.png DECLARE=Variant=1 +ua
    povray +I${SCENE} $OPTIONS $technology_size -o${tempdir}/bkg.png DECLARE=Variant=2
    povray +I${SCENE} $OPTIONS $technology_size -o${tempdir}/shadow.png DECLARE=Variant=3

    shadow="( ${tempdir}/shadow.png -colorspace gray -alpha off -negate )"

    background="( ${tempdir}/bkg.png $shadow -compose copy-opacity -composite )"

    convert \( $background ${tempdir}/alpha.png -compose over -composite \) ${tempdir}/image.png

    pngcrush -rem alla -brute ${tempdir}/image.png ${IMAGE}
    ;;
  entity)
    povray +I${SCENE} $OPTIONS -o${tempdir}/alpha.png DECLARE=Variant=4 +ua
    povray +I${SCENE} $OPTIONS -o${tempdir}/bkg.png DECLARE=Variant=5
    povray +I${SCENE} $OPTIONS -o${tempdir}/shadow.png DECLARE=Variant=6

    shadow="( ${tempdir}/shadow.png -colorspace gray -alpha off -negate )"

    convert -verbose \( ${tempdir}/bkg.png $shadow -compose copy-opacity -composite \) ${tempdir}/shadow2.png

    pngcrush -rem alla -brute ${tempdir}/shadow2.png ${IMAGE}-shadow.png
    pngcrush -rem alla -brute ${tempdir}/alpha.png   ${IMAGE}
    ;;
  *) # icon
    povray +I${SCENE} $OPTIONS $icon_size -o${tempdir}/image.png DECLARE=Variant=7 +ua
    pngcrush -rem alla -brute ${tempdir}/image.png ${IMAGE}
    ;;
esac

