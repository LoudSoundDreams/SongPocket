// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import CoreData

final class AlbumsTVC: LibraryTVC {
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	private var purpose: Purpose {
		if let clipboard = moveAlbumsClipboard { return .movingAlbums(clipboard) }
		return .browsing
	}
	private enum Purpose {
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	private lazy var moveButton = UIBarButtonItem(
		title: LRString.move,
		image: UIImage(systemName: "folder"),
		primaryAction: UIAction { [weak self] _ in self?.startMoving() })
	private lazy var arrangeAlbumsButton = UIBarButtonItem(
		title: LRString.sort,
		image: UIImage(systemName: "arrow.up.arrow.down"))
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		if Enabling.unifiedAlbumList {
			if let collection = Collection.allFetched(sorted: true, context: Database.viewContext).first {
				viewModel = AlbumsViewModel(
					collection: collection,
					context: Database.viewContext)
			}
		}
		
		switch purpose {
			case .movingAlbums: break
			case .browsing:
				if Enabling.unifiedAlbumList {
					editingButtons = [
						editButtonItem, .flexibleSpace(),
						arrangeAlbumsButton, .flexibleSpace(),
						floatButton, .flexibleSpace(),
						sinkButton,
					]
				} else {
					editingButtons = [
						editButtonItem, .flexibleSpace(),
						moveButton, .flexibleSpace(),
						arrangeAlbumsButton, .flexibleSpace(),
						floatButton, .flexibleSpace(),
						sinkButton,
					]
				}
		}
		
		super.viewDidLoad()
		
		tableView.separatorStyle = .none
		
