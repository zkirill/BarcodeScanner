import UIKit

public protocol HeaderViewControllerDelegate: class {
  func headerViewControllerDidTapCloseButton(_ controller: HeaderViewController)
}

public final class HeaderViewController: UIViewController {
  public weak var delegate: HeaderViewControllerDelegate?

  /// Header view with title and close button.
  public private(set) lazy var navigationBar: UINavigationBar = self.makeNavigationBar()
  /// Title label to show as a title view in navigation bar
  public private(set) lazy var titleLabel: UILabel = self.makeTitleLabel()
  /// Close button to show as a left bar button item in navigation bar.
  public private(set) lazy var closeButton: UIButton = self.makeCloseButton()

  // MARK: - View lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()

    navigationBar.delegate = self
    closeButton.addTarget(self, action: #selector(handleCloseButtonTap), for: .touchUpInside)

    view.addSubview(navigationBar)
    navigationBar.translatesAutoresizingMaskIntoConstraints = false
    navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

    if #available(iOS 11, *) {
      navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    } else {
      navigationBar.topAnchor.constraint(
        equalTo: topLayoutGuide.bottomAnchor).isActive = true
    }
  }

  // MARK: - Actions

  @objc private func handleCloseButtonTap() {
    delegate?.headerViewControllerDidTapCloseButton(self)
  }
}

  // MARK: - Subviews
private extension HeaderViewController {
  func makeNavigationBar() -> UINavigationBar {
    let navigationBar = UINavigationBar()
    navigationBar.isTranslucent = false
    navigationBar.backgroundColor = Title.backgroundColor
    navigationBar.items = [makeNavigationItem()]
    return navigationBar
  }

  func makeNavigationItem() -> UINavigationItem {
    let navigationItem = UINavigationItem()
    closeButton.sizeToFit()
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
    titleLabel.sizeToFit()
    navigationItem.titleView = titleLabel
    return navigationItem
  }

  func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.text = Title.text
    label.font = Title.font
    label.textColor = Title.color
    label.numberOfLines = 1
    label.textAlignment = .center
    return label
  }

  func makeCloseButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(CloseButton.text, for: UIControlState())
    button.titleLabel?.font = CloseButton.font
    button.tintColor = CloseButton.color
    return button
  }
}

// MARK: - UINavigationBarDelegate

extension HeaderViewController: UINavigationBarDelegate {
  public func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
}
