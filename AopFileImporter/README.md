A Dart harness to run the AllOurPhotos Index builder
By Chris Reynolds.

This will take a folder and an optional date from the command-line.

It will scan that folder and all subfolders for media files (*.jpg,*.mov,*.avi)
optionally filtered with with a modified date greater than the command-line date

For each media file, it will create a full_image, thumbnail and snaps table entry.

Login and session details will be held in a config file.