		switch purpose {
			case .movingAlbums:
				navigationItem.setRightBarButton(
					{
						let moveHereButton = UIBarButtonItem(title: LRString.move, primaryAction: UIAction { [weak self] _ in
							self?.moveHere()
						})
						moveHereButton.style = .done
						return moveHereButton
					}(),
					animated: false)
			case .browsing:
				NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectDatabase), name: .LRUserUpdatedDatabase, object: nil)
		}
	}
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		
		guard let albumsViewModel = viewModel as? AlbumsViewModel else { return }
		
		tableView.allIndexPaths().forEach { indexPath in // Don’t use `indexPathsForVisibleRows`, because that excludes cells that underlap navigation bars and toolbars.
			guard
				let cell = tableView.cellForRow(at: indexPath),
				albumsViewModel.pointsToSomeItem(row: indexPath.row)
			else { return }
			let album = albumsViewModel.albumNonNil(atRow: indexPath.row)
			let (mode, _) = new_albumRowMode_and_selectionStyle(album: album)
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
					album: album,
					maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
					mode: mode)
			}.margins(.all, .zero)
		}
	}
	
	// MARK: - Library items
	
	override func freshenLibraryItems() {
		switch purpose {
			case .movingAlbums: return
			case .browsing: super.freshenLibraryItems()
		}
	}
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit()
	}
	
	// MARK: Editing
	
	private func startMoving() {
		// Prepare a Collections view to present modally.
		let nc = UINavigationController(
			rootViewController: UIStoryboard(name: "CollectionsTVC", bundle: nil).instantiateInitialViewController()!
		)
		guard
			let collectionsTVC = nc.viewControllers.first as? CollectionsTVC,
			let selfVM = viewModel as? AlbumsViewModel
		else { return }
		
		// Configure the `CollectionsTVC`.
		collectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(albumsBeingMoved: {
			var subjectedRows: [Int] = tableView.selectedIndexPaths.map { $0.row }
			subjectedRows.sort()
			if subjectedRows.isEmpty {
				subjectedRows = selfVM.rowsForAllItems()
			}
			return subjectedRows.map {
				selfVM.albumNonNil(atRow: $0)
			}
		}())
		collectionsTVC.viewModel = CollectionsViewModel(context: {
			let childContext = NSManagedObjectContext(.mainQueue)
			childContext.parent = viewModel.context
			return childContext
		}())
		
		present(nc, animated: true)
	}
	
	// MARK: - Freshening UI
	
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		moveButton.isEnabled = {
			guard !viewModel.items.isEmpty else {
				return false
			}
			return true
		}()
		
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeMenu()
	}
	private static let arrangeCommands: [[ArrangeCommand]] = [
		[.album_newest, .album_oldest],
		[.random, .reverse],
	]
	private func createArrangeMenu() -> UIMenu {
		let elementsGrouped: [[UIMenuElement]] = Self.arrangeCommands.reversed().map {
			$0.reversed().map { command in
				command.createMenuElement(
					enabled: {
						guard unsortedRowsToArrange().count >= 2 else {
							return false
						}
						switch command {
							case .random, .reverse: return true
							case .collection_name, .song_track: return false
							case .album_newest, .album_oldest:
								let subjectedItems = unsortedRowsToArrange().map {
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
	
	// MARK: - “Move” sheet
	
	private func moveHere() {
		guard
			case let .movingAlbums(clipboard) = purpose,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		albumsViewModel.context.move(
			albumIDs: clipboard.idsOfAlbumsBeingMoved,
			toCollectionWith: albumsViewModel.collection.objectID)
		let newViewModel = AlbumsViewModel(
			collection: albumsViewModel.collection,
			context: albumsViewModel.context)
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			viewModel.context.tryToSave()
			viewModel.context.parent!.tryToSave() // Save the main context now, even though we haven’t exited editing mode, because if you moved all the albums out of a collection, we’ll close the collection and exit editing mode shortly.
			
			NotificationCenter.default.post(name: .LRUserUpdatedDatabase, object: nil)
			MusicRepo.shared.signal_userUpdatedDatabase.toggle()
		}
	}
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.items.isEmpty {
			contentUnavailableConfiguration = UIHostingConfiguration {
				Image(systemName: "square.stack")
					.foregroundStyle(.secondary)
					.font(.title)
					.accessibilityLabel(LRString.noAlbums)
			}.margins(.all, .zero) // As of iOS 17.4, without this, the content shows up too low within a sheet until you move the sheet vertically by any amount.
		} else {
			contentUnavailableConfiguration = nil
		}
		
		return 1
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
		let album = (viewModel as! AlbumsViewModel).albumNonNil(atRow: indexPath.row)
		let (mode, enabled) = new_albumRowMode_and_selectionStyle(album: album)
		cell.backgroundColors_configureForLibraryItem()
		cell.isUserInteractionEnabled = enabled
		if enabled {
			cell.accessibilityTraits.subtract(.notEnabled)
		} else {
			cell.accessibilityTraits.formUnion(.notEnabled)
		}
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(
				album: album,
				maxHeight: {
					let height = view.frame.height
					let topInset = view.safeAreaInsets.top
					let bottomInset = view.safeAreaInsets.bottom
					return height - topInset - bottomInset
				}(),
				mode: mode)
		}.margins(.all, .zero)
		return cell
	}
	private func new_albumRowMode_and_selectionStyle(album: Album) -> (
		mode: AlbumRow.Mode,
		enabled: Bool
	) {
		let mode: AlbumRow.Mode = {
			switch purpose {
				case .movingAlbums(let clipboard):
					if clipboard.idsOfAlbumsBeingMovedAsSet.contains(album.objectID) {
						return .disabledTinted
					}
					return .disabled
				case .browsing:
					return .normal
			}
		}()
		let enabled: Bool = {
			switch purpose {
				case .movingAlbums: return false
				case .browsing: return true
			}
		}()
		return (mode, enabled)
	}
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if !isEditing {
			navigationController?.pushViewController(
				{
					let songsTVC = UIStoryboard(name: "SongsTVC", bundle: nil).instantiateInitialViewController() as! SongsTVC
					songsTVC.viewModel = SongsViewModel(
						album: (viewModel as! AlbumsViewModel).albumNonNil(atRow: indexPath.row),
						context: viewModel.context)
					return songsTVC
				}(),
				animated: true)
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}

// MARK: - Rows

private struct AlbumRow: View {
	enum Mode {
		case normal
		case disabled
		case disabledTinted
	}
	
	let album: Album
	let maxHeight: CGFloat
	let mode: Mode
	
	@Environment(\.pixelLength) private var pointsPerPixel
	private static let borderWidthInPixels: CGFloat = 2
	var body: some View {
		VStack(spacing: 0) {
			Rectangle().frame(height: 1/2 * Self.borderWidthInPixels * pointsPerPixel).hidden()
			// TO DO: Redraw when artwork changes
			CoverArt(
				albumRepresentative: album.representativeSongInfo(),
				largerThanOrEqualToSizeInPoints: maxHeight)
			.background( // Use `border` instead?
				Rectangle()
					.stroke(
						Color(uiColor: .separator), // As of iOS 16.6, only this is correct in dark mode, not `opaqueSeparator`.
						lineWidth: {
							// Add a grey border exactly 1 pixel wide, like list separators.
							// Draw outside the artwork; don’t overlap it.
							// The artwork itself will obscure half the stroke width.
							// SwiftUI interprets our return value in points, not pixels.
							return Self.borderWidthInPixels * pointsPerPixel
						}()
					)
			)
			.frame(
				maxWidth: .infinity, // Horizontally centers narrow artwork
				maxHeight: maxHeight) // Prevents artwork from becoming taller than viewport
			.accessibilityLabel(album.titleFormatted())
			.accessibilitySortPriority(10)
			
			AlbumLabel(album: album)
				.padding(.top, .eight * 3/2)
				.padding(.horizontal)
				.padding(.bottom, .eight * 4)
				.accessibilityRespondsToUserInteraction(false)
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.accessibilityAddTraits(.isButton)
		.opacity({ () -> Double in
			switch mode {
				case .normal: return 1
				case .disabled: return .oneFourth // Close to what Files pickers use
				case .disabledTinted: return .oneHalf
			}
		}())
		.disabled({
			switch mode {
				case .normal: return false
				case .disabled, .disabledTinted: return true
			}
		}())
		.background {
			if mode == .disabledTinted {
				Color.accentColor.opacity(.oneEighth)
			}
		}
		.accessibilityInputLabels([album.titleFormatted()])
	}
}
private struct CoverArt: View {
	let albumRepresentative: (any SongInfo)?
	let largerThanOrEqualToSizeInPoints: CGFloat
	
	var body: some View {
		let uiImageOptional = albumRepresentative?.coverArt(atLeastInPoints: CGSize(
			width: largerThanOrEqualToSizeInPoints,
			height: largerThanOrEqualToSizeInPoints))
		if let uiImage = uiImageOptional {
			Image(uiImage: uiImage)
				.resizable() // Lets 1 image point differ from 1 screen point
				.scaledToFit() // Maintains aspect ratio
				.accessibilityIgnoresInvertColors()
		} else {
			ZStack {
				Color(uiColor: .secondarySystemBackground) // Close to what Apple Music uses
					.aspectRatio(1, contentMode: .fit)
				Image(systemName: "opticaldisc")
					.foregroundStyle(.secondary)
					.font(.system(size: .eight * 4))
			}
			.accessibilityLabel(LRString.albumArtwork)
			.accessibilityIgnoresInvertColors()
		}
	}
}
private struct AlbumLabel: View {
	let album: Album
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			ZStack(alignment: .leading) {
				Chevron().hidden()
				AvatarImage(libraryItem: album, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10) // Bigger is sooner
			}
			
			Text(album.releaseDateEstimateFormattedOptional() ?? LRString.emDash)
				.foregroundStyle(.secondary)
				.fontFootnote()
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
			
			ZStack(alignment: .trailing) {
				AvatarPlayingImage().hidden()
				Chevron()
			}
		}
		.accessibilityElement(children: .combine)
	}
}
