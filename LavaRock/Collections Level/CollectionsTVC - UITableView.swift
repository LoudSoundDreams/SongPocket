//
//  CollectionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension CollectionsTVC {
	
	// MARK: - Numbers
	
	final override func numberOfSections(in tableView: UITableView) -> Int {
		return (viewModel as? CollectionsViewModel)?.numberOfSections() ?? 0
	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	)-> Int {
		return (viewModel as? CollectionsViewModel)?.numberOfRows(
			forSection: section,
			contentState: contentState())
		?? 0
	}
	
	// MARK: - Headers
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		return (viewModel as? CollectionsViewModel)?.header(forSection: section)
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let isPlaying = sharedPlayer?.playbackState == .playing
		return (viewModel as? CollectionsViewModel)?.cell(
			forRowAt: indexPath,
			contentState: contentState(),
			isEditing: isEditing,
			albumMoverClipboard: albumMoverClipboard,
			isPlaying: isPlaying,
			renameFocusedCollectionAction: renameFocusedCollectionAction,
			accentColor: AccentColor.savedPreference(),
			tableView: tableView)
		?? UITableViewCell()
	}
	
	// MARK: - Editing
	
	final override func tableView(
		_ tableView: UITableView,
		canEditRowAt indexPath: IndexPath
	) -> Bool {
		return (viewModel as? CollectionsViewModel)?.canEditRow(at: indexPath) ?? false
	}
	
	final override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		return (viewModel as? CollectionsViewModel)?.targetIndexPathForMovingRow(
			at: sourceIndexPath,
			to: proposedDestinationIndexPath)
		?? sourceIndexPath
	}
	
	final override func tableView(
		_ tableView: UITableView,
		accessoryButtonTappedForRowWith indexPath: IndexPath
	) {
		presentDialogToRenameCollection(at: indexPath)
	}
	
	// MARK: - Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		if albumMoverClipboard != nil {
			return false
		} else {
			switch contentState() {
			case .allowAccess, .loading:
				return false
			case .blank: // Should never run
				return false
			case .noCollections:
				return false
			case .oneOrMoreCollections:
				return super.tableView(
					tableView,
					shouldBeginMultipleSelectionInteractionAt: indexPath)
			}
		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch contentState() {
		case .allowAccess:
			break
		case .loading:
			break
		case .blank: // Should never run
			break
		case .noCollections:
			break
		case .oneOrMoreCollections:
			return super.tableView(tableView, willSelectRowAt: indexPath)
		}
		
		return indexPath
	}
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch contentState() {
		case .allowAccess:
			didSelectAllowAccessRow(at: indexPath)
		case .loading, .blank: // Should never run
			return
		case .noCollections:
			if let musicURL = URL(string: "music://") {
				UIApplication.shared.open(musicURL)
			}
			tableView.deselectRow(at: indexPath, animated: true)
		case .oneOrMoreCollections:
			super.tableView(
				tableView,
				didSelectRowAt: indexPath)
		}
	}
	
	private func didSelectAllowAccessRow(at indexPath: IndexPath) {
		switch MPMediaLibrary.authorizationStatus() {
		case .notDetermined: // The golden opportunity.
			MPMediaLibrary.requestAuthorization { newStatus in // iOS 15: Use async/await
				switch newStatus {
				case .authorized:
					DispatchQueue.main.async {
						self.didReceiveAuthorizationForMusicLibrary()
					}
				default:
					DispatchQueue.main.async {
						self.tableView.deselectRow(at: indexPath, animated: true)
					}
				}
			}
		case .authorized:
			break
		default: // Denied or restricted.
			if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
				UIApplication.shared.open(settingsURL)
			}
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}
	
}
