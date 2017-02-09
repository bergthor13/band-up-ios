//
//  DrawerViewController.swift
//  band-up-ios
//
//  Created by Bergþór on 16.12.2016.
//  Copyright © 2016 Bad Melody. All rights reserved.
//

import UIKit
import KYDrawerController

class DrawerViewController: UIViewController {
	
	@IBOutlet weak var lblUsername: UILabel!
	@IBOutlet weak var imgUserImage: UIImageView!
	@IBOutlet weak var lblFavInstrument: UILabel!
	let listItems = [
		ListItem(id: "nav_near_me",    name: "Near Me"),
		ListItem(id: "nav_my_profile", name: "My Profile"),
		ListItem(id: "nav_matches",    name: "Matches/Chat"),
		ListItem(id: "nav_settings",   name: "Settings"),
		ListItem(id: "nav_upcoming",   name: "Coming Soon"),
		ListItem(id: "nav_log_out",    name: "Log Out")
	]
	
	let ITEM_IMAGE_TAG = 1
	let ITEM_NAME_TAG = 2
	
	var currentUser = User();
	
	override func viewDidLoad() {
		super.viewDidLoad()
		bandUpAPI.profile.loadIfNeeded()?.onSuccess({ (response) in
			self.currentUser = User(response.jsonDict as NSDictionary)
			self.populateUser()
		}).onFailure({ (error) in
			
		})
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func populateUser() {
		self.lblUsername.text = currentUser.username
		self.lblFavInstrument.text = currentUser.favouriteInstrument
		
		imgUserImage.image = nil
		
		if let checkedUrl = URL(string: currentUser.image.url) {
			imgUserImage.contentMode = .scaleAspectFill
			self.downloadImage(url: checkedUrl, imageView: imgUserImage)
		} else {
			imgUserImage.image = #imageLiteral(resourceName: "ProfilePlaceholder")
			
		}
	}
	
	func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
		URLSession.shared.dataTask(with: url) {
			(data, response, error) in
			completion(data, response, error)
			}.resume()
	}
	
	func downloadImage(url: URL, imageView: UIImageView) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		getDataFromUrl(url: url) { (data, response, error)  in
			guard let data = data, error == nil else { return }
			DispatchQueue.main.async() { () -> Void in
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				imageView.image = UIImage(data: data)
			}
		}
	}
	
}

extension DrawerViewController: UITableViewDataSource, UITableViewDelegate {
	
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return listItems.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "drawerCell", for: indexPath)
		let itemName = cell.viewWithTag(ITEM_NAME_TAG) as! UILabel
		
		itemName.text = listItems[indexPath.row].name
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let drawer = self.parent as! KYDrawerController
		
		let mainController = drawer.mainViewController.childViewControllers[0] as! MainScreenViewController
		mainController.updateView(row: listItems[indexPath.row].id)
		drawer.setDrawerState(.closed, animated: true)
	}
}
