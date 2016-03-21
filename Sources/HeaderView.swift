import UIKit

class HeaderView: UIView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.backgroundColor = .whiteColor()
    label.text = Title.text
    label.font = Title.font
    label.textColor = Title.color
    label.numberOfLines = 1
    label.textAlignment = .Center

    return label
  }()

  lazy var button: UIButton = {
    let button = UIButton(type: .System)
    button.setTitle(CloseButton.text, forState: .Normal)
    button.titleLabel?.font = CloseButton.font
    button.tintColor = CloseButton.color

    return button
  }()

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .whiteColor()

    [label, button].forEach {
      addSubview($0)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    let padding: CGFloat = 15
    let labelHeight: CGFloat = 40

    button.sizeToFit()
    button.frame.origin = CGPoint(x: padding,
      y: ((frame.height - button.frame.height) / 2) + 8)

    label.frame = CGRect(
      x: 0, y: ((frame.height - labelHeight) / 2) + 8,
      width: frame.width, height: labelHeight)
  }
}
