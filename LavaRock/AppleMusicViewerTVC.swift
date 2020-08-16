//
//  AppleMusicViewerTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import UIKit
import MediaPlayer
import CoreData

class AppleMusicViewerTVC: UITableViewController {
	
	// Constants
	static let artworkSize = CGSize(width: 66, height: 66)
	
	// Constant references
	let mediaLibraryManager = (UIApplication.shared.delegate as! AppDelegate).mediaLibraryManager
	let coreDataManager = CoreDataManager(managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
//	lazy var collectionsTVC = (tabBarController?.viewControllers?.first as! UINavigationController).viewControllers.first as! CollectionsTVC // This is obviously just for testing. Obviously.
	
	
	var items = [TestCollection]() {
		didSet {
			for indexInItems in 0..<items.count {
				items[indexInItems].index = Int64(indexInItems)
			}
		}
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.tableFooterView = UIView()
		
		loadSavedItems()
		
		if MPMediaLibrary.authorizationStatus() == .authorized {
			saveItemsFromAppleMusic()
		}
	}
	
	func loadSavedItems() {
		let fetchRequest = NSFetchRequest<TestCollection>(entityName: "TestCollection")
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		coreDataManager.managedObjectContext.performAndWait {
			do {
				items = try coreDataManager.managedObjectContext.fetch(fetchRequest)
			} catch {
				print("Couldn't load saved TestCollections.")
				fatalError("\(error)")
			}
		}
	}
	
	func saveItemsFromAppleMusic() {
		guard var queriedItems = MPMediaQuery.songs().items else {
			return
		}
		
//		queriedItems.sort() {
//			if let date0 = $0.releaseDate {
//				if let date1 = $1.releaseDate {
//					return date0 > date1
//				} else { // $0.releaseDate has a value, but $1.releaseDate doesn't
//					return true
//				}
//			} else {
//				if $1.releaseDate != nil { // $0.releaseDate is nil, but $1.releaseDate has a value
//					return false
//				} else {
//					return true
//				}
//			}
//		}
		queriedItems.sort() { ($0.title ?? "") < ($1.title ?? "") }
		queriedItems.sort() { $0.albumTrackNumber < $1.albumTrackNumber }
		queriedItems.sort() { ($0.albumTitle ?? "") < ($1.albumTitle ?? "") }
		queriedItems.sort() { ($0.albumArtist ?? "") < ($1.albumArtist ?? "") }
		
		// songs
//		for song in queriedItems {
//			let songTitle = song.title ?? ""
//			let newSong = SongInfo(title: songTitle, trackNumber: song.albumTrackNumber, releaseDate: song.releaseDate)
//			if let year = song.value(forKey: "year") { // Undocumented. As of iOS 14.0 beta 4, this works, but if this key ever changes in the API, this line of code will crash the app.
//				print(year)
//			}
//			items.append(newSong)
//		}
		
		// albums
//		for item in queriedItems {
//			if
//				let albumTitle = item.title,
//				!itemTitles.contains(albumTitle)
//			{
//
//				let album = AlbumInfo(title: albumTitle, year: <#T##Int#>)
//				items.append(album)
//			}
//		}
		
		// Collections
		var existingCollectionTitles = [String]()
		for existingCollection in items {
			existingCollectionTitles.append(existingCollection.title!)
		}
		for item in queriedItems {
			let albumArtistName = item.albumArtist ?? "Unknown Album Artist"
			guard !existingCollectionTitles.contains(albumArtistName) else {
				continue
			}
			existingCollectionTitles.append(albumArtistName)
			coreDataManager.managedObjectContext.performAndWait {
				let newCollection = TestCollection(context: self.coreDataManager.managedObjectContext)
				newCollection.title = albumArtistName
				self.items.insert(newCollection, at: 0)
			}
		}
		coreDataManager.save()
		
//		loadSavedItems()
		
//		tableView.reloadData()
	}
	
    // MARK: - Table view data source
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return allowAccessCell(for: indexPath)
		}
		
