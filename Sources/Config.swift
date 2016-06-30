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

public struct SettingsButton {
  public static var text = NSLocalizedString("Settings", comment: "")
  public static var font = UIFont.boldSystemFontOfSize(17)
  public static var color = UIColor.whiteColor()
}

public struct Info {
  public static var text = NSLocalizedString(
    "Place the barcode within the window to scan. The search will start automatically.", comment: "")
  public static var loadingText = NSLocalizedString(
    "Looking for your product...", comment: "")
  public static var notFoundText = NSLocalizedString(
    "No product found.", comment: "")
  public static var settingsText = NSLocalizedString(
    "In order to scan barcodes you have to allow camera under your settings.", comment: "")

  public static var font = UIFont.boldSystemFontOfSize(14)
  public static var textColor = UIColor.blackColor()
  public static var tint = UIColor.blackColor()

  public static var loadingFont = UIFont.boldSystemFontOfSize(16)
  public static var loadingTint = UIColor.blackColor()

  public static var notFoundTint = UIColor.redColor()
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
