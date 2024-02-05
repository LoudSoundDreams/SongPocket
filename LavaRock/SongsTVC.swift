//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit

final class SongsListStatus: ObservableObject {
	@Published fileprivate(set) var editing = false
}

extension SongsTVC: TapeDeckReflecting {
	final func reflect_playbackState() { reflectAvatar() }
	final func reflect_nowPlaying() { reflectAvatar() }
	
	private func reflectAvatar() {
		tableView.allIndexPaths().forEach { indexPath in
			guard
				let cell = tableView.cellForRow(at: indexPath) as? SongCell
			else { return }
			cell.reflectAvatarStatus({
				guard
					viewModel.pointsToSomeItem(row: indexPath.row),
					let song = viewModel.itemNonNil(atRow: indexPath.row) as? Song
				else {
					return .notPlaying
				}
				return song.avatarStatus()
			}())
		}
	}
}
final class SongsTVC: LibraryTVC {
	let status = SongsListStatus()
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		status.editing = editing
	}
	
	private lazy var arrangeSongsButton = UIBarButtonItem(
		title: LRString.sort,
		image: UIImage(systemName: "arrow.up.arrow.down")
	)
	override func viewDidLoad() {
		editingButtons = [
			editButtonItem, .flexibleSpace(),
			.flexibleSpace(), .flexibleSpace(),
			arrangeSongsButton, .flexibleSpace(),
			floatButton, .flexibleSpace(),
			sinkButton,
		]
		
		super.viewDidLoad()
		
		TapeDeck.shared.addReflector(weakly: self)
	}
	override func reflectDatabase() {
		// Do this even if the view isn’t visible.
		reflectAvatar()
		
		super.reflectDatabase()
	}
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		arrangeSongsButton.isEnabled = allowsArrange()
		arrangeSongsButton.menu = createArrangeMenu()
	}
	private static let arrangeCommands: [[ArrangeCommand]] = [
		[.song_track],
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
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
}
