//
//  CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import SwiftUI
import MusicKit

extension CollectionsTVC: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(nil) // As of iOS 15.3 developer beta 1, the selection works but the highlight doesn’t appear if `textField.text` is long.
	}
}
final class CollectionsTVC: LibraryTVC {
	private enum Purpose {
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	private enum CollectionsViewState {
		case allowAccess
		case loading
		case emptyDatabase
		case someCollections
	}
	
	private lazy var arrangeCollectionsButton = UIBarButtonItem(
		title: LRString.sort,
		image: UIImage(systemName: "arrow.up.arrow.down")
	)
	
	private var purpose: Purpose {
		if let clipboard = moveAlbumsClipboard { return .movingAlbums(clipboard) }
		return .browsing
	}
	
	private var viewState: CollectionsViewState {
		guard MusicAuthorization.currentStatus == .authorized else {
			return .allowAccess
		}
		guard viewModel.isEmpty() else {
			return .someCollections
		}
		if isMergingChanges {
			return .loading
		}
		return .emptyDatabase
	}
	
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: -
	
	func reflectViewState() {
		let toDelete: [IndexPath] = {
			switch viewState {
				case .allowAccess, .loading, .emptyDatabase:
					return tableView.indexPathsForRows(section: 0, firstRow: 0)
				case .someCollections: // Merging changes with existing collections
					// Crashes after Reset Location & Privacy
					return []
			}
		}()
		tableView.performBatchUpdates {
			tableView.deleteRows(at: toDelete, with: .middle)
		}
		
		switch viewState {
			case .allowAccess, .loading, .emptyDatabase:
				if isEditing {
					setEditing(false, animated: true)
				}
			case .someCollections: break
		}
		
		freshenEditingButtons() // Including “Edit” button
	}
	
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
			case .movingAlbums: break
			case .browsing:
				AppleMusic.loadingIndicator = self
				
				NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectDatabase), name: .LRUserUpdatedDatabase, object: nil)
		}
		
		navigationItem.backButtonDisplayMode = .minimal
		
		switch purpose {
			case .movingAlbums:
				navigationItem.setLeftBarButton(
					UIBarButtonItem(
						systemItem: .close,
						primaryAction: UIAction { [weak self] _ in
							self?.dismiss(animated: true)
						}
					),
					animated: false)
				navigationItem.setRightBarButton(
					UIBarButtonItem(
						systemItem: .add,
						primaryAction: UIAction { [weak self] _ in self?.createAndOpen() }
					),
					animated: false)
			case .browsing: break
		}
		
		switch purpose {
			case .movingAlbums: break
			case .browsing:
				navigationController?.setToolbarHidden(false, animated: false)
		}
	}
	
	@IBAction private func unwindToCollections(_ unwindSegue: UIStoryboardSegue) {}
	
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		switch purpose {
			case .movingAlbums: break
			case .browsing:
				if !forBrowsingAndHasFirstAppeared {
					forBrowsingAndHasFirstAppeared = true
					
					// As of iOS 16.6.1, the build setting “Global Accent Color Name” doesn’t apply to (UIKit) alerts or action sheets.
					view.window!.tintColor = UIColor(named: "denim")!
				}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		switch purpose {
			case .movingAlbums:
				revertCreate()
			case .browsing: break
		}
		super.viewDidAppear(animated)
	}
	private var forBrowsingAndHasFirstAppeared = false
	
	func prepareToIntegrateWithAppleMusic() async {
		isMergingChanges = true // `viewState` is now `.loading` or `.someCollections` (updating)
		reflectViewState()
	}
	
	func requestAccessToAppleMusic() async {
		switch MusicAuthorization.currentStatus {
			case .authorized: break // Should never run
			case .notDetermined:
				let response = await MusicAuthorization.request()
				
				switch response {
					case .denied, .restricted, .notDetermined: break
					case .authorized: await AppleMusic.integrateIfAuthorized()
					@unknown default: break
				}
			case .denied, .restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
			@unknown default: break
		}
	}
	
	// MARK: - Library items
	
	override func freshenLibraryItems() {
		switch purpose {
			case .movingAlbums: return
			case .browsing: break
		}
		
		switch viewState {
			case .loading, .emptyDatabase:
				reflectViewState()
				super.freshenLibraryItems()
				return
			case .allowAccess, .someCollections: break
		}
		
		super.freshenLibraryItems()
	}
	
	override func reflectViewModelIsEmpty() {
		reflectViewState()
	}
	
	// MARK: Editing
	
	func promptRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(atRow: indexPath.row) as? Collection else { return }
		
		let dialog = UIAlertController(
			title: LRString.rename,
			message: nil,
			preferredStyle: .alert)
		
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
				thenShouldReselect: rowWasSelectedBeforeRenaming
			)
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
		if proposedTitle.isEmpty {
			collection.title = LRString.tilde
		} else {
			collection.title = proposedTitle
		}
		
		tableView.performBatchUpdates {
			tableView.reloadRows(at: [indexPath], with: .fade)
		}
		if thenShouldReselect {
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}
	
	// MARK: - Freshening UI
	
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		switch viewState {
			case .allowAccess, .loading, .emptyDatabase:
				editButtonItem.isEnabled = false
			case .someCollections: break
		}
		
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
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let albumsTVC = segue.destination as? AlbumsTVC
		else { return }
		
		albumsTVC.moveAlbumsClipboard = moveAlbumsClipboard
		
		let selectedCollection = collectionsViewModel.collectionNonNil(atRow: selectedIndexPath.row)
		albumsTVC.viewModel = AlbumsViewModel(
			collection: selectedCollection,
			context: viewModel.context)
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
		performSegue(withIdentifier: "Open Collection", sender: self)
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
	
	override func tableView(
		_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath
	) {
		promptRename(at: indexPath)
	}
	
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
				return viewModel.libraryGroup().items.count
		}
	}
	
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

// MARK: - Rows

private struct CollectionRow: View {
	let title: String?
	let collection: Collection
	let dimmed: Bool
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			ZStack(alignment: .leading) {
				Chevron().hidden()
				AvatarImage(
					libraryItem: collection,
					state: SystemMusicPlayer._shared!.state,
					queue: SystemMusicPlayer._shared!.queue
				).accessibilitySortPriority(10)
			}
			
			Text({ () -> String in
				// Don’t let this be `nil` or `""`. Otherwise, when we revert combining collections before `freshenLibraryItems`, the table view vertically collapses rows for deleted collections.
				guard let title, !title.isEmpty else { return " " }
				return title
			}())
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
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.opacity(
			dimmed
			? .oneFourth // Close to what Files pickers use
			: 1
		)
		.disabled(dimmed)
		.accessibilityInputLabels([title].compacted()) // Exclude the now-playing status.
		// ! Accessibility action
		// ! Accessibility “selected” state
	}
}
