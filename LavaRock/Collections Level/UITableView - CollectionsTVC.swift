//
//  UITableView - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension CollectionsTVC {
	
	private enum ContentState {
		case allowAccess
		case loading
		case justFinishedLoading
		case normal
	}
	
	private func contentState() -> ContentState {
		if MPMediaLibrary.authorizationStatus() != .authorized {
			return .allowAccess
		} else if didJustFinishLoading { // You must check didJustFinishLoading before checking isLoading.
			return .justFinishedLoading
		} else if isLoading {
			return .loading
		} else {
			return .normal
		}
	}
	
	final func refreshToReflectContentState(
		completion: (() -> ())?
	) {
		let onscreenIndexPaths = tableView.allIndexPaths()
		switch contentState() {
		case .allowAccess, .loading:
			let indexPathToKeep = IndexPath(row: 0, section: 0)
			switch onscreenIndexPaths.count {
			case 0: // Launch -> "Loading…"
				tableView.performBatchUpdates {
					tableView.insertRows(at: [indexPathToKeep], with: .fade)
				} completion: { _ in
					completion?()
				}
			case 1: // "Allow Access" -> "Loading…"
				tableView.performBatchUpdates {
					tableView.reloadRows(at: [indexPathToKeep], with: .fade)
				} completion: { _ in
					completion?()
				}
			default: // Currently unused
				let indexPathsToDelete = Array(onscreenIndexPaths.dropFirst())
				tableView.performBatchUpdates {
					tableView.deleteRows(at: indexPathsToDelete, with: .fade)
					tableView.reloadRows(at: [indexPathToKeep], with: .fade)
				} completion: { _ in
					completion?()
				}
			}
		case .justFinishedLoading: // "Loading…" -> empty
			tableView.performBatchUpdates {
				tableView.deleteRows(at: onscreenIndexPaths, with: .middle)
			} completion: { _ in
				completion?()
			}
		case .normal: // Currently unused
			completion?()
		}
	}
	
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
			return super.tableView(tableView, numberOfRowsInSection: section)
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch contentState() {
		case .allowAccess, .loading:
			return allowAccessOrLoadingCell()
		case .justFinishedLoading:
			return UITableViewCell() // Should never run
		case .normal:
			return collectionCell(forRowAt: indexPath)
		}
	}
	
	// MARK: "Allow Access" or "Loading…" Cell
	
	private func allowAccessOrLoadingCell() -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access or Loading Cell") as? AllowAccessOrLoadingCell else {
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
		case .justFinishedLoading, .normal:
			return UITableViewCell() // Should never run
		}
	}
	
	// MARK: Collection Cell
	
	private func collectionCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		// Get the data to put into the cell.
		guard let collection = libraryItem(for: indexPath) as? Collection else {
			return UITableViewCell()
		}
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? CollectionCell else {
			return UITableViewCell()
		}
		
		cell.titleLabel.text = collection.title
		let isInPlayer = isInPlayer(libraryItemFor: indexPath)
		let cellNowPlayingIndicator = PlayerManager.nowPlayingIndicator(
			isInPlayer: isInPlayer)
		cell.applyNowPlayingIndicator(cellNowPlayingIndicator)
		
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
			let renameCollectionAccessibilityCustomAction = UIAccessibilityCustomAction(
				name: LocalizedString.rename,
				actionHandler: renameAccessibilityFocusedCollection)
			cell.accessibilityCustomActions = [renameCollectionAccessibilityCustomAction]
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
	
	private func renameAccessibilityFocusedCollection(_ sender: UIAccessibilityCustomAction) -> Bool {
		var indexPathOfCollectionToRename: IndexPath?
		let indexPathsOfAllCollections = indexPaths(forIndexOfSectionOfLibraryItems: 0)
		for indexPath in indexPathsOfAllCollections {
			if
				let cell = tableView.cellForRow(at: indexPath),
				cell.accessibilityElementIsFocused()
			{
				indexPathOfCollectionToRename = indexPath
				break
			}
		}
		
		if let indexPathOfCollectionToRename = indexPathOfCollectionToRename {
			renameCollection(at: indexPathOfCollectionToRename)
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
		
		super.tableView(tableView, didSelectRowAt: indexPath) // Includes refreshBarButtons() in editing mode.
	}
	
}
