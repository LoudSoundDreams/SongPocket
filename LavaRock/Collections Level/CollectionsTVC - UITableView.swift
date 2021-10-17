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
//		return Section.allCases.count
		
		
		return 1
	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	)-> Int {
		return numberOfRows(forSection: section)
	}
	
	final func numberOfRows(forSection section: Int) -> Int {
//		guard let sectionCase = Section(rawValue: section) else {
//			return 0
//		}
//
//		switch sectionCase {
//		case .all:
//			return 1
//		case .collections:
		
		
		switch libraryState {
		case .allowAccess, .loading:
			return 1
		case .blank:
			return 0
		case .noMusic:
			return 2
		case .someMusic:
			return viewModel.numberOfRows(forSection: section)
		}
		
		
//		}
	}
	
	// MARK: - Headers
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
//		guard let sectionCase = Section(rawValue: section) else {
//			return nil
//		}
//
//		switch sectionCase {
//		case .all:
//			return nil
//		case .collections:
//			return LocalizedString.collections
//		}
		
		
		return nil
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
//		guard let sectionCase = Section(rawValue: indexPath.section) else {
//			return UITableViewCell()
//		}
//
//		switch sectionCase {
//		case .all:
//			return allCell(forRowAt: indexPath)
//		case .collections:
		
		
		switch libraryState {
		case .allowAccess:
			return tableView.dequeueReusableCell(
				withIdentifier: "Allow Access",
				for: indexPath) as? AllowAccessCell ?? UITableViewCell()
		case .loading:
			return tableView.dequeueReusableCell(
				withIdentifier: "Loading",
				for: indexPath) as? LoadingCell ?? UITableViewCell()
		case .blank: // Should never run
			return UITableViewCell()
		case .noMusic:
			switch indexPath.row {
			case 0:
				return tableView.dequeueReusableCell(
					withIdentifier: "No Collections",
					for: indexPath) as? NoCollectionsPlaceholderCell ?? UITableViewCell()
			case 1:
				return tableView.dequeueReusableCell(
					withIdentifier: "Open Music",
					for: indexPath) as? OpenMusicCell ?? UITableViewCell()
			default: // Should never run
				return UITableViewCell()
			}
		case .someMusic:
			return collectionCell(forRowAt: indexPath)
		}
		
		
//		}
	}
	
	
	private func allCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "All",
			for: indexPath) as? AllCollectionsCell
		else {
			return UITableViewCell()
		}
		
		if isEditing {
			cell.accessoryType = .none
		} else {
			cell.accessoryType = .disclosureIndicator
			
			switch libraryState {
			case .allowAccess, .loading, .blank, .noMusic:
				cell.allLabel.textColor = .placeholderText
				cell.disableWithAccessibilityTrait()
			case .someMusic:
				cell.allLabel.textColor = .label
				cell.enableWithAccessibilityTrait()
			}
		}
		
		return cell
	}
	
	
	private func collectionCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let collection = viewModel.item(at: indexPath) as? Collection else {
			return UITableViewCell()
		}
		
		// "Now playing" indicator
		let isInPlayer = (viewModel as? CollectionsViewModel)?.isInPlayer(libraryItemAt: indexPath) ?? false
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Collection",
			for: indexPath) as? CollectionCell
		else {
			return UITableViewCell()
		}
		
		let idOfSourceCollection = albumMoverClipboard?.idOfSourceCollection
		cell.configure(
			with: collection,
			isMovingAlbumsFromCollectionWith: idOfSourceCollection,
			renameFocusedCollectionAction: renameFocusedCollectionAction)
		cell.applyNowPlayingIndicator(nowPlayingIndicator)
		
		return cell
	}
	
	// MARK: - Editing
	
	final override func tableView(
		_ tableView: UITableView,
		canEditRowAt indexPath: IndexPath
	) -> Bool {
//		guard let sectionCase = Section(rawValue: indexPath.section) else {
//			return false
//		}
//
//		switch sectionCase {
//		case .all:
//			return false
//		case .collections:
		
		
		return viewModel.canEditRow(at: indexPath)
		
		
//		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
//		guard let proposedSectionCase = Section(rawValue: proposedDestinationIndexPath.section) else {
//			return sourceIndexPath
//		}
//
//		switch proposedSectionCase {
//		case .all:
//			return sourceIndexPath
//		case .collections:
		
		
		return viewModel.targetIndexPathForMovingRow(
			at: sourceIndexPath,
			to: proposedDestinationIndexPath)
		
		
//		}
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
			switch libraryState {
			case .allowAccess, .loading:
				return false
			case .blank: // Should never run
				return false
			case .noMusic:
				return false
			case .someMusic:
				return viewModel.shouldBeginMultipleSelectionInteraction(at: indexPath)
			}
		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch libraryState {
		case .allowAccess:
			break
		case .loading:
			break
		case .blank: // Should never run
			break
		case .noMusic:
			break
		case .someMusic:
			return viewModel.willSelectRow(at: indexPath)
		}
		
		return indexPath
	}
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch libraryState {
		case .allowAccess:
			didSelectAllowAccessRow(at: indexPath)
		case .loading, .blank: // Should never run
			return
		case .noMusic:
			if let musicURL = URL(string: "music://") {
				UIApplication.shared.open(musicURL)
			}
			tableView.deselectRow(at: indexPath, animated: true)
		case .someMusic:
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
