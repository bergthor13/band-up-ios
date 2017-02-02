//
//  UserListPageViewController.swift
//  band-up-ios
//
//  Created by Bergþór on 29.12.2016.
//  Copyright © 2016 Bad Melody. All rights reserved.
//

import UIKit

class UserListViewController: UIViewController {

	@IBOutlet weak var userCollectionView: UICollectionView!
	@IBOutlet weak var lblError: UILabel!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	public lazy var userDetailsViewController: UserDetailsViewController = {
		return UserDetailsViewController(nibName: "UserDetailsView", bundle: nil)
	}()
	
	@IBAction func didClickDetails(_ sender: UIButton) {
		userDetailsViewController.currentUser = userArray[Int(currentIndex)]
		self.navigationController?.pushViewController(userDetailsViewController, animated: true)
	}
	
	@IBAction func didClickLike(_ sender: UIButton) {
		let likedUser = userArray[Int(currentIndex)]
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
		bandUpAPI.like.request(.post, json: ["userID": likedUser.id]).onSuccess { (response) in
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			
			if let isMatch = response.jsonDict["isMatch"] as? Bool {
				likedUser.isLiked = true
				sender.setTitle("Liked", for: .normal)
				sender.isEnabled = false
				
				if isMatch {
					sender.setTitle("Matched", for: .normal)
					sender.isEnabled = false
				}
			}
		}.onFailure { (error) in
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
		}
	}
	
	var userArray: [User] = []
	
	var currentIndex : CGFloat = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		registerForPreviewing(with: self, sourceView: userCollectionView)
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
		bandUpAPI.nearby.loadIfNeeded()?.onSuccess({ (response) in
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			self.activityIndicator.stopAnimating()
			
			for user in response.jsonArray {
				if let jsonUser = user as? NSDictionary {
					self.userArray.append(User(jsonUser))
				}
			}
			self.userArray.shuffle()
			self.userCollectionView.reloadData()
			
		}).onFailure({ (error) in
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			self.activityIndicator.stopAnimating()
			print("ERROR")
			print(error)
		})
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

extension UserListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return userArray.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "user_item_cell", for: indexPath) as! UserListItemViewCell
		
		cell.user = userArray[indexPath.row]
		let currentUser = cell.user
		
		cell.imgUserImage.image = nil
		if let checkedUrl = URL(string: currentUser.image.url) {
			cell.imgUserImage.contentMode = .scaleAspectFill
			self.downloadImage(url: checkedUrl, imageView: cell.imgUserImage, activityIndicator: cell.actIndicator)
		} else {
			cell.imgUserImage.image = UIImage(named: "defaultmynd")
			cell.actIndicator.stopAnimating()
		}
		
		cell.lblUsername.text = currentUser.username
		cell.lblPercentage.text = String(format:"\(currentUser.percentage)%%")
		cell.lblDistance.text = String(format:"%.0f km away from you", currentUser.distance)
		
		if (currentUser.favouriteInstrument == "") {
			if (currentUser.instruments.count > 0) {
				cell.lblFavInstrument.text = currentUser.instruments[0]
			} else {
				cell.lblFavInstrument.text = "No Instrument"
			}
		} else {
			cell.lblFavInstrument.text = currentUser.favouriteInstrument
		}
		
		if (currentUser.genres.count > 0) {
			cell.lblGenre.text = currentUser.genres[0]
		} else {
			cell.lblGenre.text = "No Genre"
		}
		
		if currentUser.isLiked {
			cell.btnLike.setTitle("Liked", for: .normal)
			cell.btnLike.isEnabled = false;
		} else {
			cell.btnLike.setTitle("Like", for: .normal)
			cell.btnLike.isEnabled = true;
		}
		
		cell.lblAge.text = String(format:"\(currentUser.getAge()) years old")
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView,
	                    layout collectionViewLayout: UICollectionViewLayout,
	                    sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		return CGSize(width: view.frame.width, height: view.frame.height)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		currentIndex = self.userCollectionView.contentOffset.x / self.userCollectionView.frame.size.width
	}
	
	func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
		URLSession.shared.dataTask(with: url) {
			(data, response, error) in
			completion(data, response, error)
			}.resume()
	}
	
	func downloadImage(url: URL, imageView: UIImageView, activityIndicator: UIActivityIndicatorView) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		activityIndicator.startAnimating()
		getDataFromUrl(url: url) { (data, response, error)  in
			guard let data = data, error == nil else { return }
			DispatchQueue.main.async() { () -> Void in
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				activityIndicator.stopAnimating()
				imageView.image = UIImage(data: data)
			}
		}
	}
}

extension UserListViewController: UIViewControllerPreviewingDelegate {
	
	// If you return nil, a preview presentation will not be performed
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		userDetailsViewController.currentUser = userArray[Int(currentIndex)]
		
		
		let indexPath: IndexPath = IndexPath(item: Int(currentIndex), section: 0)

		let itemCell = userCollectionView.cellForItem(at: indexPath) as! UserListItemViewCell
		
		let imageViewRect = itemCell.imgUserImage.frame
		let newX = location.x - itemCell.imgUserImage.frame.width * currentIndex
		
		let newLocation = CGPoint(x: newX, y: location.y)
		
		if (!imageViewRect.contains(newLocation)) {
			return nil
		}
		
		let sourceRect = previewingContext.sourceView.convert(imageViewRect, from: userCollectionView.superview)

		previewingContext.sourceRect = sourceRect
		
		return userDetailsViewController
		
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		show(userDetailsViewController, sender: self)
	}
}

extension MutableCollection where Index == Int {
	/// Shuffle the elements of `self` in-place.
	mutating func shuffle() {
		// empty and single-element collections don't shuffle
		if count < 2 { return }
		
		for i in startIndex ..< endIndex - 1 {
			let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
			if i != j {
				swap(&self[i], &self[j])
			}
		}
	}
}
