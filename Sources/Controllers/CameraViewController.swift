import UIKit
import AVFoundation

protocol CameraViewControllerDelegate: class {
  func cameraViewControllerDidSetupCaptureSession(_ controller: CameraViewController)
  func cameraViewControllerDidFailToSetupCaptureSession(_ controller: CameraViewController)
  func cameraViewController(_ controller: CameraViewController, didReceiveError error: Error)
  func cameraViewControllerDidTapSettingsButton(_ controller: CameraViewController)
  func cameraViewController(
    _ controller: CameraViewController,
    didOutput metadataObjects: [AVMetadataObject]
  )
}

final class CameraViewController: UIViewController {
  weak var delegate: CameraViewControllerDelegate?
  /// Focus view type.
  var barCodeFocusViewType: FocusViewType = .animated
  /// `AVCaptureMetadataOutput` metadata object types.
  var metadata = [AVMetadataObject.ObjectType]()

  // MARK: - UI

  /// Animated focus view.
  private lazy var focusView: UIView = self.makeFocusView()
  /// Button to change torch mode.
  public lazy var flashButton: UIButton = .init(type: .custom)
  /// Button that opens settings to allow camera usage.
  private lazy var settingsButton: UIButton = self.makeSettingsButton()
  // Constraints for the focus view when it gets smaller in size.
  private var regularFocusViewConstraints = [NSLayoutConstraint]()
  // Constraints for the focus view when it gets bigger in size.
  private var animatedFocusViewConstraints = [NSLayoutConstraint]()

  // MARK: - Video

  /// Video preview layer.
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  /// Video capture device. This may be nil when running in Simulator.
  private lazy var captureDevice: AVCaptureDevice! = AVCaptureDevice.default(for: .video)
  /// Capture session.
  private lazy var captureSession: AVCaptureSession = AVCaptureSession()
  // Service used to check authorization status of the capture device
  private let permissionService = VideoPermissionService()

  /// The current torch mode on the capture device.
  private var torchMode: TorchMode = .off {
    didSet {
      guard let captureDevice = captureDevice, captureDevice.hasFlash else { return }

      do {
        try captureDevice.lockForConfiguration()
        captureDevice.torchMode = torchMode.captureTorchMode
        captureDevice.unlockForConfiguration()
      } catch {}

      flashButton.setImage(torchMode.image, for: UIControlState())
    }
  }

  // MARK: - Initialization

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

    guard let videoPreviewLayer = videoPreviewLayer else {
      return
    }

    view.layer.addSublayer(videoPreviewLayer)
    view.addSubviews(settingsButton, flashButton, focusView)

    torchMode = .off
    focusView.isHidden = true
    setupCamera()
    setupConstraints()

    flashButton.addTarget(self, action: #selector(flashButtonDidPress), for: .touchUpInside)
    settingsButton.addTarget(self, action: #selector(settingsButtonDidPress), for: .touchUpInside)

    NotificationCenter.default.addObserver(
      self, selector: #selector(appWillEnterForeground),
      name: NSNotification.Name.UIApplicationWillEnterForeground,
      object: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupVideoPreviewLayerOrientation()
    animateFocusView()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession.stopRunning()
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.setupVideoPreviewLayerOrientation()
    }) { [weak self] _ in
      self?.animateFocusView()
    }
  }

  // MARK: - State handling

  func startCapturing() {
    guard !isSimulatorRunning else {
      return
    }

    torchMode = .off
    captureSession.startRunning()
    focusView.isHidden = false
    flashButton.isHidden = false
  }

  func stopCapturing() {
    guard !isSimulatorRunning else {
      return
    }

    torchMode = .off
    captureSession.stopRunning()
    focusView.isHidden = true
    flashButton.isHidden = true
  }

  // MARK: - Actions

  /// `UIApplicationWillEnterForegroundNotification` action.
  @objc private func appWillEnterForeground() {
    torchMode = .off
    animateFocusView()
  }

  /// Opens setting to allow camera usage.
  @objc private func settingsButtonDidPress() {
    delegate?.cameraViewControllerDidTapSettingsButton(self)
  }

  /// Sets the next torch mode.
  @objc private func flashButtonDidPress() {
    torchMode = torchMode.next
  }

  // MARK: - Camera setup

  /// Sets up camera and checks for camera permissions.
  private func setupCamera() {
    permissionService.checkPersmission { [weak self] error in
      guard let strongSelf = self else {
        return
      }

      DispatchQueue.main.async { [weak self] in
        self?.settingsButton.isHidden = error == nil
      }

      if error == nil {
        strongSelf.setupSession()
        strongSelf.delegate?.cameraViewControllerDidSetupCaptureSession(strongSelf)
      } else {
        strongSelf.delegate?.cameraViewControllerDidFailToSetupCaptureSession(strongSelf)
      }
    }
  }

