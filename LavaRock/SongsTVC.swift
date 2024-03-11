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
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.isEmpty() {
			contentUnavailableConfiguration = UIHostingConfiguration {
				Image(systemName: "music.note")
					.foregroundStyle(.secondary)
					.font(.title)
			}
			.margins(.all, .zero)
		} else {
			contentUnavailableConfiguration = nil
		}
		
		return viewModel.groups.count
	}
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		let songsViewModel = viewModel as! SongsViewModel
		if songsViewModel.album == nil {
			return 0 // Without `prerowCount`
		} else {
			return SongsViewModel.prerowCount + songsViewModel.libraryGroup().items.count
		}
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let songsViewModel = viewModel as! SongsViewModel
		let album = songsViewModel.libraryGroup().container as! Album
		
		switch indexPath.row {
			case 0:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Header", for: indexPath)
				cell.selectionStyle = .none // So the user can’t even highlight the cell
				cell.backgroundColors_configureForLibraryItem()
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumHeader(
						album: album,
						trackNumberSpacer: (songsViewModel.libraryGroup() as! SongsGroup).trackNumberSpacer
					)
				}
				return cell
			default:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Song",
					for: indexPath) as? SongCell
				else { return UITableViewCell() }
				cell.backgroundColors_configureForLibraryItem()
				cell.configureWith(
					song: songsViewModel.itemNonNil(atRow: indexPath.row) as! Song,
					albumRepresentative: album.representativeSongInfo(),
					spacerTrackNumberText: (songsViewModel.libraryGroup() as! SongsGroup).trackNumberSpacer,
					songsTVC: Weak(self),
					forBottomOfAlbum: indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
				)
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
						for song in (self.viewModel.libraryGroup().items as! [Song]) {
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
			TrackNumberLabel(text: trackNumberSpacer, spacerText: trackNumberSpacer)
				.hidden()
			
			VStack(
				alignment: .leading,
				spacing: .eight * 1/2
			) {
				Text({ () -> String in
					let representative = album.representativeSongInfo()
					guard
						let albumArtist = representative?.albumArtistOnDisk,
						albumArtist != ""
					else {
						return LRString.unknownArtist
					}
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
	}
}

private struct SongRow: View {
	let song: Song
	let trackDisplay: String
	let trackNumberSpacer: String
	let artist_if_different_from_album_artist: String?
	@ObservedObject var listStatus: SongsListStatus
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			HStack(alignment: .firstTextBaseline) {
				ZStack(alignment: .leading) {
					overflowMenuLabel().hidden()
					AvatarImage(
						libraryItem: song,
						state: SystemMusicPlayer._shared!.state,
						queue: SystemMusicPlayer._shared!.queue
					).accessibilitySortPriority(10)
				}
				TrackNumberLabel(text: trackDisplay, spacerText: "")
			}
			
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * 5/4
			) {
				
				VStack(
					alignment: .leading,
					spacing: .eight * 1/2
				) {
					Text(song.songInfo()?.titleOnDisk ?? LRString.emDash)
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.foregroundStyle(.secondary)
							.fontFootnote()
					}
				}
				.frame(maxWidth: .infinity)
				.padding(.bottom, .eight * 1/4)
				.alignmentGuide_separatorLeading()
			}
			
			HStack(alignment: .firstTextBaseline) {
				ZStack(alignment: .trailing) {
					AvatarPlayingImage().hidden()
					Menu {
						overflowMenuContent()
					} label: {
						overflowMenuLabel()
					}
					.disabled(listStatus.editing)
				}
			}
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.padding(.horizontal)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
	}
	private func overflowMenuLabel() -> some View {
		Image(systemName: "ellipsis.circle")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
	}
	@ViewBuilder private func overflowMenuContent() -> some View {
		Button {
		} label: {
			Label(LRString.play, systemImage: "play")
		}
		
		Divider()
		
		Button {
		} label: {
			Label(LRString.playLast, systemImage: "text.line.last.and.arrowtriangle.forward")
		}
		Button {
		} label: {
			Label(LRString.playRestOfAlbumLast, systemImage: "text.line.last.and.arrowtriangle.forward")
		}
	}
}
private struct TrackNumberLabel: View {
	let text: String
	let spacerText: String
	
	var body: some View {
		ZStack(alignment: .trailing) {
			Text(spacerText).hidden()
			Text(text).foregroundStyle(.secondary)
		}
		.monospacedDigit()
	}
}

private final class SongCell: UITableViewCell {
	private static let usesSwiftUI = 10 == 1
	
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var spacerNumberLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var overflowButton: ExpandedTargetButton!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		if Self.usesSwiftUI { return }
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(
			ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
			weight: .regular)
		numberLabel.font = spacerNumberLabel.font
		
		overflowButton.maximumContentSizeCategory = .extraExtraExtraLarge
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if Self.usesSwiftUI { return }
		
