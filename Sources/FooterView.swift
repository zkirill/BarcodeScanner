import UIKit

class FooterView: UIVisualEffectView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.font = Info.font
    label.textColor = Info.color
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
    view.layer.borderColor = Info.loadingColor.CGColor
    view.layer.cornerRadius = 10

    return view
  }()

  var state: State = .Scanning {
    didSet {
      setupFrames()

      label.text = state == .Scanning
        ? Info.scanningText
        : Info.processingText

      label.textAlignment = state == .Scanning ? .Left : .Center

      imageView.tintColor = state == .Scanning
        ? Info.color
        : Info.loadingColor

      if state == .Scanning {
        layer.removeAllAnimations()
        borderView.hidden = true
        borderView.layer.removeAllAnimations()
      } else {
        borderView.hidden = false
        animateLoading()
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

    if state == .Scanning {
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
        y: (frame.height - imageSize.height) / 2 - 100,
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
    UIView.animateWithDuration(2.0, delay:0, options: [.Repeat, .Autoreverse],
      animations: {
        self.effect = UIBlurEffect(style: .Light)
      }, completion: nil)

    animateBorderView(CGFloat(M_PI_2))
  }

  func animateBorderView(angle: CGFloat) {
    UIView.animateWithDuration(0.8,
      delay: 0, usingSpringWithDamping: 0.6,
      initialSpringVelocity: 1.0,
      options: [.BeginFromCurrentState],
      animations: {
        self.borderView.transform = CGAffineTransformMakeRotation(angle)
      }, completion: { _ in
        self.animateBorderView(angle + CGFloat(M_PI_2))
    })
  }
}
