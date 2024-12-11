//
//  LoginInterface.swift
//  Barman
//
//  Created by Ángel González on 07/12/24.
//

import Foundation
import UIKit
import AuthenticationServices
import GoogleSignIn

class LoginInterface: UIViewController, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    // TODO: Detectar la conexión a Internet
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    let actInd = UIActivityIndicatorView(style: .large)
    // TODO: implementar cuando debe aparecer y desaparecer el activity indicator
	func showActivityIndicator(){
		actInd.center = self.view.center
		actInd.startAnimating()
		self.view.addSubview(actInd)
	}
	
	func hideActivityIndicator(){
		actInd.stopAnimating()
		actInd.removeFromSuperview()
	}
	
	override func viewDidLoad(){
	super.viewDidLoad()
	
	NotificationCenter.default.addObserver(self, selector: #selector(connectionStatusChanged), name: NSNotification.Name("ConnectionStatusChanged"), object: nil)
	
	if !InternetMonior.shared.isConnected{
		print("Sin conexión a internet")
		showNoInternetAlert()
	} else {
		print("Conexión establecida - \(InternetMonitor.shared.conectionTypeWifi)")
	}
	}
	
	@objc func connectionStatusChanged(){
		if InternetMonior.shared.isConnected {
			print("Se reconectó a Internet")
		} else {
			print("Se perdió la conexión a Internet")
		}
	}
    
    func detectaEstado () { // revisa si el usuario ya inició sesión
        // TODO: si es customLogin, hay que revisar en UserDefaults
		if let customLogin = UserDefaults.standard.string(forKey: "customLogin"){
			print("Usuario loggeado con CustomLogin: \(customLogin) ")
			self.performSegue(withIdentifier: "loginOK", sender:nil)
			return
		}
        
        // si esta loggeado con AppleId
		let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: "userIdentifier"){ (credentialState, error) in
			switch credentialState{
				case .authorized:
					print("Uusuario loggeado con AppleID")
					DispatchQueue.main.async{
						self.performSegue(withIdentifier: "loginOK", sender: nil)
					}
				case .revoked, .notFound:
					print("Usuario no loggeado con appleID")
				default:
					break;
			}
		}
        
        // si esta loggeado con Google
        GIDSignIn.sharedInstance.restorePreviousSignIn { usuario, error in
            guard let perfil = usuario else { return }
            print ("usuario: \(perfil.profile?.name ?? ""), correo: \(perfil.profile?.email ?? "")")
            self.performSegue(withIdentifier:"loginOK", sender:nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        detectaEstado()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // reutilizar custom login para que el usuario acceda por mi backend
        let loginVC = CustomLoginViewController()
        // agregar la lógica de ejecución del controller:
        self.addChild(loginVC)
        loginVC.view.frame = CGRect(x:0, y:45, width:self.view.bounds.width, height:self.view.bounds.width)
        // agregamos la vista de customlogin como subvista
        self.view.addSubview(loginVC.view)
        // agregar boton para login con appleID
        let appleIDBtn = ASAuthorizationAppleIDButton()
        self.view.addSubview(appleIDBtn)
        appleIDBtn.center = self.view.center
        appleIDBtn.frame.origin.y = loginVC.view.frame.maxY + 10
        appleIDBtn.addTarget(self, action:#selector(appleBtnTouch), for:.touchUpInside)
        let googleBtn = GIDSignInButton(frame:CGRect(x:0, y:appleIDBtn.frame.maxY + 10, width: appleIDBtn.frame.width, height:appleIDBtn.frame.height) )
        googleBtn.center.x = self.view.center.x
        self.view.addSubview(googleBtn)
        googleBtn.addTarget(self, action:#selector(googleBtnTouch), for:.touchUpInside)
    }
    
    @objc func googleBtnTouch () {
        GIDSignIn.sharedInstance.signIn(withPresenting:self){ resultado, error in
            if error != nil {
                Utils.showMessage("jiuston... \(error?.localizedDescription)")
            }
            else {
                guard let perfil = resultado?.user else { return }
                print ("usuario: \(perfil.profile?.name), correo: \(perfil.profile?.email)")
                self.performSegue(withIdentifier: "loginOK", sender: nil)
            }
        }
    }
    
    @objc func appleBtnTouch () {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authController = ASAuthorizationController(authorizationRequests:[request])
        authController.presentationContextProvider = self
        authController.delegate = self
        authController.performRequests()
    }
	
	// Método para mostrar la alerta de no conexión
	func showNoInternetAlert() {
		let alertController = UIAlertController(
			title: "Sin conexión a Internet",
			message: "Parece que no estás conectado a Internet. Por favor, verifica tu conexión para continuar.",
			preferredStyle: .alert
		)
		let retryAction = UIAlertAction(title: "Reintentar", style: .default) { _ in
			if InternetMonitor.shared.isConnected {
				print("Conexión restaurada al reintentar")
			} else {
				self.showNoInternetAlert() // Reintenta mostrar la alerta si sigue sin conexión
			}
		}
		let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
		
		alertController.addAction(retryAction)
		alertController.addAction(cancelAction)
		
		DispatchQueue.main.async {
			self.present(alertController, animated: true, completion: nil)
		}
	}
}
