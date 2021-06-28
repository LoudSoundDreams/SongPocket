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
	
	// Remember to call refreshBarButtons() before returning. super also does it.
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	)-> Int {
		switch contentState() {
		case .allowAccess, .loading:
			refreshBarButtons()
			tableView.backgroundView = nil
			return 1
		case .justFinishedLoading:
			refreshBarButtons()
			tableView.backgroundView = nil
			return 0
		case .normal:
			return super.tableView(
				tableView,
				numberOfRowsInSection: section)
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
		case .justFinishedLoading: // Should never run
			return UITableViewCell()
		case .normal:
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
			cell.allowAccessOrLoadingLabel.textColor = view.window?.tintColor
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
		case .justFinishedLoading, .normal: // Should never run
			return UITableViewCell()
		}
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
//			cell.accessoryView?.accessibilityUserInputLabels = ["Info", "Detail", "Rename"] // I want to give the "rename collection" button a name for Voice Control, but this line of code doesn't do it.
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
			renameCollection(at: focusedIndexPath)
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
		renameCollection(at: indexPath)
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
			case .justFinishedLoading: // Should never run
				break
			case .normal:
				break
			}
			return super.tableView(
				tableView,
				shouldBeginMultipleSelectionInteractionAt: indexPath)
		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			break
		case .notDetermined: // The golden opportunity.
			MPMediaLibrary.requestAuthorization { newStatus in // iOS 15: Use async/await
				switch newStatus {
				case .authorized:
					DispatchQueue.main.async { self.didReceiveAuthorizationForMusicLibrary() }
				default:
					DispatchQueue.main.async { self.tableView.deselectRow(at: indexPath, animated: true) }
				}
			}
		default: // Denied or restricted.
			if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
				UIApplication.shared.open(settingsURL)
			}
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		super.tableView(
			tableView,
			didSelectRowAt: indexPath) // Includes refreshBarButtons() in editing mode.
	}
	
}
