import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    lazy var rootViewController = MainController()
    
//    TODO: someone more competant with swift should remove this.
//    The problem was that spotify needs the accessToken property on
//    rootViewController, but when the segue happens in storyboard,
//    the object is created automatically by the system, and not
//    assigned to the member variable in this class, which means
//    the token can't be assigned. Instead, I'm just created a
//    static variable and setting it manually inside the login/signup
//    view controllers.
    static var shared: SceneDelegate?
    
//  exit the main storyboard and start using the main controller
    public func transitionToMainController() {
        window!.rootViewController = rootViewController
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "NavigationViewController") as! NavigationViewController
        
        SceneDelegate.shared = self
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.makeKeyAndVisible()
        window!.windowScene = windowScene
        window!.rootViewController = initialViewController
    }

//     For spotify authorization and authentication flow
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    
        guard let url = URLContexts.first?.url else { return }
        let parameters = rootViewController.appRemote.authorizationParameters(from: url)
        if let code = parameters?["code"] {
            rootViewController.responseCode = code
        } else if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            rootViewController.accessToken = access_token
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("No access token error =", error_description)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if let accessToken = rootViewController.appRemote.connectionParameters.accessToken {
            rootViewController.appRemote.connectionParameters.accessToken = accessToken
            rootViewController.appRemote.connect()
        } else if let accessToken = rootViewController.accessToken {
            rootViewController.appRemote.connectionParameters.accessToken = accessToken
            rootViewController.appRemote.connect()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if rootViewController.appRemote.isConnected {
            rootViewController.appRemote.disconnect()
        }
    }
}
