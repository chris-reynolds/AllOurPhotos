// import UIKit
// import Flutter

// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//    GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

import UIKit
import Flutter
import Photos

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    DispatchQueue.main.async {
/*      NSLog("\nimage count is: \(self.getGalleryImageCount())")
      self.dataForGalleryItem(index: 0) { (data, id, created, location) in
        if let data = data {
          NSLog("\nfirst data: \(data) \(id) \(created) \(location)")
        }
      } */
    }

    GeneratedPluginRegistrant.register(with: self)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("rootViewController is not type FlutterViewController")
    }
    let channel = FlutterMethodChannel(name: "/gallery", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { (call, result) in
    switch (call.method) {
    case "getItem":
      let index = call.arguments as? Int ?? 0
      self.dataForGalleryItem(index: index, completion: { (data, id, created, location) in
        result([
             "data": data ?? Data(),
             "id": id,
             "created": created,
             "location": location
        ])
      })
      case "clearCollection" : result(self.clearCollection())
      case "getItemCount": result(self.getGalleryImageCount())
      case "getCountFromDate":
         NSLog("get Count from Date")
         let startDate = call.arguments as? Int ?? 0
         NSLog(" start date \(startDate)")
         result(self.getGalleryCountFromDate(startDate:startDate))
        default: result(FlutterError(code: "0", message: nil, details: nil))
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    var gCollection : PHFetchResult<PHAsset>? = nil

func dataForGalleryItem(index: Int, completion: @escaping (Data?, String, Int, String) -> Void) {
//  let fetchOptions = PHFetchOptions()
//  fetchOptions.includeHiddenAssets = true
//  let collection: PHFetchResult = PHAsset.fetchAssets(with: fetchOptions)
  NSLog("\nstart Get ios item \(index)  \(gCollection?.count ?? -1) \(gCollection != nil)")
  if (index >= gCollection?.count ?? -1) {
    return
  }
    let asset = gCollection!.object(at: index)
  NSLog("\nGet ios item \(index) \(asset.localIdentifier )")
  NSLog("\n\(asset.creationDate ?? Date())")
  let options = PHImageRequestOptions()
  options.deliveryMode = .highQualityFormat // .fastFormat
  options.isSynchronous = true
  options.resizeMode = .none // .exact
//  let imageSize = CGSize(width: 250, height: 250)

  let imageManager = PHCachingImageManager()
  imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
    if let image = image {
      let data = image.jpegData(compressionQuality: 1.00)
      completion(data,
                 asset.localIdentifier,
                 Int(asset.creationDate?.timeIntervalSince1970 ?? 0),
                 "\(asset.location ?? CLLocation())")
    } else {
      completion(nil, "", 0, "")
    }
  }
}

  func getGalleryImageCount() -> Int {
      NSLog("\n getting count")
      let fetchOptions = PHFetchOptions()
      fetchOptions.includeHiddenAssets = true
      let collection: PHFetchResult = PHAsset.fetchAssets(with: fetchOptions)
      return collection.count
  }

    func getGalleryCountFromDate(startDate:Int) -> Int {
        let myDate :Date = Date(timeIntervalSince1970 : TimeInterval(startDate))
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = true
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@ ",argumentArray: [myDate] )
        NSLog("\nFetching from \(myDate)")
        gCollection = PHAsset.fetchAssets(with: fetchOptions)
        return gCollection?.count ?? 0
    }

    func clearCollection() -> Int {
        gCollection = nil;
      return 1;
    }

}
