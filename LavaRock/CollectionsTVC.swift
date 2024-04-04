// 2020-05-04

import UIKit
import SwiftUI
import MusicKit

final class CollectionsTVC: LibraryTVC {
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [
			editButtonItem,
		]
		
		super.viewDidLoad()
		
		AppleMusic.loadingIndicator = self
	}
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		refreshPlaceholder()
		return 1
	}
	private func refreshPlaceholder() {
		contentUnavailableConfiguration = {
			guard MusicAuthorization.currentStatus == .authorized else {
				return UIHostingConfiguration {
					ContentUnavailableView {
					} description: {
						Text(LRString.welcome_message)
					} actions: {
						Button(LRString.welcome_button) {
							Task {
								await self.requestAccessToAppleMusic()
							}
						}
					}
				}
			}
			if viewModel.items.isEmpty {
				return UIHostingConfiguration {
					ContentUnavailableView {
					} actions: {
						Button(LRString.emptyLibrary_button) {
							let musicURL = URL(string: "music://")!
							UIApplication.shared.open(musicURL)
						}
					}
				}
			}
			return nil
		}()
	}
	private func requestAccessToAppleMusic() async {
		switch MusicAuthorization.currentStatus {
			case .authorized: break // Should never run
			case .notDetermined:
				switch await MusicAuthorization.request() {
					case .denied, .restricted, .notDetermined: break
					case .authorized: AppleMusic.integrate()
					@unknown default: break
				}
			case .denied, .restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
			@unknown default: break
		}
	}
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	)-> Int {
		return viewModel.items.count
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Folder", for: indexPath)
		let collectionsViewModel = viewModel as! CollectionsViewModel
		let collection = collectionsViewModel.collectionNonNil(atRow: indexPath.row)
		cell.contentConfiguration = UIHostingConfiguration {
			Text(collection.title ?? "")
		}.margins(.all, .zero)
		cell.backgroundColors_configureForLibraryItem()
		return cell
	}
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if !isEditing {
			openCollection(atIndexPath: indexPath)
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
	
	private func openCollection(atIndexPath: IndexPath) {
		navigationController?.pushViewController(
			{
				let albumsTVC = UIStoryboard(name: "AlbumsTVC", bundle: nil).instantiateInitialViewController() as! AlbumsTVC
				albumsTVC.viewModel = AlbumsViewModel(collection: (viewModel as! CollectionsViewModel).collectionNonNil(atRow: atIndexPath.row))
				return albumsTVC
			}(),
			animated: true)
	}
}