		// Get the data to put into the cell.
		guard items.count > 0 else {
			return UITableViewCell()
		}
		let item = items[indexPath.row]
		let itemTitle = item.title
		let itemSubtitle: String? = nil
//		let dateFormatter = ISO8601DateFormatter()
//		if let date = item.releaseDate {
//			itemSubtitle = dateFormatter.string(from: date)
//		}
//		let itemArtwork = item.artwork?.image(at: Self.artworkSize)
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		
		if #available(iOS 14.0, *) {
			var cc = UIListContentConfiguration.subtitleCell()
			
			cc.text = itemTitle
			cc.secondaryText = itemSubtitle
//			cc.image = itemArtwork
			
			cc.secondaryTextProperties.color = .secondaryLabel
			cc.imageProperties.maximumSize = Self.artworkSize
			
			cell.contentConfiguration = cc
			
		} else { // iOS 13 and earlier
			cell.textLabel?.text = itemTitle
			cell.detailTextLabel?.text = itemSubtitle
//			cell.imageView?.image = itemArtwork
		}
		
		return cell
	}
	
	// MARK: - DONE PORTING ALL THE METHODS BELOW TO LibraryTVC
	
	// Copied from LibraryTVC.
	func allowAccessCell(for indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell", for: indexPath) // Do we need a copy of this cell in the storyboard in every scene that's a child of this class?
		if #available(iOS 14.0, *) {
			var configuration = UIListContentConfiguration.cell()
			configuration.text = "Placeholder: No Access to Apple Music"
			configuration.textProperties.color = view.window!.tintColor
			cell.contentConfiguration = configuration
		} else { // iOS 13 and earlier
			cell.textLabel?.textColor = view.window?.tintColor
		}
		return cell
	}
	
	// Copied to LibraryTVC
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// You need to accommodate 2 special cases:
		// 1. When the user hasn't allowed access to Apple Music, use the "Allow Access to Apple Music" cell as a button.
		// 2. When there are no items, set the "Add some songs to the Apple Music app." placeholder cell to the background view.
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			// This logic, for setting the "no items" placeholder, should be in numberOfRowsInSection, not in numberOfSections.
			// - If you put it in numberOfSections, VoiceOver moves focus from the tab bar directly to the navigation bar title, skipping over the placeholder. (It will move focus to the placeholder if you tap there, but then you won't be able to move focus out until you tap elsewhere.)
			// - If you put it in numberOfRowsInSection, VoiceOver move focus from the tab bar to the placeholder, then to the navigation bar title, as expected.
			if items.count > 0 {
				tableView.backgroundView = nil
				return items.count
			} else {
				let noItemsView = tableView.dequeueReusableCell(withIdentifier: "No Items Cell")! // We need a copy of this cell in every scene in the storyboard that might use it.
				tableView.backgroundView = noItemsView
				return 0
			}
		default:
			tableView.backgroundView = nil
			return 1 // "Allow Access" cell
		}
	}
	
	// MARK: - Events
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		// Copied from LibraryTVC. OUT OF DATE
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			break
		case .notDetermined: // The golden opportunity.
			MPMediaLibrary.requestAuthorization() { newStatus in // Fires the alert asking the user for access.
				switch newStatus {
				case .authorized:
					DispatchQueue.main.async {
						MediaPlayerManager.setDefaultLibraryIfAuthorized()
						self.viewDidLoad()
						tableView.performBatchUpdates({
							tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .middle)
							tableView.insertRows(at: self.indexPathsEnumeratedIn(section: 0, firstRow: 1, lastRow: self.tableView(tableView, numberOfRowsInSection: 0) - 1), with: .middle)
						}, completion: nil)
					}
				default:
					DispatchQueue.main.async { self.tableView.deselectRow(at: indexPath, animated: true) }
				}
			}
		default: // Denied or restricted.
			let settingsURL = URL(string: UIApplication.openSettingsURLString)!
			UIApplication.shared.open(settingsURL)
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
		
	}

}
