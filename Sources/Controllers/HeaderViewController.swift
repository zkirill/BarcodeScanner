import UIKit

/// Delegate to handle touch event of the close button.
public protocol HeaderViewControllerDelegate: class {
  func headerViewControllerDidTapCloseButton(_ controller: HeaderViewController)
}

/// Controller with title label and close button.
/// It will be added as a child view controller if `BarcodeScannerController` is being presented.
public final class HeaderViewController: UIViewController {
  public weak var delegate: HeaderViewControllerDelegate?

  /// Header view with title label and close button.
  public private(set) lazy var navigationBar: UINavigationBar = self.makeNavigationBar()
  /// Title view of the navigation bar
  public private(set) lazy var titleLabel: UILabel = self.makeTitleLabel()
  /// Left bar button item of the navigation bar.
  public private(set) lazy var closeButton: UIButton = self.makeCloseButton()

  // MARK: - View lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()

    navigationBar.delegate = self
    closeButton.addTarget(self, action: #selector(handleCloseButtonTap), for: .touchUpInside)

    view.addSubview(navigationBar)
    setupConstraints()
  }

  // MARK: - Actions

  @objc private func handleCloseButtonTap() {
    delegate?.headerViewControllerDidTapCloseButton(self)
  }

  // MARK: - Layout

  private func setupConstraints() {
    navigationBar.translatesAutoresizingMaskIntoConstraints = false
    navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

    if #available(iOS 11, *) {
      navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    } else {
      navigationBar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
    }
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
