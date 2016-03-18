import UIKit

public var closeButtonTitle = "Close"
public var infoText = ""

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
