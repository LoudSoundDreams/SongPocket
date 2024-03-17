//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import SwiftUI
@preconcurrency import MusicKit

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
	private let listStatus = SongsListStatus()
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		listStatus.editing = editing
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
		deleteThenExit()
	}
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.isEmpty() {
			contentUnavailableConfiguration = UIHostingConfiguration {
				Image(systemName: "music.note")
					.foregroundStyle(.secondary)
					.font(.title)
			}
		} else {
			contentUnavailableConfiguration = nil
		}
		
		return 1
	}
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		if viewModel.isEmpty() {
			return 0 // Without `prerowCount`
		} else {
			return SongsViewModel.prerowCount + viewModel.group.items.count
		}
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let songsViewModel = viewModel as! SongsViewModel
		let album = songsViewModel.group.container as! Album
		
		switch indexPath.row {
			case 0:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Header", for: indexPath)
				cell.selectionStyle = .none // So the user can’t even highlight the cell
				cell.backgroundColors_configureForLibraryItem()
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumHeader(
						album: album,
						trackNumberSpacer: (songsViewModel.group as! SongsGroup).trackNumberSpacer
					)
				}.margins(.all, .zero)
				return cell
			default:
				let cell = tableView.dequeueReusableCell(withIdentifier: "Song", for: indexPath)
				cell.backgroundColors_configureForLibraryItem()
				let song = songsViewModel.itemNonNil(atRow: indexPath.row) as! Song
				let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
				let albumRepresentative: SongInfo? = album.representativeSongInfo()
				let trackDisplay: String = {
					let result: String? = {
						guard let albumRepresentative, let info else {
							// `SongInfo` not available
							return nil
						}
						if albumRepresentative.shouldShowDiscNumber {
							// Disc and track number
							return info.discAndTrackNumberFormatted()
						} else {
							// Track number only, which might be blank
							return info.trackNumberFormattedOptional()
						}
					}()
					return result ?? "#"
				}()
				let artistDisplayOptional: String? = {
					let albumArtistOptional = albumRepresentative?.albumArtistOnDisk
					if
						let songArtist = info?.artistOnDisk,
						songArtist != albumArtistOptional
					{
						return songArtist
					} else {
						return nil
					}
				}()
				cell.contentConfiguration = UIHostingConfiguration {
					SongRow(
						song: song,
						trackDisplay: trackDisplay,
						artist_if_different_from_album_artist: artistDisplayOptional,
						listStatus: listStatus // TO DO: Memory leak?
					)
				}.margins(.all, .zero)
				return cell
		}
	}
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if
			!isEditing,
			let selectedCell = tableView.cellForRow(at: indexPath)
		{
			// The UI is clearer if we leave the row selected while the action sheet is onscreen.
			// You must eventually deselect the row in every possible scenario after this moment.
			
			let startPlaying = UIAlertAction(
				title: LRString.startPlaying,
				style: .default
			) { [weak self] _ in
				Task {
					guard
						let self,
						let player = SystemMusicPlayer._shared
					else { return }
					
					let allMusicItems: [MusicKit.Song] = await {
						var result: [MusicKit.Song] = []
						for song in (self.viewModel.group.items as! [Song]) {
							guard let musicItem = await song.musicKitSong() else { continue }
							result.append(musicItem)
						}
						return result
					}()
					
					let song = (self.viewModel as! SongsViewModel).itemNonNil(atRow: indexPath.row) as! Song
					guard let musicItem = await song.musicKitSong() else { return }
					
					player.queue = SystemMusicPlayer.Queue(for: allMusicItems, startingAt: musicItem)
					try? await player.play()
					
					// As of iOS 17.2 beta, if setting the queue effectively did nothing, you must do these after calling `play`, not before.
					player.state.repeatMode = MusicPlayer.RepeatMode.none
					player.state.shuffleMode = .off
					
					tableView.deselectAllRows(animated: true)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
			
			let actionSheet = UIAlertController(
				title: nil,
				message: nil,
				preferredStyle: .actionSheet)
			actionSheet.popoverPresentationController?.sourceView = selectedCell
			actionSheet.addAction(startPlaying)
			actionSheet.addAction(
				UIAlertAction(title: LRString.cancel, style: .cancel) { [weak self] _ in
					self?.tableView.deselectAllRows(animated: true)
				}
			)
			present(actionSheet, animated: true)
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}

// MARK: - Rows

private struct AlbumHeader: View {
	let album: Album
	let trackNumberSpacer: String
	
	var body: some View {
		HStack(spacing: .eight * 5/4) {
			AvatarPlayingImage().hidden()
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text({ () -> String in
					guard
						let representative = album.representativeSongInfo(),
						let albumArtist = representative.albumArtistOnDisk,
						albumArtist != ""
					else { return LRString.unknownArtist }
					return albumArtist
				}())
				.foregroundStyle(.secondary)
				.fontCaption2_bold()
				Text(album.titleFormatted())
					.fontTitle2_bold()
			}
			.alignmentGuide_separatorLeading()
			Spacer()
		}
		.alignmentGuide_separatorTrailing()
		.padding(.horizontal).padding(.vertical, .eight * 3/2)
	}
}

private struct SongRow: View {
	let song: Song
	let trackDisplay: String
	let artist_if_different_from_album_artist: String?
	@ObservedObject var listStatus: SongsListStatus
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			HStack(alignment: .firstTextBaseline) {
				AvatarImage(libraryItem: song, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10)
				VStack(alignment: .leading, spacing: .eight * 1/2) {
					Text(song.songInfo()?.titleOnDisk ?? LRString.emDash)
						.alignmentGuide_separatorLeading()
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.foregroundStyle(.secondary)
							.fontFootnote()
					}
				}
				.padding(.bottom, .eight * 1/4)
				Spacer()
				Text(trackDisplay)
					.foregroundStyle(.secondary)
					.monospacedDigit()
			}
			.accessibilityElement(children: .combine)
			.accessibilityAddTraits(.isButton)
			.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
			Menu { overflowMenuContent() } label: { overflowMenuLabel() }
				.disabled(listStatus.editing)
				.onTapGesture { signal_tappedMenu.toggle() }
				.alignmentGuide_separatorTrailing()
		}
		.padding(.horizontal).padding(.vertical, .eight * 3/2)
	}
	private func overflowMenuLabel() -> some View {
		Image(systemName: "ellipsis.circle.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.symbolRenderingMode(.hierarchical)
	}
	@ViewBuilder private func overflowMenuContent() -> some View {
		Button {
			Task { await song.play() }
		} label: { Label(LRString.play, systemImage: "play") }
		Divider()
		Button {
			Task { await song.playLast() }
		} label: { Label(LRString.playLast, systemImage: "text.line.last.and.arrowtriangle.forward") }
		
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		Button {
			Task { await song.playRestOfAlbumLast() }
		} label: {
			Label(LRString.playRestOfAlbumLast, systemImage: "text.line.last.and.arrowtriangle.forward")
		}
		.disabled((signal_tappedMenu && false) || song.isAtBottomOfAlbum()) // Hopefully the compiler never optimizes away the dependency on the SwiftUI state property
	}
	@State private var signal_tappedMenu = false // Value doesn’t actually matter
}

final class SongCell: UITableViewCell {
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var spacerNumberLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var overflowButton: ExpandedTargetButton!
	
	func reflectAvatarStatus(_ status: AvatarStatus) {
	}
}
final class ExpandedTargetButton: UIButton {
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let tappableWidth = max(bounds.width, 44)
		let tappableHeight = max(bounds.height, 55)
		let tappableRect = CGRect(
			x: bounds.midX - tappableWidth/2,
			y: bounds.midY - tappableHeight/2,
			width: tappableWidth,
			height: tappableHeight)
		return tappableRect.contains(point)
	}
}
