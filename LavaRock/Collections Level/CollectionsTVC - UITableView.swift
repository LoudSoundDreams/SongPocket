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
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	)-> Int {
		return newNumberOfRows(forSection: section)
	}
	
	final func newNumberOfRows(forSection section: Int) -> Int {
		switch contentState() {
		case .allowAccess, .loading:
			return 1
		case .blank:
			return 0
		case .noCollections:
			return 2
		case .oneOrMoreCollections:
			return sectionOfLibraryItems.items.count + numberOfRowsInSectionAboveLibraryItems
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch contentState() {
		case .allowAccess, .loading:
			return allowAccessOrLoadingCell(forRowAt: indexPath)
		case .blank: // Should never run
			return UITableViewCell()
		case .noCollections:
			switch indexPath.row {
			case 0:
				return noCollectionsPlaceholderCell(forRowAt: indexPath)
			case 1:
				return openMusicCell(forRowAt: indexPath)
			default: // Should never run
				return UITableViewCell()
			}
		case .oneOrMoreCollections:
			return collectionCell(forRowAt: indexPath)
		}
	}
	
	// MARK: "Allow Access" or "Loading…" Cell
	
	private func allowAccessOrLoadingCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Allow Access or Loading Cell",
			for: indexPath)
				as? AllowAccessOrLoadingCell
		else {
			return UITableViewCell()
		}
		
		switch contentState() {
		case .allowAccess:
			cell.allowAccessOrLoadingLabel.text = LocalizedString.allowAccessToMusic
			cell.allowAccessOrLoadingLabel.textColor = .tintColor(maybeResortTo: view.window)
			cell.spinnerView.stopAnimating()
			cell.isUserInteractionEnabled = true
			cell.accessibilityTraits.formUnion(.button)
			return cell
		case .loading:
			cell.allowAccessOrLoadingLabel.text = LocalizedString.loadingWithEllipsis
			cell.allowAccessOrLoadingLabel.textColor = .secondaryLabel
			cell.spinnerView.startAnimating()
			cell.isUserInteractionEnabled = false
			cell.accessibilityTraits.remove(.button)
			return cell
		case .blank, .noCollections, .oneOrMoreCollections: // Should never run
			return UITableViewCell()
		}
	}
	
	// MARK: "No Collections" Cells
	
	private func noCollectionsPlaceholderCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "No Collections Placeholder", for: indexPath)
		
		var contentConfiguration = UIListContentConfiguration.cell()
		contentConfiguration.text = LocalizedString.noCollectionsPlaceholder
		contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
		contentConfiguration.textProperties.color = .secondaryLabel
		cell.contentConfiguration = contentConfiguration
		
		return cell
	}
	
	private func openMusicCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Open Music", for: indexPath)
		
		var contentConfiguration = UIListContentConfiguration.cell()
		contentConfiguration.text = LocalizedString.openMusic
		contentConfiguration.textProperties.color = .tintColor(maybeResortTo: view.window)
		cell.contentConfiguration = contentConfiguration
		
		return cell
	}
	
	// MARK: Collection Cell
	
	private func collectionCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		// Get the data to put into the cell.
		guard let collection = libraryItem(for: indexPath) as? Collection else {
			return UITableViewCell()
		}
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: cellReuseIdentifier,
			for: indexPath)
				as? CollectionCell
		else {
			return UITableViewCell()
		}
		
		cell.titleLabel.text = collection.title
		let isInPlayer = isInPlayer(libraryItemFor: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		cell.apply(nowPlayingIndicator)
		
		if let albumMoverClipboard = albumMoverClipboard {
			if collection.objectID == albumMoverClipboard.ifOfSourceCollection {
				cell.titleLabel.textColor = UIColor.placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
				cell.isUserInteractionEnabled = false
				cell.accessibilityTraits.formUnion(.notEnabled)
			} else { // Undo changes made to the disabled cell
				cell.titleLabel.textColor = UIColor.label
				cell.isUserInteractionEnabled = true
				cell.accessibilityTraits.remove(.notEnabled)
			}
		} else {
			let renameFocusedCollectionAction = UIAccessibilityCustomAction(
				name: LocalizedString.rename,
				actionHandler: renameFocusedCollectionHandler)
			cell.accessibilityCustomActions = [renameFocusedCollectionAction]
//			refreshVoiceControlNames(for: cell)
		}
		
		return cell
	}
	
//	final func refreshVoiceControlNames(for cell: UITableViewCell) {
//		if isEditing {
//			cell.accessoryView?.accessibilityUserInputLabels = ["Rename", "Info", "Detail"] // I want to give the "rename" button a name for Voice Control, but this line of code doesn't do it.
//		} else {
//			cell.accessoryView?.accessibilityUserInputLabels = [""]
//		}
//	}
	
	private func renameFocusedCollectionHandler(
		_ sender: UIAccessibilityCustomAction
	) -> Bool {
		let indexPathsOfAllCollections = indexPaths(forIndexOfSectionOfLibraryItems: 0)
		let focusedIndexPath = indexPathsOfAllCollections.first {
			let cell = tableView.cellForRow(at: $0)
			return cell?.accessibilityElementIsFocused() ?? false
		}
		
		if let focusedIndexPath = focusedIndexPath {
			presentDialogToRenameCollection(at: focusedIndexPath)
			return true
		} else {
			return false
		}
	}
	
	// MARK: - Editing
	
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
