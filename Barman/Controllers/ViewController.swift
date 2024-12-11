//
//  ViewController.swift
//  Barman
//
//  Created by JanZelaznog on 26/02/23.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var drinks = [Drink]()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let drinks = DrinkDataManager.loadDrinks() {
            self.drinks = drinks
        }
        NotificationCenter.default.addObserver(self, selector:#selector(nuevoDrink), name:NSNotification.Name("NUEVO_DRINK"), object: nil)
        let logoutBtn = UIBarButtonItem(image:UIImage(systemName:"rectangle.portrait.and.arrow.right"), style:.plain, target:self, action:#selector(logout))
        self.navigationItem.leftBarButtonItem = logoutBtn
    }

    @objc func logout () {
        // TODO: confirmar si el usuario realmente quiere cerrar sesión
		let alertController = UIAlertController(
			title: "Cerrar Sesión",
			message: "¿Estas seguro que deseas cerrar sesión?",
			preferredStyle: .alert
		)
		
        // TODO: si es customLogin, hay que revisar en UserDefaults y eliminar la llave
		let confirmAction = UIAlertAction(title: "Cerrar Sesión", style: .destructive){ _ in
			if let _ = UserDefaults.standard.object(forKey: "isLoggedIn"){
				UserDefaults.standard.removeObject(forKey: "isLoggedIn")
				UserDefaults.standard.removeObject(forKey: "userAccount")
			}
		
        
			// si esta loggeado con AppleId
			//Al no existir un "logout", se revoca la autorización
			if let appleUserID = UserDefaults.standard.string(forKey: "appleUserID"){
				let request = ASAuthorizationController(authorizationRequests: [request]])
				controller.delegate = self
				controller.performRequests()
			
			//Limpiando la información almacenada del AppleId
			UserDefaults.standard.removeObject(forKey: "appleUserID")
		}
        
			// si esta loggeado con Google
			GIDSignIn.sharedInstance.signOut()
			self.dismiss(animated: true)
		}
		
		let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
		alertController.addAction(confirmAction)
		alertController.addAction(cancelAction)
		
		DispatchQueue.main.async{
			self.present(alertController, animated: true, completion:nil)
		}
    }
    
    @objc func nuevoDrink() {
        let ad = UIApplication.shared.delegate as! AppDelegate
        if let unDrink = ad.drinkExterno {
            performSegue(withIdentifier:SegueID.detail, sender:unDrink)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drinks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellID.drinkID) else {
            return UITableViewCell()
        }
        cell.textLabel?.text = drinks[indexPath.row].name
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.detail {
            let detailViewControler = segue.destination as! DetailViewController
            if let drink = sender as? Drink {
                detailViewControler.drink = drink
            }
            else {
                guard let indexPath = tableView.indexPathForSelectedRow else { return }
                let drink = drinks[indexPath.row]
                detailViewControler.drink = drink
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let index = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    @IBAction func unwindToDrinkList(segue: UIStoryboardSegue) {
        guard segue.identifier == "saveUnwind" else { return }
        let sourceViewController = segue.source as! DetailViewController
        
        if let drink = sourceViewController.drink {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                drinks[selectedIndexPath.row] = drink
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            } else { // if you cannot create the constant then else
                let newIndexPath = IndexPath(row: drinks.count, section: 0)
                drinks.append(drink)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        }
        DrinkDataManager.update(drinks: drinks)
    }
}

