//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

final class SongsTVC:
	LibraryTVC,
	NavigationItemTitleCustomizer
{
	
	// MARK: - Properties
	
	var areSongActionsPresented = false // If we have to refresh to reflect changes in the Apple Music library, we'll dismiss this action sheet first.
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Song"
		numberOfRowsAboveIndexedLibraryItems = 2
	}
	
	// MARK: Setting Up UI
	
	override func setUpUI() {
		super.setUpUI()
		
		refreshNavigationItemTitle()
		navigationItemButtonsEditingModeOnly = [floatToTopButton, sortButton]
		sortOptions = ["Track Number"]
	}
	
	func refreshNavigationItemTitle() {
		if let containingAlbum = containerOfData as? Album {
			title = containingAlbum.titleFormattedOrPlaceholder()
		}
	}
	
	// MARK: - Taking Action on Songs
	
	func showSongActions(for song: Song) {
		areSongActionsPresented = true
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		let playAlbumStartingHereAction = UIAlertAction(
			title: "Play Starting Here",
			style: .destructive,
			handler: playAlbumStartingAtSelectedSong
		)
		let enqueueSongAction = UIAlertAction(
			title: "Add to Queue",
			style: .default,
			handler: enqueueSelectedSong
		)
		let enqueueAlbumStartingHereAction = UIAlertAction(
			title: "Add to Queue Starting Here",
			style: .default,
			handler: enqueueAlbumStartingAtSelectedSong
		)
		
		// Disable the actions that we shouldn't offer for the last song in the section.
		if song == indexedLibraryItems.last {
			enqueueAlbumStartingHereAction.isEnabled = false
		}
		
		actionSheet.addAction(playAlbumStartingHereAction)
		actionSheet.addAction(enqueueAlbumStartingHereAction)
		actionSheet.addAction(enqueueSongAction)
		actionSheet.addAction(
			UIAlertAction(
				title: "Cancel",
				style: .cancel,
				handler: { _ in
					self.tableView.deselectAllRows(animated: true)
					self.areSongActionsPresented = false
				}
			)
		)
		present(actionSheet, animated: true, completion: nil)
	}
	
	// MARK: Song Actions
	
	func playAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		tableView.deselectAllRows(animated: true)
		areSongActionsPresented = false
		
		
	}
	
	func enqueueAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		tableView.deselectAllRows(animated: true)
		areSongActionsPresented = false
		
		
	}
	
	func enqueueSelectedSong(_ sender: UIAlertAction) {
		tableView.deselectAllRows(animated: true)
		areSongActionsPresented = false
		
		
	}
	
}
