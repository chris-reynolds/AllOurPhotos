# create the icns file on mac

  - cd into the install/dmg directory
  - ensure you have a app png in the directory
  - execute ./png2icns.sc "png filename"
  - this should create a .icns file with the same base filename as the png.


  # create the dmg file

  - staying in the same directory
  - ensure the old dmg file no long exists
  - execute appdmg config.json allourphotos.dmg


  