import UIKit
import AVFoundation

// MARK: - Delegates

/// Delegate to handle the captured code.
public protocol BarcodeScannerCodeDelegate: class {
  func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String)
}

/// Delegate to report errors.
public protocol BarcodeScannerErrorDelegate: class {
  func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error)
}

/// Delegate to dismiss barcode scanner when the close button has been pressed.
public protocol BarcodeScannerDismissalDelegate: class {
  func scannerDidDismiss(_ controller: BarcodeScannerViewController)
}

// MARK: - Controller

/**
 Barcode scanner controller with 4 sates:
 - Scanning mode
 - Processing animation
 - Unauthorized mode
 - Not found error message
 */
open class BarcodeScannerViewController: UIViewController {

  // MARK: - Public properties

  /// When the flag is set to `true` controller returns a captured code
  /// and waits for the next reset action.
  public var isOneTimeSearch = true
  /// Delegate to handle the captured code.
  public weak var codeDelegate: BarcodeScannerCodeDelegate?
  /// Delegate to report errors.
  public weak var errorDelegate: BarcodeScannerErrorDelegate?
  /// Delegate to dismiss barcode scanner when the close button has been pressed.
  public weak var dismissalDelegate: BarcodeScannerDismissalDelegate?
  /// `AVCaptureMetadataOutput` metadata object types.
  public var metadata = AVMetadataObject.ObjectType.barcodeScannerMetadata {
    didSet {
      cameraViewController.metadata = metadata
    }
  }

  // MARK: - Private properties

  /// Flag to lock session from capturing.
  private var locked = false

  // MARK: - UI

  /// Information view with description label.
  private lazy var messageViewController: MessageViewController = .init()
  /// Camera view with custom buttons.
  private lazy var cameraViewController: CameraViewController = .init()

  private var messageView: UIView {
    return messageViewController.view
  }

  /// The current controller's status mode.
  private var status: Status = Status(state: .scanning) {
    didSet {
      changeStatus(from: oldValue, to: status)
    }
  }

  /// Calculated frame for the info view.
  private var messageViewFrame: CGRect {
    let height = status.state != .processing ? 75 : view.bounds.height
    return CGRect(
      x: 0, y: view.bounds.height - height,
      width: view.bounds.width, height: height
    )
  }

  // MARK: - View lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.black
    cameraViewController.metadata = metadata
    cameraViewController.delegate = self

    add(childViewController: cameraViewController)
    add(childViewController: messageViewController)
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    let cameraView = cameraViewController.view!

    NSLayoutConstraint.activate(
      cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    )

    if navigationController != nil {
      cameraView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    } else {
      let headerViewController = HeaderViewController()
      headerViewController.delegate = self
      add(childViewController: headerViewController)

      let headerView = headerViewController.view!

      NSLayoutConstraint.activate(
        headerView.topAnchor.constraint(equalTo: view.topAnchor),
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        headerView.bottomAnchor.constraint(equalTo: headerViewController.navigationBar.bottomAnchor),
        cameraView.topAnchor.constraint(equalTo: headerView.bottomAnchor)
      )
    }
  }

  open override func viewWillTransition(to size: CGSize,
                                        with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { (context) in
      self.messageView.frame = self.messageViewFrame
    })
  }

  // MARK: - State handling

  /**
   Shows error message and goes back to the scanning mode.

   - Parameter errorMessage: Error message that overrides the message from the config.
   */
  public func resetWithError(message: String? = nil) {
    status = Status(state: .notFound, text: message)
  }

  /**
   Resets the controller to the scanning mode.

   - Parameter animated: Flag to show scanner with or without animation.
   */
  public func reset(animated: Bool = true) {
    status = Status(state: .scanning, animated: animated)
  }

  private func changeStatus(from oldValue: Status, to newValue: Status) {
    guard newValue.state != .notFound else {
      messageViewController.state = newValue.state
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
        self.status = Status(state: .scanning)
      }
      return
    }

    let animatedTransition = newValue.state == .processing || oldValue.state == .processing
      || oldValue.state == .notFound
    let duration = newValue.animated && animatedTransition ? 0.5 : 0.0
    let delayReset = oldValue.state == .processing || oldValue.state == .notFound

    if !delayReset {
      resetState()
    }

    messageViewController.state = newValue.state

    UIView.animate(
      withDuration: duration,
      animations: ({
        self.messageView.layoutIfNeeded()
        self.messageView.frame = self.messageViewFrame
      }),
      completion: ({ [weak self] _ in
        if delayReset {
          self?.resetState()
        }

        self?.messageView.layer.removeAllAnimations()
        if self?.status.state == .processing {
          self?.messageViewController.animateLoading()
        }
      }))
  }

  /**
   Resets the current state.
   */
  private func resetState() {
    locked = status.state == .processing && isOneTimeSearch
    if status.state == .scanning {
      cameraViewController.startCapturing()
    } else {
      cameraViewController.stopCapturing()
    }
  }

  // MARK: - Animations

  /**
   Simulates flash animation.

   - Parameter processing: Flag to set the current state to `.processing`.
   */
  private func animateFlash(whenProcessing: Bool = false) {
    let flashView = UIView(frame: view.bounds)
    flashView.backgroundColor = UIColor.white
    flashView.alpha = 1

    view.addSubview(flashView)
    view.bringSubview(toFront: flashView)

    UIView.animate(
      withDuration: 0.2,
      animations: ({
        flashView.alpha = 0.0
      }),
      completion: ({ [weak self] _ in
        flashView.removeFromSuperview()

        if whenProcessing {
          self?.status = Status(state: .processing)
        }
      }))
  }
}

// MARK: - HeaderViewControllerDelegate

extension BarcodeScannerViewController: HeaderViewControllerDelegate {
  public func headerViewControllerDidTapCloseButton(_ controller: HeaderViewController) {
    status = Status(state: .scanning)
    dismissalDelegate?.scannerDidDismiss(self)
  }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerViewController: CameraViewControllerDelegate {
  func cameraViewControllerDidSetupCaptureSession(_ controller: CameraViewController) {
    status = Status(state: .scanning)
  }

  func cameraViewControllerDidFailToSetupCaptureSession(_ controller: CameraViewController) {
    status = Status(state: .unauthorized)
  }

  func cameraViewController(_ controller: CameraViewController, didReceiveError error: Error) {
    errorDelegate?.scanner(self, didReceiveError: error)
  }

  func cameraViewControllerDidTapSettingsButton(_ controller: CameraViewController) {
    DispatchQueue.main.async {
      if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.shared.openURL(settingsURL)
      }
    }
  }

  func cameraViewController(_ controller: CameraViewController,
                            didOutput metadataObjects: [AVMetadataObject]) {
    guard !locked else { return }
    guard !metadataObjects.isEmpty else { return }

    guard
      let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
      var code = metadataObj.stringValue,
      metadata.contains(metadataObj.type)
      else { return }

    if isOneTimeSearch {
      locked = true
    }

    var rawType = metadataObj.type.rawValue

    // UPC-A is an EAN-13 barcode with a zero prefix.
    // See: https://stackoverflow.com/questions/22767584/ios7-barcode-scanner-api-adds-a-zero-to-upca-barcode-format
    if metadataObj.type == AVMetadataObject.ObjectType.ean13 && code.hasPrefix("0") {
      code = String(code.dropFirst())
      rawType = AVMetadataObject.ObjectType.upca.rawValue
    }

    codeDelegate?.scanner(self, didCaptureCode: code, type: rawType)
    animateFlash(whenProcessing: isOneTimeSearch)
  }
}
