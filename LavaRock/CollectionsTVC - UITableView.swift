//
//  CollectionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import SwiftUI

extension CollectionsTVC {
	override func tableView(
		_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath
	) {
		promptRename(at: indexPath)
	}
	
	// MARK: - Numbers
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		switch viewState {
			case .someCollections:
				contentUnavailableConfiguration = nil
			case .allowAccess:
				contentUnavailableConfiguration = UIHostingConfiguration {
					ContentUnavailableView {
					} description: {
						Text(LRString.welcome_message)
					} actions: {
						Button {
							Task {
								await self.requestAccessToAppleMusic()
							}
						} label: {
							Text(LRString.welcome_button)
						}
					}
				}
			case .loading:
				contentUnavailableConfiguration = UIHostingConfiguration {
					ProgressView().tint(.secondary)
				}
			case .emptyDatabase:
				contentUnavailableConfiguration = UIHostingConfiguration {
					ContentUnavailableView {
					} actions: {
						Button {
							let musicURL = URL(string: "music://")!
							UIApplication.shared.open(musicURL)
						} label: {
							Text(LRString.emptyLibrary_button)
						}
					}
				}
		}
		
		return 1
	}
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	)-> Int {
		switch viewState {
			case .allowAccess, .loading, .emptyDatabase: return 0
			case .someCollections:
				return viewModel.prerowCount() + viewModel.libraryGroup().items.count
		}
	}
	
	// MARK: - Cells
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier and selection segue.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Folder", for: indexPath)
		let collectionsViewModel = viewModel as! CollectionsViewModel
		let collection = collectionsViewModel.collectionNonNil(atRow: indexPath.row)
		let enabled = { () -> Bool in
			switch purpose {
				case .movingAlbums(let clipboard):
					if clipboard.idsOfSourceCollections.contains(collection.objectID) {
						return false
					}
					return true
				case .browsing: return true
			}
		}()
		cell.contentConfiguration = UIHostingConfiguration {
			CollectionRow(title: collection.title, collection: collection, dimmed: !enabled)
		}
		cell.editingAccessoryType = .detailButton
		cell.backgroundColors_configureForLibraryItem()
		cell.isUserInteractionEnabled = enabled
		if enabled {
			cell.accessibilityTraits.subtract(.notEnabled)
		} else {
			cell.accessibilityTraits.formUnion(.notEnabled)
		}
		switch purpose {
			case .movingAlbums: break
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
}
