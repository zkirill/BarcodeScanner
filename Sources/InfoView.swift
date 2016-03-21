import UIKit

class InfoView: UIVisualEffectView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.numberOfLines = 2

    return label
  }()

  lazy var imageView: UIImageView = {
    let image = imageNamed("info").imageWithRenderingMode(.AlwaysTemplate)
    let imageView = UIImageView(image: image)

    return imageView
  }()

  lazy var borderView: UIView = {
    let view = UIView()
    view.backgroundColor = .clearColor()
    view.layer.borderWidth = 2
    view.layer.borderColor = Info.loadingTint.CGColor
    view.layer.cornerRadius = 10

    return view
  }()

  var state: State = .Scanning {
    didSet {
      setupFrames()

      switch state {
      case .Processing, .NotFound:
        label.text = state == .Processing ? Info.loadingText : Info.notFoundText
        label.font = Info.loadingFont
        label.textColor = Info.textColor
        label.textAlignment = .Center
        imageView.tintColor = state == .Processing ? Info.loadingTint : Info.notFoundTint

        if state == .NotFound {
          borderView.hidden = true
        }
      default:
        label.text = state == .Scanning ? Info.text : Info.settingsText
        label.font = Info.font
        label.textColor = Info.textColor
        label.textAlignment = .Left
        imageView.tintColor = Info.tint

        borderView.hidden = true
        borderView.layer.removeAllAnimations()
      }
    }
  }

  // MARK: - Initialization

  init() {
    let blurEffect = UIBlurEffect(style: .ExtraLight)
    super.init(effect: blurEffect)

    [label, imageView, borderView].forEach {
      addSubview($0)
    }

    state = .Scanning
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  func setupFrames() {
    let padding: CGFloat = 10
    let labelHeight: CGFloat = 40
    let imageSize = CGSize(width: 30, height: 27)
    let borderSize: CGFloat = 51

    if state != .Processing && state != .NotFound {
      imageView.frame = CGRect(
        x: padding,
        y: (frame.height - imageSize.height) / 2,
        width: imageSize.width,
        height: imageSize.height)

      label.frame = CGRect(
        x: imageView.frame.maxX + padding,
        y: 0,
        width: frame.width - imageView.frame.maxX - 2 * padding,
        height: frame.height)
    } else {
      imageView.frame = CGRect(
        x: (frame.width - imageSize.width) / 2,
        y: (frame.height - imageSize.height) / 2 - 60,
        width: imageSize.width,
        height: imageSize.height)

      label.frame = CGRect(
        x: padding,
        y: imageView.frame.maxY + 14,
        width: frame.width - padding,
        height: labelHeight)
    }

    borderView.frame = CGRect(
      x: (frame.width - borderSize) / 2,
      y: imageView.frame.minY - 12,
      width: borderSize,
      height: borderSize)
  }

  // MARK: - Animations

  func animateLoading() {
    borderView.hidden = false

    animateBlur(.Light)
    animateBorderView(CGFloat(M_PI_2))
  }

  func animateBlur(style: UIBlurEffectStyle) {
    guard state == .Processing else { return }

    UIView.animateWithDuration(2.0, delay: 0.5, options: [.BeginFromCurrentState],
      animations: {
        self.effect = UIBlurEffect(style: style)
      }, completion: { _ in
        self.animateBlur(style == .Light ? .ExtraLight : .Light)
    })
  }

  func animateBorderView(angle: CGFloat) {
    guard state == .Processing else {
      borderView.transform = CGAffineTransformIdentity
      return
    }

    UIView.animateWithDuration(0.8,
      delay: 0.5, usingSpringWithDamping: 0.6,
      initialSpringVelocity: 1.0,
      options: [.BeginFromCurrentState],
      animations: {
        self.borderView.transform = CGAffineTransformMakeRotation(angle)
      }, completion: { _ in
        self.animateBorderView(angle + CGFloat(M_PI_2))
    })
  }
}
