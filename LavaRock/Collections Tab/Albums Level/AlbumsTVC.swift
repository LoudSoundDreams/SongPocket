//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class AlbumsTVC: LibraryTVC, AlbumMover, NavigationItemTitleCustomizer {
	
	// MARK: Properties
	
	// "Constants"
	static let rowHeightInPoints = 44 * 3
	@IBOutlet var startMovingAlbumsButton: UIBarButtonItem!
	@IBOutlet var moveAlbumsHereButton: UIBarButtonItem!
	
	// Variables
	var moveAlbumsClipboard: MoveAlbumsClipboard?
	var newCollectionDetector: MovedAlbumsToNewCollectionDetector?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Album"
	}
	
	override func setUpUI() {
		super.setUpUI()
		
		customizeNavigationItemTitle()
		
		tableView.rowHeight = CGFloat(Self.rowHeightInPoints)
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			navigationItem.prompt = MoveAlbumsClipboard.moveAlbumsModePrompt(numberOfAlbumsBeingMoved: moveAlbumsClipboard.idsOfAlbumsBeingMoved.count)
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
			tableView.allowsSelection = false
			
			navigationController?.isToolbarHidden = false
			
		} else {
			navigationItemButtonsEditModeOnly = [floatToTopButton, startMovingAlbumsButton]
			
			navigationController?.isToolbarHidden = true
		}
	}
	
	func customizeNavigationItemTitle() {
		if let containingCollection = containerOfData as? Collection {
			title = containingCollection.title
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if moveAlbumsClipboard != nil {
		} else {
			if activeLibraryItems.isEmpty {
				performSegue(withIdentifier: "Exit Empty Collection", sender: nil)
			}
		}
	}
	
	@IBAction func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {
		isEditing = false
		
		loadSavedLibraryItems()
		tableView.reloadData()
		
		viewDidAppear(true) // Exits this collection if it's now empty.
	}
	
	// MARK: Loading Data
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		// Get the data to put into the cell.
		
		let album = activeLibraryItems[indexPath.row] as! Album
		let representativeItem = album.mpMediaItemCollection()?.representativeItem
		
		let cellImage = representativeItem?.artwork?.image(at: CGSize(width: Self.rowHeightInPoints, height: Self.rowHeightInPoints)) // nil removes the placeholder image in the storyboard.
		let cellTitle = album.titleFormattedOrPlaceholder()
		let cellSubtitle = album.releaseDateEstimateFormatted()
		
		// Make, configure, and return the cell.
		
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! AlbumCell
		
		cell.artworkImageView.image = cellImage
		cell.titleLabel.text = cellTitle
		cell.yearLabel.text = cellSubtitle
		
		if moveAlbumsClipboard != nil {
			cell.accessoryType = .none
		}
		
		return cell
    }
	
	// MARK: - Events
	
	override func refreshNavigationBarButtons() {
		super.refreshNavigationBarButtons()
		
		if isEditing {
			updateStartMovingAlbumsButton()
		}
	}
	
	func updateStartMovingAlbumsButton() {
		if tableView.indexPathsForSelectedRows == nil {
			startMovingAlbumsButton.title = "Move All"
		} else {
			startMovingAlbumsButton.title = "Move"
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Moved Albums",
		   let nonmodalAlbumsTVC = segue.destination as? AlbumsTVC,
		   let newCollectionDetector = newCollectionDetector,
		   newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear
		{
			nonmodalAlbumsTVC.newCollectionDetector!.shouldDetectNewCollectionsOnNextViewWillAppear = true
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
