// 2020-05-04

import UIKit
import SwiftUI
import MusicKit

extension CollectionsTVC: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(nil) // As of iOS 15.3 developer beta 1, the selection works but the highlight doesn’t appear if `textField.text` is long.
	}
}
final class CollectionsTVC: LibraryTVC {
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	private var purpose: Purpose {
		if let clipboard = moveAlbumsClipboard { return .movingAlbums(clipboard) }
		return .browsing
	}
	private enum Purpose {
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	private lazy var arrangeCollectionsButton = UIBarButtonItem(title: LRString.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		switch purpose {
			case .movingAlbums: break
			case .browsing:
				editingButtons = [
					editButtonItem, .flexibleSpace(),
					.flexibleSpace(), .flexibleSpace(),
					arrangeCollectionsButton, .flexibleSpace(),
					floatButton, .flexibleSpace(),
					sinkButton,
				]
		}
		
		super.viewDidLoad()
		
		switch purpose {
			case .movingAlbums:
				navigationItem.setLeftBarButton(
					UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
						self?.dismiss(animated: true)
					}),
					animated: false)
				navigationItem.setRightBarButton(
					UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in self?.createAndOpen()
					}),
					animated: false)
				if !MainToolbar.usesSwiftUI {
					navigationController?.setToolbarHidden(true, animated: false)
				}
			case .browsing:
				AppleMusic.loadingIndicator = self
				
				NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectDatabase), name: .LRUserUpdatedDatabase, object: nil)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		switch purpose {
			case .movingAlbums: revertCreate()
			case .browsing: break
		}
		super.viewDidAppear(animated)
	}
	
	// MARK: - Library items
	
	override func freshenLibraryItems() {
		switch purpose {
			case .movingAlbums: return
			case .browsing: super.freshenLibraryItems()
		}
	}
	
	// MARK: - Editing
	
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		arrangeCollectionsButton.isEnabled = allowsArrange()
		arrangeCollectionsButton.menu = createArrangeMenu()
	}
	private static let arrangeCommands: [[ArrangeCommand]] = [
		[.collection_name],
		[.random, .reverse],
	]
	private func createArrangeMenu() -> UIMenu {
		let setOfCommands: Set<ArrangeCommand> = Set(Self.arrangeCommands.flatMap { $0 })
		let elementsGrouped: [[UIMenuElement]] = Self.arrangeCommands.reversed().map {
			$0.reversed().map { command in
				return command.createMenuElement(
					enabled:
						unsortedRowsToArrange().count >= 2
					&& setOfCommands.contains(command)
				) { [weak self] in
					self?.arrangeSelectedOrAll(by: command)
				}
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			return UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
	}
	
	private func promptRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(atRow: indexPath.row) as? Collection else { return }
		
		let dialog = UIAlertController(title: LRString.rename, message: nil, preferredStyle: .alert)
		
		dialog.addTextField {
			// UITextField
			$0.text = collection.title
			$0.placeholder = LRString.tilde
			$0.clearButtonMode = .always
			
			// UITextInputTraits
			$0.returnKeyType = .done
			$0.autocapitalizationType = .sentences
			$0.smartQuotesType = .yes
			$0.smartDashesType = .yes
			
			$0.delegate = self
		}
		
		dialog.addAction(UIAlertAction(title: LRString.cancel, style: .cancel))
		
		let rowWasSelectedBeforeRenaming = tableView.selectedIndexPaths.contains(indexPath)
		let done = UIAlertAction(title: LRString.done, style: .default) { [weak self] _ in
			self?.commitRename(
				textFieldText: dialog.textFields?.first?.text,
				indexPath: indexPath,
				thenShouldReselect: rowWasSelectedBeforeRenaming)
		}
		dialog.addAction(done)
		dialog.preferredAction = done
		
		present(dialog, animated: true)
	}
	private func commitRename(
		textFieldText: String?,
		indexPath: IndexPath,
		thenShouldReselect: Bool
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		let collection = collectionsViewModel.collectionNonNil(atRow: indexPath.row)
		
		let proposedTitle = (textFieldText ?? "").truncated(maxLength: 256) // In case the user entered a dangerous amount of text
		if proposedTitle == "" {
			collection.title = LRString.tilde
		} else {
			collection.title = proposedTitle
		}
		
		tableView.reloadRows(at: [indexPath], with: .fade)
		if thenShouldReselect {
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}
	
	// MARK: - “Move” sheet
	
	private func createAndOpen() {
		guard
			case .movingAlbums(let clipboard) = purpose,
			!clipboard.hasCreatedNewCollection,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		clipboard.hasCreatedNewCollection = true
		
		let newViewModel = collectionsViewModel.updatedAfterCreating()
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			openCreated()
		}
	}
	private func openCreated() {
		let indexPath = IndexPath(row: CollectionsViewModel.indexOfNewCollection, section: 0)
		tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		openCollection(atIndexPath: indexPath)
	}
	
	private func revertCreate() {
		guard case .movingAlbums(let clipboard) = purpose else {
			fatalError()
		}
		guard clipboard.hasCreatedNewCollection else { return }
		clipboard.hasCreatedNewCollection = false
		
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
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
		}.margins(.all, .zero)
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
	
	override func tableView(
		_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath
	) {
		promptRename(at: indexPath)
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
				
				albumsTVC.moveAlbumsClipboard = moveAlbumsClipboard
				
				albumsTVC.viewModel = AlbumsViewModel(collection: (viewModel as! CollectionsViewModel).collectionNonNil(atRow: atIndexPath.row))
				
				return albumsTVC
			}(),
			animated: true)
	}
}

// MARK: - Rows

private struct CollectionRow: View {
	let title: String?
	let collection: Collection
	let dimmed: Bool
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			ZStack(alignment: .leading) {
				Chevron().hidden()
				AvatarImage(libraryItem: collection, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10)
			}
			Text(title ?? "")
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
				.padding(.bottom, .eight * 1/4)
			ZStack(alignment: .trailing) {
				AvatarPlayingImage().hidden()
				Chevron()
			}
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.padding(.horizontal).padding(.vertical, .eight * 3/2)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.opacity(
			dimmed
			? .oneFourth // Close to what Files pickers use
			: 1
		)
		.disabled(dimmed)
		.accessibilityInputLabels([title].compacted()) // Exclude the now-playing status.
	}
}
