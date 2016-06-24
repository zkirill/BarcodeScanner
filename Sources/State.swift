struct Status {
  let state: State
  let animated: Bool
  let text: String

  init(_ state: State, animated: Bool = true, text: String? = nil) {
    self.state = state
    self.animated = animated
    self.text = text ?? state.text
  }
}

enum State {
  case Scanning, Processing, Unauthorized, NotFound

  typealias Styles = (tint: UIColor, font: UIFont, alignment: NSTextAlignment)

  var text: String {
    let string: String

    switch self {
    case .Scanning:
      string = Info.text
    case .Processing:
      string = Info.loadingText
    case .Unauthorized:
      string = Info.settingsText
    case .NotFound:
      string = Info.notFoundText
    }

    return string
  }

  var styles: Styles {
    let styles: Styles

    switch self {
    case .Scanning:
      styles = (
        tint: Info.tint,
        font: Info.font,
        alignment: .Left
      )
    case .Processing:
      styles = (
        tint: Info.loadingTint,
        font: Info.loadingFont,
        alignment: .Center
      )
    case .Unauthorized:
      styles = (
        tint: Info.tint,
        font: Info.font,
        alignment: .Left
      )
    case .NotFound:
      styles = (
        tint: Info.notFoundTint,
        font: Info.loadingFont,
        alignment: .Center
      )
    }

    return styles
  }
}
