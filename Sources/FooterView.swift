import UIKit

class FooterView: UIVisualEffectView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.backgroundColor = .whiteColor()
    label.text = Info.text
    label.font = Info.font
    label.textColor = Info.color
    label.numberOfLines = 2

    return label
  }()

  lazy var imageView: UIImageView = {
    let imageView = UIImageView(image: imageNamed("info"))
    return imageView
  }()

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    let padding: CGFloat =  10

    imageView.frame.origin.y = 30
    imageView.center.x = frame.midX

    label.frame = CGRect(
      x: padding, y: frame.midY,
      width: frame.width - padding, height: 40)
  }
}
