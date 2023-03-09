//
//  SignupViewController.swift
//  Musivote
//
//  Created by Matthew Loucks on 2/24/23.
//

import UIKit
import Supabase
import GoTrue

class SignupViewController: UIViewController {
    
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Signup"
        // Do any additional setup after loading the view.
        
    }
    
    
    @IBAction func signupClicked(_ sender: Any) {
        
        guard let email = self.emailField.text else { return }
        guard let password = self.passwordField.text else { return }
        
        let client = getSupabaseConnection()
        
        // next, update their device Token
        let deviceToken: String = getDeviceToken()
        
        let jsonData: [String: AnyJSON]? = [
            "deviceToken": AnyJSON.string(deviceToken)
        ]
        
        let attributes: UserAttributes = UserAttributes(data: jsonData)
        
        Task {
            do {
                try await client!.auth.signUp(email: email, password: password)
                let session = try await client!.auth.session
                print("### Session Info: \(session)")
                
                try await client?.auth.update(user: attributes)
                
                //              self.performSegue(withIdentifier: "goToNext", sender: self)
                SceneDelegate.shared!.transitionToMainController()
            } catch {
                print("### Sign Up Error: \(error)")
            }
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
