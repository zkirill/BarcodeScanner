import UIKit

class FooterView: UIVisualEffectView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.font = Info.font
    label.textColor = Info.color
    label.numberOfLines = 2
    label.textAlignment = .Center

    return label
  }()

  lazy var imageView: UIImageView = {
    let imageView = UIImageView(image: imageNamed("info"))
    return imageView
  }()

  lazy var activityIndicator: UIActivityIndicatorView = {
    let view = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    return view
  }()

  var state: State = .Scanning {
    didSet {
      label.text = state == .Scanning
        ? Info.scanningText
        : Info.processingText

      state == .Scanning
        ? activityIndicator.stopAnimating()
        : activityIndicator.startAnimating()
    }
  }

  // MARK: - Initialization

  override init(effect: UIVisualEffect?) {
    super.init(effect: effect)

    [label, imageView, activityIndicator].forEach {
      addSubview($0)
    }

    state = .Scanning
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    let padding: CGFloat = 10
    let labelHeight: CGFloat = 40

    label.frame = CGRect(
      x: padding,
      y: (frame.height - labelHeight) / 2,
      width: frame.width - padding,
      height: labelHeight)

    imageView.frame.size = CGSize(width: 36, height: 36)
    imageView.frame.origin.y = label.frame.origin.y - 12 - imageView.frame.height
    imageView.center.x = frame.midX

    activityIndicator.frame.origin.y = label.frame.maxY + (frame.height - label.frame.maxY) / 2
    activityIndicator.center.x = frame.midX
  }
}
