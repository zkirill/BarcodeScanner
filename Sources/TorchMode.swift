import UIKit
import AVFoundation

/**
 Wrapper around `AVCaptureTorchMode`.
 */
public enum TorchMode {
  case On, Off

  /// Returns the next torch mode.
  var next: TorchMode {
    let result: TorchMode

    switch self {
    case .On:
      result = .Off
    case .Off:
      result = .On
    }

    return result
  }

  /// Torch mode image.
  var image: UIImage {
    let result: UIImage

    switch self {
    case .On:
      result = imageNamed("flashOn")
    case .Off:
      result = imageNamed("flashOff")
    }

    return result
  }

  /// Returns `AVCaptureTorchMode` value.
  var captureTorchMode: AVCaptureTorchMode {
    let result: AVCaptureTorchMode

    switch self {
    case .On:
      result = .On
    case .Off:
      result = .Off
    }

    return result
  }
}
