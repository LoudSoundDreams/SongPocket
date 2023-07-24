//
//  FoldersTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer
import SwiftUI

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
			case .removingFolderRows:
				return 0
			case .emptyPlaceholder:
				return 2
			case .someFolders:
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
					case .folder:
						break
				}
			case .browsing:
				break
		}
		
		switch viewState {
			case .allowAccess:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Allow Access",
					for: indexPath)
				cell.contentConfiguration = UIHostingConfiguration {
					HStack {
						Text(LRString.allowAccessToMusic)
							.foregroundStyle(Color.accentColor)
						Spacer()
					}
					.accessibilityAddTraits(.isButton)
					.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
						viewDimensions[.trailing]
					}
				}
				return cell
			case .loading:
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Loading",
					for: indexPath) as? LoadingCell ?? UITableViewCell()
				cell.selectionStyle = .none
				return cell
			case .removingFolderRows: // Should never run
				return UITableViewCell()
			case .emptyPlaceholder:
				switch indexPath.row {
					case 0:
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(
							withIdentifier: "No Folders",
							for: indexPath)
						cell.selectionStyle = .none
						cell.contentConfiguration = UIHostingConfiguration {
							HStack {
								Text(LRString.emptyDatabasePlaceholder)
									.foregroundStyle(.secondary)
								Spacer()
							}
							.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
								viewDimensions[.trailing]
							}
						}
						return cell
					case 1:
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(
							withIdentifier: "Open Music",
							for: indexPath)
						cell.contentConfiguration = UIHostingConfiguration {
							LabeledContent {
								Image(systemName: "arrow.up.forward.app")
									.foregroundStyle(Color.accentColor)
							} label: {
								Text(LRString.appleMusic)
									.foregroundStyle(Color.accentColor)
							}
							.accessibilityAddTraits(.isButton)
							.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
								viewDimensions[.trailing]
							}
						}
						return cell
					default: // Should never run
						return UITableViewCell()
				}
			case .someFolders:
				break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Folder",
			for: indexPath) as? FolderCell
		else { return UITableViewCell() }
		
		let collection = foldersViewModel.folderNonNil(at: indexPath)
		let mode: FolderRowMode = {
			switch purpose {
				case .willOrganizeAlbums(let stickyNote):
					if stickyNote.idsOfSourceCollections.contains(collection.objectID) {
						return .modalDisabled
					} else {
						return .modal
					}
				case .organizingAlbums(let clipboard):
					if clipboard.idsOfSourceCollections.contains(collection.objectID) {
						return .modalDisabled
					} else if clipboard.idsOfCollectionsContainingMovedAlbums.contains(collection.objectID) {
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
					return .normal([renameFocused])
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
							.removingFolderRows, // Should never run
							.emptyPlaceholder:
						return false
					case .someFolders:
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
					case .folder:
						break
				}
			case .browsing:
				break
		}
		
		switch viewState {
			case
					.allowAccess,
					.loading, // Should never run
					.removingFolderRows, // Should never run
					.emptyPlaceholder:
				return indexPath
			case .someFolders:
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
					case .folder:
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
					.removingFolderRows: // Should never run
				return
			case .emptyPlaceholder:
				Task {
					let musicURL = URL(string: "music://")!
					let _ = await UIApplication.shared.open(musicURL) // If iOS shows the ‘Restore “Music”?’ alert, this returns `false`, but before the user responds to the alert, not after, unfortunately.
					
					tableView.deselectRow(at: indexPath, animated: true)
				}
			case .someFolders:
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