  /// Sets up capture input, output and session.
  private func setupSession() {
    guard let captureDevice = captureDevice, !isSimulatorRunning else {
      return
    }

    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
    } catch {
      delegate?.cameraViewController(self, didReceiveError: error)
    }

    let output = AVCaptureMetadataOutput()
    captureSession.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    output.metadataObjectTypes = metadata
    videoPreviewLayer?.session = captureSession

    view.setNeedsLayout()
  }

  // MARK: - Animations

  /// Performs focus view animation.
  private func animateFocusView() {
    focusView.layer.removeAllAnimations()
    focusView.isHidden = false

    guard barCodeFocusViewType == .animated else {
      return
    }

    regularFocusViewConstraints.forEach({ $0.isActive = false })
    animatedFocusViewConstraints.forEach({ $0.isActive = true })
    
    UIView.animate(
      withDuration: 1.0, delay:0,
      options: [.repeat, .autoreverse, .beginFromCurrentState],
      animations: ({ [weak self] in
        self?.view.layoutIfNeeded()
      }),
      completion: nil
    )
  }
}

// MARK: - Layout

private extension CameraViewController {
  func setupConstraints() {
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate(
        flashButton.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor,
          constant: 30
        ),
        flashButton.trailingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.trailingAnchor,
          constant: -13
        )
      )
    } else {
      NSLayoutConstraint.activate(
        flashButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
        flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -13)
      )
    }

    let flashButtonSize: CGFloat = 37

    NSLayoutConstraint.activate(
      flashButton.widthAnchor.constraint(equalToConstant: flashButtonSize),
      flashButton.heightAnchor.constraint(equalToConstant: flashButtonSize),

      settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      settingsButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      settingsButton.widthAnchor.constraint(equalToConstant: 150),
      settingsButton.heightAnchor.constraint(equalToConstant: 50)
    )

    setupFocusViewConstraints()
  }

  func setupFocusViewConstraints() {
    NSLayoutConstraint.activate(
      focusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      focusView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    )

    let focusViewSize = barCodeFocusViewType == .oneDimension
      ? CGSize(width: 280, height: 80)
      : CGSize(width: 218, height: 150)

    regularFocusViewConstraints = [
      focusView.widthAnchor.constraint(equalToConstant: focusViewSize.width),
      focusView.heightAnchor.constraint(equalToConstant: focusViewSize.height)
    ]

    animatedFocusViewConstraints = [
      focusView.widthAnchor.constraint(equalToConstant: 280),
      focusView.heightAnchor.constraint(equalToConstant: 80)
    ]

    NSLayoutConstraint.activate(regularFocusViewConstraints)
  }

  func setupVideoPreviewLayerOrientation() {
    guard let videoPreviewLayer = videoPreviewLayer else {
      return
    }

    videoPreviewLayer.frame = view.layer.bounds

    if let connection = videoPreviewLayer.connection, connection.isVideoOrientationSupported {
      switch (UIApplication.shared.statusBarOrientation) {
      case .portrait:
        connection.videoOrientation = .portrait
      case .landscapeRight:
        connection.videoOrientation = .landscapeRight
      case .landscapeLeft:
        connection.videoOrientation = .landscapeLeft
      case .portraitUpsideDown:
        connection.videoOrientation = .portraitUpsideDown
      default:
        connection.videoOrientation = .portrait
      }
    }
  }
}

// MARK: - Subviews factory

private extension CameraViewController {
  func makeFocusView() -> UIView {
    let view = UIView()
    view.layer.borderColor = UIColor.white.cgColor
    view.layer.borderWidth = 2
    view.layer.cornerRadius = 5
    view.layer.shadowColor = UIColor.white.cgColor
    view.layer.shadowRadius = 10.0
    view.layer.shadowOpacity = 0.9
    view.layer.shadowOffset = CGSize.zero
    view.layer.masksToBounds = false
    return view
  }

  func makeSettingsButton() -> UIButton {
    let button = UIButton(type: .system)
    let title = NSAttributedString(
      string: localizedString("BUTTON_SETTINGS"),
      attributes: [.font: UIFont.boldSystemFont(ofSize: 17), .foregroundColor : UIColor.white]
    )
    button.setAttributedTitle(title, for: UIControlState())
    button.sizeToFit()
    return button
  }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraViewController: AVCaptureMetadataOutputObjectsDelegate {
  func metadataOutput(_ output: AVCaptureMetadataOutput,
                      didOutput metadataObjects: [AVMetadataObject],
                      from connection: AVCaptureConnection) {
    delegate?.cameraViewController(self, didOutput: metadataObjects)
  }
}
