import UIKit
import AVFoundation

extension UIInterfaceOrientation {

  var captureOrientation: AVCaptureVideoOrientation {
    let result: AVCaptureVideoOrientation

    switch (self) {
    case UIInterfaceOrientation.LandscapeLeft:
      result = .LandscapeLeft
    case UIInterfaceOrientation.LandscapeRight:
      result = .LandscapeRight
    case UIInterfaceOrientation.Portrait:
      result = .Portrait
    case UIInterfaceOrientation.PortraitUpsideDown:
      result = .PortraitUpsideDown
    default:
      result = .Portrait
    }

    return result
  }
}
