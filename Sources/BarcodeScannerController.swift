import UIKit
import AVFoundation

public class BarcodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

  lazy var messageLabel: UILabel = {
    let label = UILabel()
    label.backgroundColor = .whiteColor()
    return label
  }()

  lazy var videoView: UIView = UIView()

  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var focusView: UIView?
  var captureDevice: AVCaptureDevice?
}
