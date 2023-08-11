//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer

final class SongsTVC: LibraryTVC {
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = nil
	}
	
	private lazy var arrangeSongsButton = UIBarButtonItem(title: LRString.arrange)
	override func setUpBarButtons() {
		editingModeToolbarButtons = [
			arrangeSongsButton,
			.flexibleSpace(),
			floatButton,
			.flexibleSpace(),
			sinkButton,
		]
		
		super.setUpBarButtons()
	}
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		arrangeSongsButton.isEnabled = allowsArrange()
		arrangeSongsButton.menu = createArrangeSongsMenu()
	}
	private static let arrangeCommands: [[ArrangeCommand]] = [
		[.song_track, .song_added],
		[.random, .reverse],
	]
	private func createArrangeSongsMenu() -> UIMenu {
		let setOfCommands: Set<ArrangeCommand> = Set(Self.arrangeCommands.flatMap { $0 })
		let elementsGrouped: [[UIMenuElement]] = Self.arrangeCommands.reversed().map {
			$0.reversed().map { command in
				return command.createMenuElement(
					enabled: {
						guard
							unsortedRowsToArrange().count >= 2,
							setOfCommands.contains(command)
						else {
							return false
						}
						
						return true
					}()
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
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		
		if
			let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)), // ! Use `SongsViewModel.rowCase`
			let songsViewModel = viewModel as? SongsViewModel,
			let album = songsViewModel.libraryGroup().container as? Album
		{
			cell.contentConfiguration = Self.createCoverArtConfiguration(
				albumRepresentative: album.representativeSongInfo(),
				maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
				albumTitle: album.titleFormatted(),
				albumArtist: album.albumArtistFormatted(),
				releaseDateStringOptional: album.releaseDateEstimateFormattedOptional()
			)
		}
	}
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
	
	func mediaItems() -> [MPMediaItem] {
		let items = Array(viewModel.libraryGroup().items)
		return items.compactMap { ($0 as? Song)?.mpMediaItem() }
	}
}
