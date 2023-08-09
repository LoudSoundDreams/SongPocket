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
			case .emptyDatabase:
				let _ = Self.emptyDatabaseInfoRow
				return 2
			case .someFolders:
				return viewModel.prerowCount() + viewModel.libraryGroup().items.count
		}
	}
	
	// MARK: - Cells
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let foldersViewModel = viewModel as! FoldersViewModel
		
		switch purpose {
			case .willOrganizeAlbums:
				break
			case .organizingAlbums:
				break
			case .movingAlbums:
				let rowCase = foldersViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow:
						return tableView.dequeueReusableCell(
							withIdentifier: "Create Folder",
							for: indexPath) as? CreateFolderCell ?? UITableViewCell()
					case .folder:
						break
				}
			case .browsing:
				break
		}
		
		switch viewState {
			case .allowAccess:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access", for: indexPath)
				cell.contentConfiguration = UIHostingConfiguration {
					HStack {
						Text(LRString.allowAccessToAppleMusic)
							.foregroundStyle(Color.accentColor)
						Spacer()
					}
					.accessibilityAddTraits(.isButton)
					.alignmentGuide_separatorTrailing()
				}
				return cell
			case .loading:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Loading", for: indexPath)
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					HStack {
						Text(LRString.loadingEllipsis)
							.foregroundStyle(.secondary)
						Spacer()
						ProgressView()
					}
					.alignmentGuide_separatorTrailing()
				}
				return cell
			case .removingFolderRows: // Should never run
				return UITableViewCell()
			case .emptyDatabase:
				switch indexPath.row {
					case Self.emptyDatabaseInfoRow:
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "No Folders", for: indexPath)
						cell.selectionStyle = .none
						cell.contentConfiguration = UIHostingConfiguration {
							HStack {
								Text(LRString.emptyDatabasePlaceholder)
									.foregroundStyle(.secondary)
								Spacer()
							}
							.alignmentGuide_separatorTrailing()
						}
						return cell
					default:
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Open Music", for: indexPath)
						cell.contentConfiguration = UIHostingConfiguration {
							LabeledContent {
								Image(systemName: "arrow.up.forward.app")
									.foregroundStyle(Color.accentColor)
							} label: {
								Text(LRString.appleMusic)
									.foregroundStyle(Color.accentColor)
							}
							.accessibilityAddTraits(.isButton)
							.alignmentGuide_separatorTrailing()
						}
						return cell
				}
			case .someFolders:
				break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Folder",
			for: indexPath) as? FolderCell
		else { return UITableViewCell() }
		
		let collection = foldersViewModel.folderNonNil(atRow: indexPath.row)
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
							.emptyDatabase:
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
				let foldersViewModel = viewModel as! FoldersViewModel
				let rowCase = foldersViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow:
						return indexPath
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
					.removingFolderRows: // Should never run
				return indexPath
			case .emptyDatabase:
				if indexPath.row == Self.emptyDatabaseInfoRow {
					return nil
				}
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
				let foldersViewModel = viewModel as! FoldersViewModel
				let rowCase = foldersViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow:
						createAndOpen()
						return
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
			case .emptyDatabase:
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