		freshenOverflowButton()
	}
	
	func reflectAvatarStatus(_ status: AvatarStatus) {
		if Self.usesSwiftUI { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = AvatarStatus.playing.uiImage
		speakerImageView.image = status.uiImage
		
		accessibilityLabel = [status.axLabel, rowContentAccessibilityLabel__].compactedAndFormattedAsNarrowList()
	}
	
	func configureWith(
		song: Song,
		albumRepresentative representative: SongInfo?,
		spacerTrackNumberText: String,
		songsTVC: Weak<SongsTVC>,
		forBottomOfAlbum: Bool
	) {
		let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
		
		let trackDisplay: String = {
			let result: String? = {
				guard let representative, let info else {
					// `SongInfo` not available
					return nil
				}
				if representative.shouldShowDiscNumber {
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
			let albumArtistOptional = representative?.albumArtistOnDisk
			if
				let songArtist = info?.artistOnDisk,
				songArtist != albumArtistOptional
			{
				return songArtist
			} else {
				return nil
			}
		}()
		
		if Self.usesSwiftUI {
			contentConfiguration = UIHostingConfiguration {
				if let referencee = songsTVC.referencee {
					SongRow(
						song: song,
						trackDisplay: trackDisplay,
						trackNumberSpacer: spacerTrackNumberText,
						artist_if_different_from_album_artist: artistDisplayOptional,
						listStatus: referencee.status
					)
				}
			}
			.margins(.all, .zero)
		} else {
			spacerNumberLabel.text = spacerTrackNumberText
			numberLabel.text = trackDisplay
			titleLabel.text = { () -> String in
				info?.titleOnDisk ?? LRString.emDash
			}()
			artistLabel.text = artistDisplayOptional
			
			if artistLabel.text == nil {
				textStack.spacing = 0
			} else {
				textStack.spacing = .eight * 1/2
			}
			
			rowContentAccessibilityLabel__ = [
				numberLabel.text,
				titleLabel.text,
				artistLabel.text,
			].compactedAndFormattedAsNarrowList()
			reflectAvatarStatus(song.avatarStatus())
			
			freshenOverflowButton()
			overflowButton.menu = newOverflowMenu(
				song: song,
				songsTVC: songsTVC,
				songPersistentIDForBottomOfAlbum: song.persistentID)
			
			accessibilityUserInputLabels = [info?.titleOnDisk].compacted()
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if Self.usesSwiftUI { return }
		
		separatorInset.left = 0
		+ contentView.frame.minX // Cell’s leading edge → content view’s leading edge
		+ textStack.frame.minX // Content view’s leading edge → text stack’s leading edge
		separatorInset.right = directionalLayoutMargins.trailing
	}
	
	private func freshenOverflowButton() {
		overflowButton.isEnabled = !isEditing
	}
	private func newOverflowMenu(
		song: Song,
		songsTVC: Weak<SongsTVC>,
		songPersistentIDForBottomOfAlbum: Int64
	) -> UIMenu? {
		guard
			let player = SystemMusicPlayer._shared,
			let tvc = songsTVC.referencee
		else { return nil }
		
		let play = UIAction(
			title: LRString.play, image: UIImage(systemName: "play")
		) { _ in
			// For actions that start playback, `MPMusicPlayerController.play` might need to fade out other currently-playing audio.
			// That blocks the main thread, so wait until the menu dismisses itself before calling it; for example, by doing the following asynchronously.
			// The UI will still freeze, but at least the menu won’t be onscreen while it happens.
			Task {
				guard let musicItem = await song.musicKitSong() else { return }
				
				player.queue = SystemMusicPlayer.Queue(for: [musicItem])
				try? await player.play()
				
				player.state.repeatMode = MusicPlayer.RepeatMode.none
				player.state.shuffleMode = .off
			}
		}
		
		let playLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.playLast, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				Task {
					guard let musicItem = await song.musicKitSong() else { return }
					
					try await player.queue.insert([musicItem], position: .tail)
					
					UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
				}
			}
			useMenuElements([action])
		})
		
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		let playRestOfAlbumLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let restOfSongs = tvc.viewModel.libraryGroup().items.map { $0 as! Song }
			let action = UIAction(
				title: LRString.playRestOfAlbumLast, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				Task {
					guard let rowItem = await song.musicKitSong() else { return }
					
					let toAppend: [MusicKit.Song] = await {
						var musicItems: [MusicKit.Song] = []
						for song in restOfSongs {
							guard let musicItem = await song.musicKitSong() else { continue }
							musicItems.append(musicItem)
						}
						let result = musicItems.drop(while: { $0.id != rowItem.id })
						return Array(result)
					}()
					// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
					try await player.queue.insert(toAppend, position: .tail)
					
					let impactor = UIImpactFeedbackGenerator(style: .heavy)
					impactor.impactOccurred()
					try await Task.sleep(nanoseconds: 0_200_000_000)
					
					impactor.impactOccurred()
				}
			}
			if songPersistentIDForBottomOfAlbum == restOfSongs.last?.persistentID {
				action.attributes.formUnion(.disabled)
			}
			useMenuElements([action])
		})
		
		return UIMenu(
			children: [
				UIMenu(options: .displayInline, children: [play]),
				UIMenu(options: .displayInline, children: [playLast, playRestOfAlbumLast]),
			]
		)
	}
}
private final class ExpandedTargetButton: UIButton {
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
