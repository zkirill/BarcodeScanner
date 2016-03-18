import UIKit
import AVFoundation

public enum FlashMode {
  case On, Off, Auto

  var next: FlashMode {
    let result: FlashMode

    switch self {
    case .On:
      result = .Off
    case .Off:
      result = .Auto
    case .Auto:
      result = .On
    }

    return result
  }

  var image: UIImage {
    let result: UIImage

    switch self {
    case .On:
      result = imageNamed("flashOn")
    case .Off:
      result = imageNamed("flashOff")
    case .Auto:
      result = imageNamed("flashAuto")
    }

    return result
  }

  var captureFlashMode: AVCaptureFlashMode {
    let result: AVCaptureFlashMode

    switch self {
    case .On:
      result = .On
    case .Off:
      result = .Off
    case .Auto:
      result = .Auto
    }

    return result
  }
}
