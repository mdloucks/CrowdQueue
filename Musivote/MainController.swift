//
//  MainController.swift
//  Musivote
//
//  Created by Matthew Loucks on 2/24/23.
//
//
//  ViewController.swift
//  easyplay
//
//

import UIKit
import Supabase

class MainController: UIViewController {

    // MARK: - Spotify Authorization & Configuration
    var responseCode: String? {
        didSet {
            fetchAccessToken { (dictionary, error) in
                if let error = error {
                    print("Fetching token request error \(error)")
                    return
                }
                let accessToken = dictionary!["access_token"] as! String
                DispatchQueue.main.async {
                    self.appRemote.connectionParameters.accessToken = accessToken
                    self.appRemote.connect()
                }
            }
        }
    }

    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()

    var accessToken = UserDefaults.standard.string(forKey: accessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: accessTokenKey)
        }
    }

    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: spotifyClientId, redirectURL: redirectUri)
        // Set the playURI to a non-nil value so that Spotify plays music after authenticating
        // otherwise another app switch will be required
        configuration.playURI = ""
        // Set these url's to your backend which contains the secret to exchange for an access token
        // You can use the provided ruby script spotify_token_swap.rb for testing purposes
        configuration.tokenSwapURL = URL(string: "http://localhost:1234/swap")
        configuration.tokenRefreshURL = URL(string: "http://localhost:1234/refresh")
        return configuration
    }()

    lazy var sessionManager: SPTSessionManager? = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()

    private var lastPlayerState: SPTAppRemotePlayerState?
    private var partyCodeLabelDefaultText = "Start a party to get your join code!"
    private var trackQueue: [String] = []

    // MARK: - Subviews
    let stackView = UIStackView()
    let connectLabel = UILabel()
    let partyCodeLabel = UILabel()
    let connectButton = UIButton(type: .system)
    let imageView = UIImageView()
    let trackLabel = UILabel()
    let playPauseButton = UIButton(type: .system)
    let signOutButton = UIButton(type: .system)
    
//    create party button
    let createPartyButton = UIButton(type: .system)
    let endPartyButton = UIButton(type: .system)

    // MARK: App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
//        register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: Notification.Name("NotificationReceived"), object: nil)
        
        style()
        layout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateViewBasedOnConnected()
    }

    func update(playerState: SPTAppRemotePlayerState) {
        if lastPlayerState?.track.uri != playerState.track.uri {
            fetchArtwork(for: playerState.track)
        }
        lastPlayerState = playerState
        trackLabel.text = playerState.track.name

        let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .large)
        if playerState.isPaused {
            playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: configuration), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: configuration), for: .normal)
        }
    }

    // MARK: - Actions
    @objc func didTapPauseOrPlay(_ button: UIButton) {
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            appRemote.playerAPI?.resume(nil)
        } else {
            appRemote.playerAPI?.pause(nil)
        }
    }

    @objc func didTapSignOut(_ button: UIButton) {
        if appRemote.isConnected == true {
            appRemote.disconnect()
        }
    }

    @objc func didTapConnect(_ button: UIButton) {
        guard let sessionManager = sessionManager else { return }
        sessionManager.initiateSession(with: scopes, options: .clientOnly)
    }
    
    // MARK: - Party
    
    @objc func handleNotification(_ notification: Notification) {
        print("### HANDLE NOTIFICATION")
        let track = notification.userInfo?["track"] as! String
        self.addTrackToQueue(track)

        enqueueSongs(track)
    }
    
    func enqueueSongs(_ trackUri: String) {
        if !appRemote.isConnected {
            print("### Can't enqueue song, not connected")
            return
        }
        
        for track in self.trackQueue {
            self.appRemote.playerAPI?.enqueueTrackUri(track)
        }

        self.trackQueue = []
    }
    
    /**
     Create a live party that users can enqueue songs for.
     */
    @objc func createParty(_ button: UIButton) {
        print("create party!")
        
        Task {
            
            if let partyCode = await Party.getPartyCode() {
                partyCodeLabel.text = "JOIN CODE: \(partyCode)"
                
                endPartyButton.isHidden = false
                createPartyButton.isHidden = true
            } else {
                let partyCode = await Party.create()
                
                partyCodeLabel.text = "JOIN CODE: \(partyCode!)"
                
                endPartyButton.isHidden = false
                createPartyButton.isHidden = true
            }
        }
    }
    
    /**
     Delete the party created from createParty from the database
     */
    @objc func endParty(_ button: UIButton) {
        print("end party!")
        createPartyButton.isHidden = false
        
        Task {
            let didDelete = await Party.delete()
            if didDelete {
                endPartyButton.isHidden = true
                partyCodeLabel.text = self.partyCodeLabelDefaultText
            }
        }
        
    }

    // MARK: - Private Helpers
    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.present(controller, animated: true)
        }
    }
}

// MARK: Style & Layout
extension MainController {
    func style() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center

        connectLabel.translatesAutoresizingMaskIntoConstraints = false
        connectLabel.text = "Connect your Spotify account"
        connectLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        connectLabel.textColor = .systemGreen
        
        partyCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        partyCodeLabel.text = self.partyCodeLabelDefaultText
        partyCodeLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        partyCodeLabel.textColor = .systemCyan

        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.configuration = .filled()
        connectButton.setTitle("Continue with Spotify", for: [])
        connectButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        connectButton.addTarget(self, action: #selector(didTapConnect), for: .primaryActionTriggered)
        
        createPartyButton.translatesAutoresizingMaskIntoConstraints = false
        createPartyButton.configuration = .filled()
        createPartyButton.setTitle("Create Party", for: [])
        createPartyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        createPartyButton.addTarget(self, action: #selector(createParty), for: .primaryActionTriggered)
        
        endPartyButton.translatesAutoresizingMaskIntoConstraints = false
        endPartyButton.configuration = .filled()
        endPartyButton.setTitle("End Party", for: [])
        endPartyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        endPartyButton.backgroundColor = UIColor.red
        endPartyButton.isHidden = true
        endPartyButton.addTarget(self, action: #selector(endParty), for: .primaryActionTriggered)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        trackLabel.translatesAutoresizingMaskIntoConstraints = false
        trackLabel.font = UIFont.preferredFont(forTextStyle: .body)
        trackLabel.textAlignment = .center

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(didTapPauseOrPlay), for: .primaryActionTriggered)

        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("Sign out", for: .normal)
        signOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        signOutButton.addTarget(self, action: #selector(didTapSignOut(_:)), for: .touchUpInside)
    }

    func layout() {

        stackView.addArrangedSubview(partyCodeLabel)
        stackView.addArrangedSubview(createPartyButton)
        stackView.addArrangedSubview(endPartyButton)
        stackView.addArrangedSubview(connectLabel)
        stackView.addArrangedSubview(connectButton)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(trackLabel)
        stackView.addArrangedSubview(playPauseButton)
        stackView.addArrangedSubview(signOutButton)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        Task {
    //        update hidden status of party stop/start based on if party exists
            if(await Party.partyExists()) {
                print("Party exists")
                let partyCode = await Party.getPartyCode()
                partyCodeLabel.text = "JOIN CODE: \(partyCode!)"
                createPartyButton.isHidden = true
                endPartyButton.isHidden = false
            } else {
//                delete code from local storage 
                print("Party doesn't exist")
                createPartyButton.isHidden = false
                endPartyButton.isHidden = true
            }
        }
    }

    func updateViewBasedOnConnected() {
        if appRemote.isConnected == true {
            connectButton.isHidden = true
            signOutButton.isHidden = false
            connectLabel.isHidden = true
            imageView.isHidden = false
            trackLabel.isHidden = false
            playPauseButton.isHidden = false
        }
        else { // show login
            signOutButton.isHidden = true
            connectButton.isHidden = false
            connectLabel.isHidden = false
            imageView.isHidden = true
            trackLabel.isHidden = true
            playPauseButton.isHidden = true
        }
    }
}

// MARK: - SPTAppRemoteDelegate
extension MainController: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        updateViewBasedOnConnected()
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
        fetchPlayerState()
    }

    // disconencted with error.
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        updateViewBasedOnConnected()
        lastPlayerState = nil
        reconnectSpotify()
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        updateViewBasedOnConnected()
        lastPlayerState = nil
        reconnectSpotify()
    }
    
    func reconnectSpotify() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !self.appRemote.isConnected {
                self.appRemote.connectionParameters.accessToken = self.accessToken
                self.appRemote.connect()
                self.appRemote.authorizeAndPlayURI("")
            }
        }
    }
}

// MARK: - SPTAppRemotePlayerAPIDelegate
extension MainController: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        debugPrint("Spotify Track name: %@", playerState.track.name)
        update(playerState: playerState)
    }
}

// MARK: - SPTSessionManagerDelegate
extension MainController: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        if error.localizedDescription == "The operation couldn’t be completed. (com.spotify.sdk.login error 1.)" {
            print("AUTHENTICATE with WEBAPI")
        } else {
            presentAlertController(title: "Authorization Failed", message: error.localizedDescription, buttonTitle: "Bummer")
        }
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }
}

// MARK: - Networking
extension MainController {

    func fetchAccessToken(completion: @escaping ([String: Any]?, Error?) -> Void) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let spotifyAuthKey = "Basic \((spotifyClientId + ":" + spotifyClientSecretKey).data(using: .utf8)!.base64EncodedString())"
        request.allHTTPHeaderFields = ["Authorization": spotifyAuthKey,
                                       "Content-Type": "application/x-www-form-urlencoded"]

        var requestBodyComponents = URLComponents()
        let scopeAsString = stringScopes.joined(separator: " ")

        requestBodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: spotifyClientId),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: responseCode!),
            URLQueryItem(name: "redirect_uri", value: redirectUri.absoluteString),
            URLQueryItem(name: "code_verifier", value: ""), // not currently used
            URLQueryItem(name: "scope", value: scopeAsString),
        ]

        request.httpBody = requestBodyComponents.query?.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,                              // is there data
                  let response = response as? HTTPURLResponse,  // is there HTTP response
                  (200 ..< 300) ~= response.statusCode,         // is statusCode 2XX
                  error == nil else {                           // was there no error, otherwise ...
                      print("Error fetching token \(error?.localizedDescription ?? "")")
                      return completion(nil, error)
                  }
            let responseObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("Access Token Dictionary=", responseObject ?? "")
            completion(responseObject, nil)
        }
        task.resume()
    }

    func fetchArtwork(for track: SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage {
                self?.imageView.image = image
            }
        })
    }

    func fetchPlayerState() {
        appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
            }
        })
    }
    
    func addTrackToQueue(_ trackUri: String) {
        self.trackQueue.append(trackUri)
    }
}

