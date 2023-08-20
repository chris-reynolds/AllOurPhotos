
mkdir tmp.iconset
# resize all the images
cp "$1".png tmp.iconset/tmp.png
sips -z 16 16     tmp.iconset/tmp.png --out tmp.iconset/icon_16x16.png
sips -z 32 32     tmp.iconset/tmp.png --out tmp.iconset/icon_16x16@2x.png
sips -z 32 32     tmp.iconset/tmp.png --out tmp.iconset/icon_32x32.png
sips -z 64 64     tmp.iconset/tmp.png --out tmp.iconset/icon_32x32@2x.png
sips -z 128 128   tmp.iconset/tmp.png --out tmp.iconset/icon_128x128.png
sips -z 256 256   tmp.iconset/tmp.png --out tmp.iconset/icon_128x128@2x.png
sips -z 256 256   tmp.iconset/tmp.png --out tmp.iconset/icon_256x256.png
sips -z 512 512   tmp.iconset/tmp.png --out tmp.iconset/icon_256x256@2x.png
sips -z 512 512   tmp.iconset/tmp.png --out tmp.iconset/icon_512x512.png
cp tmp.iconset/tmp.png tmp.iconset/icon_512x512@2x.png
# remove the base image
rm -rf tmp.iconset/tmp.png
# create the .icns
iconutil -c icns tmp.iconset -o "$1".icns
# remove the tmp. folder
# rm -R tmp.iconset