//
//  FoldersTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension FoldersTVC {
	// MARK: - Numbers
	
	override func numberOfSections(
		in tableView: UITableView
	) -> Int {
		return viewModel.groups.count
	}
	
	override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	)-> Int {
		return numberOfRows(forSection: section)
	}
	
	func numberOfRows(forSection section: Int) -> Int {
		switch viewState {
			case
					.allowAccess,
					.loading:
				return 1
			case .removingRowsInCollectionsSection:
				return 0
			case .emptyPlaceholder:
				return 2
			case .someCollections:
				return (viewModel as! FoldersViewModel).numberOfRows()
		}
	}
	
	// MARK: - Cells
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let foldersViewModel = viewModel as? FoldersViewModel else { return UITableViewCell() }
		
		switch purpose {
			case .willOrganizeAlbums:
				break
			case .organizingAlbums:
				break
			case .movingAlbums:
				let rowCase = foldersViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow(let prerow):
						switch prerow {
							case .createFolder:
								return tableView.dequeueReusableCell(
									withIdentifier: "Create Folder",
									for: indexPath) as? CreateFolderCell ?? UITableViewCell()
						}
					case .collection:
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
			case .removingRowsInCollectionsSection: // Should never run
				return UITableViewCell()
			case .emptyPlaceholder:
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
				break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Collection",
			for: indexPath) as? CollectionCell
		else { return UITableViewCell() }
		
		let collection = foldersViewModel.collectionNonNil(at: indexPath)
		let mode: FolderRowMode = {
			switch purpose {
				case .willOrganizeAlbums(let stickyNote):
					if stickyNote.idsOfSourceFolders.contains(collection.objectID) {
						return .modalDisabled
					} else {
						return .modal
					}
				case .organizingAlbums(let clipboard):
					if clipboard.idsOfSourceFolders.contains(collection.objectID) {
						return .modalDisabled
					} else if clipboard.idsOfFoldersContainingMovedAlbums.contains(collection.objectID) {
						return .modalTinted
					} else {
						return .modal
					}
				case .movingAlbums(let clipboard):
					if clipboard.idsOfSourceCollections.contains(collection.objectID) {
						return .modalDisabled
					} else {
						return .modal
					}
				case .browsing:
					return .normal([renameFocusedCollectionAction])
			}
		}()
		cell.configure(
			with: collection,
			mode: mode
		)
		
		return cell
	}
	
	// MARK: - Editing
	
	override func tableView(
		_ tableView: UITableView,
		accessoryButtonTappedForRowWith indexPath: IndexPath
	) {
		promptRename(at: indexPath)
	}
	
	// MARK: - Selecting
	
	override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		switch purpose {
			case .willOrganizeAlbums:
				return false
			case .organizingAlbums:
				return false
			case .movingAlbums:
				return false
			case .browsing:
				switch viewState {
					case
							.allowAccess,
							.loading,
							.removingRowsInCollectionsSection, // Should never run
							.emptyPlaceholder:
						return false
					case .someCollections:
						return super.tableView(
							tableView,
							shouldBeginMultipleSelectionInteractionAt: indexPath)
				}
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch purpose {
			case .willOrganizeAlbums:
				return nil
			case .organizingAlbums:
				break
			case .movingAlbums:
				guard let foldersViewModel = viewModel as? FoldersViewModel else {
					return nil
				}
				let rowCase = foldersViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow(let prerow):
						switch prerow {
							case .createFolder:
								return indexPath
						}
					case .collection:
						break
				}
			case .browsing:
				break
		}
		
		switch viewState {
			case
					.allowAccess,
					.loading, // Should never run
					.removingRowsInCollectionsSection, // Should never run
					.emptyPlaceholder: // Should never run for `NoCollectionsPlaceholderCell`
				return indexPath
			case .someCollections:
				return super.tableView(tableView, willSelectRowAt: indexPath)
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch purpose {
			case .willOrganizeAlbums:
				break
			case .organizingAlbums:
				break
			case .movingAlbums:
				guard let foldersViewModel = viewModel as? FoldersViewModel else { return }
				let rowCase = foldersViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow(let prerow):
						switch prerow {
							case .createFolder:
								createAndOpen()
								return
						}
					case .collection:
						break
				}
			case .browsing:
				break
		}
		
		switch viewState {
			case .allowAccess:
				Task {
					await didSelectAllowAccessRow(at: indexPath)
				}
			case
					.loading,
					.removingRowsInCollectionsSection: // Should never run
				return
			case .emptyPlaceholder:
				guard tableView.cellForRow(at: indexPath) is OpenMusicCell else {
					tableView.deselectRow(at: indexPath, animated: true)
					return
				}
				Task {
					let _ = await UIApplication.shared.open(.music) // If iOS shows the ‘Restore “Music”?’ alert, this returns `false`, but before the user responds to the alert, not after, unfortunately.
					
					tableView.deselectRow(at: indexPath, animated: true)
				}
			case .someCollections:
				super.tableView(tableView, didSelectRowAt: indexPath)
		}
	}
	
	private func didSelectAllowAccessRow(at indexPath: IndexPath) async {
		switch MPMediaLibrary.authorizationStatus() {
			case .notDetermined:
				let authorizationStatus = await MPMediaLibrary.requestAuthorization()
				
				switch authorizationStatus {
					case .authorized:
						await AppleMusic.integrateIfAuthorized()
					case
							.notDetermined,
							.denied,
							.restricted:
						tableView.deselectRow(at: indexPath, animated: true)
					@unknown default:
						tableView.deselectRow(at: indexPath, animated: true)
				}
			case .authorized: // Should never run
				break
			case
					.denied,
					.restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
				tableView.deselectRow(at: indexPath, animated: true)
			@unknown default:
				tableView.deselectRow(at: indexPath, animated: true)
		}
	}
}
