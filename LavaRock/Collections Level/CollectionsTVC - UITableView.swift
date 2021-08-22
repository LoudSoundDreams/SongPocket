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
	
//	final override func numberOfSections(in tableView: UITableView) -> Int {
//		return (viewModel as? CollectionsViewModel)?.numberOfSections() ?? 0
//	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	)-> Int {
		return newNumberOfRows(forSection: section)
	}
	
	final func newNumberOfRows(forSection section: Int) -> Int {
//		guard let sectionCase = CollectionsSection(rawValue: section) else {
//			return 0
//		}
//
//		switch sectionCase {
//		case .all:
//			return 1
//		case .collections:
			
			
			switch contentState() {
			case .allowAccess, .loading:
				return 1
			case .blank:
				return 0
			case .noCollections:
				return 2
			case .oneOrMoreCollections:
				return viewModel.numberOfRows(inSection: section)
			}
			
			
//		}
	}
	
	// MARK: - Headers
	
//	final override func tableView(
//		_ tableView: UITableView,
//		titleForHeaderInSection section: Int
//	) -> String? {
//		return (viewModel as? CollectionsViewModel)?.header(forSection: section)
//	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
//		guard let sectionCase = CollectionsSection(rawValue: indexPath.section) else {
//			return UITableViewCell()
//		}
//
//		switch sectionCase {
//		case .all:
//			return allCell(forRowAt: indexPath)
//		case .collections:
			
			
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
			
			
//		}
	}
	
	
	// MARK: "All" Cell
	
	private func allCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "All",
			for: indexPath) as? AllCollectionsCell
		else {
			return UITableViewCell()
		}
		
		func disable() {
			cell.allLabel.textColor = .placeholderText
			cell.isUserInteractionEnabled = false
			cell.accessoryType = .none
		}
		
		func enable() {
			cell.allLabel.textColor = .label
			cell.isUserInteractionEnabled = true
			cell.accessoryType = .disclosureIndicator
		}
		
		if isEditing {
			disable()
		} else {
			switch contentState() {
			case .allowAccess, .loading, .blank, .noCollections:
				disable()
			case .oneOrMoreCollections:
				enable()
			}
		}
		
		return cell
	}
	
	// MARK: "Allow Access" or "Loading…" Cell
	
	private func allowAccessOrLoadingCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Allow Access or Loading",
			for: indexPath) as? AllowAccessOrLoadingCell
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
	
	// The cell in the storyboard is completely default except for the reuse identifier.
	private func noCollectionsPlaceholderCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "No Collections Placeholder", for: indexPath)
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.noCollectionsPlaceholder
		configuration.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
		configuration.textProperties.color = .secondaryLabel
		cell.contentConfiguration = configuration
		
		cell.isUserInteractionEnabled = false
		
		return cell
	}
	
	// The cell in the storyboard is completely default except for the reuse identifier.
	private func openMusicCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Open Music", for: indexPath)
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.openMusic
		configuration.textProperties.color = .tintColor(maybeResortTo: view.window)
		cell.contentConfiguration = configuration
		
		cell.accessibilityTraits.formUnion(.button)
		
		return cell
	}
	
	// MARK: Collection Cell
	
	private func collectionCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let collection = viewModel.item(at: indexPath) as? Collection else {
			return UITableViewCell()
		}
		
		// Title
		let collectionTitle = collection.title
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(libraryItemFor: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: Self.libraryItemCellReuseIdentifier,
			for: indexPath) as? CollectionCell
		else {
			return UITableViewCell()
		}
		
		cell.titleLabel.text = collectionTitle
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
		let indexPathsOfAllCollections = viewModel.indexPathsForAllItems()
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
	
//	final override func tableView(
//		_ tableView: UITableView,
//		canEditRowAt indexPath: IndexPath
//	) -> Bool {
//		return (viewModel as? CollectionsViewModel)?.canEditRow(at: indexPath) ?? false
//	}
	
//	final override func tableView(
//		_ tableView: UITableView,
//		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
//		toProposedIndexPath proposedDestinationIndexPath: IndexPath
//	) -> IndexPath {
//		return (viewModel as? CollectionsViewModel)?.targetIndexPathForMovingRow(
//			at: sourceIndexPath,
//			to: proposedDestinationIndexPath)
//		?? sourceIndexPath
//	}
	
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
