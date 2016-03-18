import UIKit

class HeaderView: UIVisualEffectView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.backgroundColor = .whiteColor()
    label.text = Info.text
    label.font = Info.font
    label.textColor = Info.color
    label.numberOfLines = 1

    return label
  }()

  lazy var button: UIButton = {
    let button = UIButton(type: .System)
    button.setTitle(Title.text, forState: .Normal)
    button.titleLabel?.font = Title.font
    button.tintColor = Title.color

    return button
  }()

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    let padding: CGFloat = 15

    button.frame.origin.x = padding
    button.center.y = frame.midY

    label.frame = CGRect(
      x: button.frame.maxX + padding, y: frame.midY,
      width: frame.width - padding, height: 40)
  }
}
