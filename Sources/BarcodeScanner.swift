import UIKit

public struct Title {
  public static var text = NSLocalizedString("Scan barcode", comment: "")
  public static var font = UIFont.boldSystemFontOfSize(17)
  public static var color = UIColor.blackColor()
}

public struct CloseButton {
  public static var text = NSLocalizedString("Close", comment: "")
  public static var font = UIFont.boldSystemFontOfSize(17)
  public static var color = UIColor.blackColor()
}

public struct Info {
  public static var scanningText = NSLocalizedString(
    "Place the barcode within the window to scan. The search will start automatically.", comment: "")
  public static var processingText = NSLocalizedString(
    "Barcode is processing...", comment: "")
  public static var font = UIFont.boldSystemFontOfSize(16)
  public static var color = UIColor.blackColor()
}

func imageNamed(name: String) -> UIImage {
  let cls = BarcodeScannerController.self
  var bundle = NSBundle(forClass: cls)
  let traitCollection = UITraitCollection(displayScale: 3)

  if let bundlePath = bundle.resourcePath?.stringByAppendingString("/BarcodeScanner.bundle"),
    resourceBundle = NSBundle(path: bundlePath) {
      bundle = resourceBundle
  }

  guard let image = UIImage(named: name, inBundle: bundle,
    compatibleWithTraitCollection: traitCollection)
    else { return UIImage() }

  return image
}
