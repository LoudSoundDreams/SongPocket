// 2020-04-28

import UIKit
import SwiftUI
import MusicKit

final class AlbumsTVC: LibraryTVC {
	private lazy var arrangeAlbumsButton = UIBarButtonItem(title: LRString.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [
			editButtonItem, .flexibleSpace(),
			arrangeAlbumsButton, .flexibleSpace(),
			floatButton, .flexibleSpace(),
			sinkButton,
		]
		
		super.viewDidLoad()
		
		tableView.separatorStyle = .none
	}
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		
		tableView.allIndexPaths().forEach { indexPath in // Don’t use `indexPathsForVisibleRows`, because that excludes cells that underlap navigation bars and toolbars.
			guard let cell = tableView.cellForRow(at: indexPath) else { return }
			let album = viewModel.itemNonNil(atRow: indexPath.row) as! Album
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
					album: album,
					maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
			}.margins(.all, .zero)
		}
	}
	
	// MARK: - Editing
	
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeMenu()
	}
	private func createArrangeMenu() -> UIMenu {
		let sections: [[ArrangeCommand]] = [
			[.album_newest, .album_oldest],
			[.random, .reverse],
		]
		let elementsGrouped: [[UIMenuElement]] = sections.reversed().map { section in
			section.reversed().map { command in
				command.createMenuElement(
					enabled: {
						guard selectedOrAllRows().count >= 2 else { return false }
						switch command {
							case .random, .reverse: return true
							case .song_track: return false
							case .album_newest, .album_oldest:
								let subjectedItems = selectedOrAllRows().map {
									viewModel.itemNonNil(atRow: $0)
								}
								guard let albums = subjectedItems as? [Album] else {
									return false
								}
								return albums.contains { $0.releaseDateEstimate != nil }
						}
					}()
				) { [weak self] in
					self?.arrangeSelectedOrAll(by: command)
				}
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
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
								await AppleMusic.requestAccess()
							}
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
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
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		return viewModel.items.count
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
		let album = viewModel.itemNonNil(atRow: indexPath.row) as! Album
		cell.backgroundColors_configureForLibraryItem()
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(
				album: album,
				maxHeight: {
					let height = view.frame.height
					let topInset = view.safeAreaInsets.top
					let bottomInset = view.safeAreaInsets.bottom
					return height - topInset - bottomInset
				}())
		}.margins(.all, .zero)
		return cell
	}
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if !isEditing {
			navigationController?.pushViewController(
				{
					let songsTVC = UIStoryboard(name: "SongsTVC", bundle: nil).instantiateInitialViewController() as! SongsTVC
					songsTVC.viewModel = SongsViewModel(album: viewModel.itemNonNil(atRow: indexPath.row) as! Album)
					return songsTVC
				}(),
				animated: true)
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}
