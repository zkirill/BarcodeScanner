import UIKit
import BarcodeScanner

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  lazy var viewController: ViewController = {
    let controller = ViewController()
    return controller
  }()

  func application(application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window?.rootViewController = viewController
    window?.makeKeyAndVisible()

    return true
  }
}
