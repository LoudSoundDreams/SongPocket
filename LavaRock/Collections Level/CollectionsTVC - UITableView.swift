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
		return numberOfRows(forSection: section)
	}
	
	final func numberOfRows(forSection section: Int) -> Int {
		switch viewState {
		case
				.allowAccess,
				.loading:
			return 1
		case .wasLoadingOrNoCollections:
			return 0
		case .noCollections:
			return 2
		case .someCollections:
			return viewModel.numberOfRows(forSection: section)
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			if viewModel.isPrerow(indexPath: indexPath) {
				return tableView.dequeueReusableCell(
					withIdentifier: "Create Collection",
					for: indexPath) as? CreateCollectionCell ?? UITableViewCell()
			} else {
				break
			}
		case .browsing:
			break
		}
		
		switch viewState {
		case .allowAccess:
			return tableView.dequeueReusableCell(
				withIdentifier: "Allow Access",
				for: indexPath) as? AllowAccessCell ?? UITableViewCell()
		case .loading:
			return tableView.dequeueReusableCell(
				withIdentifier: "Loading",
				for: indexPath) as? LoadingCell ?? UITableViewCell()
		case .wasLoadingOrNoCollections: // Should never run
			return UITableViewCell()
		case .noCollections:
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
		case .someCollections:
			return collectionCell(forRowAt: indexPath)
		}
	}
	
	private func collectionCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let collection = viewModel.itemNonNil(at: indexPath) as? Collection else {
			return UITableViewCell()
		}
		
		// "Now playing" indicator
		let isInPlayer = (viewModel as? CollectionsViewModel)?.isInPlayer(anyIndexPath: indexPath) ?? false
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Collection",
			for: indexPath) as? CollectionCell
		else {
			return UITableViewCell()
		}
		
		let mode: CollectionCell.Mode = {
			switch purpose {
			case .organizingAlbums(let clipboard):
				if clipboard.idsOfSourceCollections.contains(collection.objectID) {
					return .modalDisabled
				} else if clipboard.idsOfDestinationCollections.contains(collection.objectID) {
					return .modalTinted
				} else {
					return .modal
				}
			case .movingAlbums(let clipboard):
				if FeatureFlag.multicollection {
					if clipboard.idsOfSourceCollections.contains(collection.objectID) {
						return .modalTinted
					} else {
						return .modal
					}
				} else {
					if clipboard.idsOfSourceCollections.contains(collection.objectID) {
						return .modalDisabled
					} else {
						return .modal
					}
				}
			case .browsing:
				return .normal
			}
		}()
		cell.configure(
			with: collection,
			mode: mode,
			renameFocusedCollectionAction: renameFocusedCollectionAction)
		cell.applyNowPlayingIndicator(nowPlayingIndicator)
		
		return cell
	}
	
	// MARK: - Editing
	
	final override func tableView(
		_ tableView: UITableView,
		accessoryButtonTappedForRowWith indexPath: IndexPath
	) {
		confirmRename(at: indexPath)
	}
	
	// MARK: - Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		switch purpose {
		case .organizingAlbums:
			return false
		case .movingAlbums:
			return false
		case .browsing:
			switch viewState {
			case
					.allowAccess,
					.loading,
					.wasLoadingOrNoCollections, // Should never run
					.noCollections:
				return false
			case .someCollections:
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
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			if viewModel.isPrerow(indexPath: indexPath) {
				return indexPath
			} else {
				break
			}
		case .browsing:
			break
		}
		
		switch viewState {
		case
				.allowAccess,
				.loading, // Should never run
				.wasLoadingOrNoCollections, // Should never run
				.noCollections: // Should never run for `NoCollectionsPlaceholderCell`
			return indexPath
		case .someCollections:
			return super.tableView(tableView, willSelectRowAt: indexPath)
		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			if viewModel.isPrerow(indexPath: indexPath) {
				createAndConfirm()
				return
			} else {
				break
			}
		case .browsing:
			break
		}
		
		switch viewState {
		case .allowAccess:
			didSelectAllowAccessRow(at: indexPath)
		case
				.loading,
				.wasLoadingOrNoCollections: // Should never run
			return
		case .noCollections:
			if let cell = tableView.cellForRow(at: indexPath) as? OpenMusicCell {
				cell.didSelect()
			}
			tableView.deselectRow(at: indexPath, animated: true)
		case .someCollections:
			super.tableView(tableView, didSelectRowAt: indexPath)
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
				case
						.notDetermined,
						.denied,
						.restricted:
					DispatchQueue.main.async {
						self.tableView.deselectRow(at: indexPath, animated: true)
					}
				@unknown default:
					DispatchQueue.main.async {
						self.tableView.deselectRow(at: indexPath, animated: true)
					}
				}
			}
		case .authorized:
			break
		case
				.denied,
				.restricted:
			if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
				UIApplication.shared.open(settingsURL)
			}
			tableView.deselectRow(at: indexPath, animated: true)
		@unknown default:
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}
	
}
