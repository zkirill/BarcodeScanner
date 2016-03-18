import UIKit

class FooterView: UIVisualEffectView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.text = Info.text
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

  // MARK: - Initialization

  override init(effect: UIVisualEffect?) {
    super.init(effect: effect)

    [label, imageView].forEach {
      addSubview($0)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    let padding: CGFloat =  10
    let labelHeight: CGFloat = 40

    imageView.frame.origin.y = 30
    imageView.center.x = frame.midX

    label.frame = CGRect(
      x: padding,
      y: (frame.height - labelHeight) / 2,
      width: frame.width - padding,
      height: labelHeight)
  }
}
