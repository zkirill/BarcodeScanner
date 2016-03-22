import UIKit
import AVFoundation

public enum TorchMode {
  case On, Off

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
