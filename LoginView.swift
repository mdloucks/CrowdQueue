//
//  LoginView.swift
//  Musivote
//
//  Created by Matthew Loucks on 2/22/23.
//

import SwiftUI

struct LoginView: View {
    
    @State private var username = ""
    @State private var password = ""
    
    @State private var wrongUsername = 0
    @State private var wrongPassword = 0
    
    var body: some View {
        ZStack {
            
            Color.teal.ignoresSafeArea()

            RoundedRectangle(cornerRadius: 25).scale(0.7).foregroundColor(.white.opacity(0.2))
            VStack {
                Text("Login").font(.largeTitle).bold().padding()
                TextField("Username", text: $username).padding().frame(width: 200, height: 50).background(.white.opacity(0.85)).border(.red, width: CGFloat(wrongUsername)).cornerRadius(10)
                
                SecureField("Password", text: $username).padding().background(.white.opacity(0.85)).frame(width: 200, height: 50).border(.red, width: CGFloat(wrongUsername)).cornerRadius(10)
                
                Button("Login", action: login).foregroundColor(.white).frame(width: 200, height: 50).background(.black.opacity(0.15)).cornerRadius(10)
                
            }
        }
    }
    
    func login() {
        
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
