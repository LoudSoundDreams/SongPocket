//
//  CollectionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer
import SwiftUI

extension CollectionsTVC {
	// MARK: - Numbers
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if #available(iOS 17, *) {
			switch viewState {
				case .removingCollectionRows, .someCollections:
					contentUnavailableConfiguration = nil
				case .allowAccess:
					contentUnavailableConfiguration = UIHostingConfiguration {
						ContentUnavailableView {
							Text(LRString.hiLetsPlay)
								.fontTitle2_bold()
						} description: {
							Text(LRString.ellipsis_yourAppleMusicLibrary_exclamationMark)
						} actions: {
							Button {
								Task {
									await self.requestAccessToAppleMusic()
								}
							} label: {
								Text(LRString.allowAccess)
							}
						}
					}
				case .loading:
					contentUnavailableConfiguration = UIHostingConfiguration {
						ProgressView()
					}
				case .emptyDatabase:
					contentUnavailableConfiguration = UIHostingConfiguration {
						ContentUnavailableView {
						} description: {
							Text(LRString.emptyDatabasePlaceholder)
						} actions: {
							Button {
								let musicURL = URL(string: "music://")!
								UIApplication.shared.open(musicURL)
							} label: {
								HStack {
									Text(LRString.appleMusic)
									Image(systemName: "arrow.up.forward")
								}
							}
						}
					}
			}
		}
		
		return 1
	}
	
	override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	)-> Int {
		return numberOfRows(forSection: section)
	}
	
	func numberOfRows(forSection section: Int) -> Int {
		switch viewState {
			case .allowAccess:
				if #available(iOS 17, *) {
					return 0
				} else {
					return 1
				}
			case .loading:
				if #available(iOS 17, *) {
					return 0
				} else {
					return 1
				}
			case .removingCollectionRows: return 0
			case .emptyDatabase:
				if #available(iOS 17, *) {
					return 0
				} else {
					return 2
				}
			case .someCollections:
				return viewModel.prerowCount() + viewModel.libraryGroup().items.count
		}
	}
	
	// MARK: - Cells
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
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
					.alignmentGuide_separatorTrailing()
					.accessibilityAddTraits(.isButton)
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
			case .removingCollectionRows: // Should never run
				return UITableViewCell()
			case .emptyDatabase:
				switch indexPath.row {
					case Self.emptyDatabaseInfoRow:
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "No Collections", for: indexPath)
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
							.alignmentGuide_separatorTrailing()
							.accessibilityAddTraits(.isButton)
						}
						return cell
				}
			case .someCollections: break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Collection",
			for: indexPath) as? CollectionCell
		else { return UITableViewCell() }
		
		let collectionsViewModel = viewModel as! CollectionsViewModel
		let collection = collectionsViewModel.collectionNonNil(atRow: indexPath.row)
		let (tinted, enabled) = { () -> (tint: Bool, enable: Bool) in
			switch purpose {
				case .willOrganizeAlbums: return (tint: false, enable: false)
				case .organizingAlbums(let clipboard):
					if clipboard.destinationCollections_ids.contains(collection.objectID) {
						return (tint: true, enable: true)
					}
					return (tint: false, enable: false)
				case .movingAlbums(let clipboard):
					if clipboard.idsOfSourceCollections.contains(collection.objectID) {
						return (tint: false, enable: false)
					}
					return (tint: false, enable: true)
				case .browsing: return (tint: false, enable: true)
			}
		}()
		cell.configure(with: collection, dimmed: !enabled)
		cell.editingAccessoryType = .detailButton
		cell.backgroundColor = tinted ? .tintColor.withAlphaComponent(.oneEighth) : .clear
		cell.isUserInteractionEnabled = enabled
		if enabled {
			cell.accessibilityTraits.subtract(.notEnabled)
		} else {
			cell.accessibilityTraits.formUnion(.notEnabled)
		}
		switch purpose {
			case .willOrganizeAlbums, .organizingAlbums, .movingAlbums: break
			case .browsing:
				cell.accessibilityCustomActions = [
					UIAccessibilityCustomAction(name: LRString.rename) { [weak self] action in
						guard
							let self,
							let focused = tableView.allIndexPaths().first(where: {
								let cell = tableView.cellForRow(at: $0)
								return cell?.accessibilityElementIsFocused() ?? false
							})
						else {
							return false
						}
						promptRename(at: focused)
						return true
					}
				]
		}
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
			case .willOrganizeAlbums, .organizingAlbums, .movingAlbums: return false
			case .browsing:
				switch viewState {
					case .allowAccess, .loading, .removingCollectionRows, .emptyDatabase: return false
					case .someCollections: return super.tableView(tableView, shouldBeginMultipleSelectionInteractionAt: indexPath)
				}
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch viewState {
			case .allowAccess, .loading, .removingCollectionRows: return indexPath
			case .emptyDatabase:
				if indexPath.row == Self.emptyDatabaseInfoRow {
					return nil
				}
				return indexPath
			case .someCollections: return super.tableView(tableView, willSelectRowAt: indexPath)
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch viewState {
			case .allowAccess:
				Task {
					await requestAccessToAppleMusic()
				}
			case .loading, .removingCollectionRows: return
			case .emptyDatabase:
				Task {
					let musicURL = URL(string: "music://")!
					let _ = await UIApplication.shared.open(musicURL) // If iOS shows the ‘Restore “Music”?’ alert, this returns `false`, but before the user responds to the alert, not after, unfortunately.
					
					tableView.deselectRow(at: indexPath, animated: true)
				}
			case .someCollections:
				super.tableView(tableView, didSelectRowAt: indexPath)
		}
	}
	
	private func requestAccessToAppleMusic() async {
		switch MPMediaLibrary.authorizationStatus() {
			case .notDetermined:
				let authorizationStatus = await MPMediaLibrary.requestAuthorization()
				
				switch authorizationStatus {
					case .authorized:
						await AppleMusic.integrateIfAuthorized()
					case .notDetermined, .denied, .restricted:
						tableView.deselectAllRows(animated: true)
					@unknown default:
						tableView.deselectAllRows(animated: true)
				}
			case .authorized: // Should never run
				break
			case .denied, .restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
				tableView.deselectAllRows(animated: true)
			@unknown default:
				tableView.deselectAllRows(animated: true)
		}
	}
}
