import UIKit

final class BlurView: UIView {
  private let effectView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .extraLight))

  // MARK: - Init

  init(style: UIBlurEffectStyle) {
    super.init(frame: .zero)
    insertSubview(effectView, at: 0)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  // MARK: - Subviews

  override func addSubview(_ view: UIView) {
    effectView.contentView.addSubview(view)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    effectView.frame = bounds
  }
}
