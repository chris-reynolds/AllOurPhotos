/// Created by Chris on 28/01/2019

import 'package:all_our_photos_app/ImgFile.dart';
import 'package:all_our_photos_app/GooglePhotosLibraryApi.dart';
import 'package:image/image.dart';

/*
  For a googlephotoInfo : creationTime, width, height,
    if checkAlreadyExists then ignore
    Load down photo/video
    Create minimal ImgFile entry
    if jpeg then
       Extract jpeg info
       Create a detailed ImgFile entry
    put photo
    if successful then
      add file to index



    bool checkAlreadyExists() - loop through until match on creationtime, widht,height



 */

class GooglePhotoSync {

  static bool isMatch(GooglePhoto gPhoto, ImgFile imgFile) {
    try {
      Duration diff = gPhoto.creationDate.difference(imgFile.takenDate);
      if ((diff.inMinutes<2) &&
          (gPhoto.width==imgFile.width) && (gPhoto.height==gPhoto.height)) {
        return true;
      }
      return false;
    } catch(ex) {
      return false;
    }
  } // of isMatch

  static ImgFile findInCatalogue(GooglePhoto gPhoto) {
    ImgFile result;
    // TODO : break when found
    ImgCatalog.actOnAll((thisFile) {
      if (isMatch(gPhoto,thisFile))
        result = thisFile;
      return true;
    });
    return result;
  }

  static void checkGPhotos(List<GooglePhoto> gPhotos) async {
    for (var gPhoto in gPhotos) {
      ImgFile imgFile = findInCatalogue(gPhoto);
      if (imgFile != null)
        print('${gPhoto.filename} is ignored');
    }
  } // of checkGPhotos

  static ImgFile makeImgFile(GooglePhoto gPhoto)  {
    String dirName = ImgDirectory.directoryNameForDate(gPhoto.creationDate);
    ImgFile newImage = new ImgFile(dirName, gPhoto.filename);
    newImage.filename = gPhoto.filename;
    newImage.height = gPhoto.height;
    newImage.width = gPhoto.width;
    return newImage;
  }
  static uploadImage(GooglePhoto gPhoto) async {
    Image image = await GooglePhotosLibraryClient.getImageFromGoogleURL(gPhoto);
  } // of uploadImage

} // of GooglePhotoSync