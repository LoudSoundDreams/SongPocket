// 2025-01-17

import SwiftUI

@MainActor struct SongRow: View {
	static let nudge_text: CGFloat = .eight * 1/4
	let uSong: USong
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	private let catalog: AppleCatalog = .shared
	var body: some View {
		VStack(spacing: .zero) {
			HStack(alignment: .firstTextBaseline) {
				let songInfo: SongInfo? = {
					guard let mkSong = catalog.mkSong_for_uSong_cache[uSong]
					else {
						let _ = catalog.signal_mkSong_cache
						Task {
							await catalog.cache_mkSong(for_uSong: uSong)
						}
						return nil
					}
					return SongInfo(
						_disc: mkSong.discNumber,
						_track: mkSong.trackNumber,
						_title: mkSong.title,
						_artist: mkSong.artistName)
				}()
				let albumInfo: AlbumInfo? = catalog.albumInfo(uAlbum: uAlbum)
				
				stack_info(songInfo, albumInfo)
					.padding(.leading, Self.nudge_text)
				Spacer()
				ZStack { // Keep the layout stable by always including all subviews.
					Image(systemName: SF.waveform)
						.foregroundStyle(
							LCD.shared.is_playing
							? Color.accentColor : Color(white: .one_fourth))
						.accessibilityLabel(
							LCD.shared.is_playing
							? InterfaceText.Now_playing : InterfaceText.Paused)
						.opacity(indicating_current ? 1 : .zero)
						.accessibilityHidden(!indicating_current)
						.accessibilitySortPriority(10)
					menu_select(songInfo, albumInfo)
						.imageScale(.large)
						.opacity(can_select_song ? 1 : .zero)
						.accessibilityHidden(!can_select_song) // As of iOS 18.3.1, VoiceOver sometimes unnecessarily reads this, even with `accessibilityHidden(true)`.
				}
				.dynamicType_clamped()
				.padding(.top, -Self.padding_top) // Let the text determine the row height, not the accessory.
				.padding(.bottom, -Self.padding_bottom)
			}
			.padding(.top, Self.padding_top)
			.padding(.bottom, Self.padding_bottom)
			Separator()
		}
		.padding(.horizontal)
		.overlay { highlight }
		.overlay { border }
		.frame(maxWidth: exhibit.length_artwork)
		.frame(maxWidth: .infinity)
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.confirmationDialog("", isPresented: $confirming) {
			Button(InterfaceText.Start_Playing) { Task {
				guard let album = Librarian.album_containing_uSong[uSong]?.referencee
				else { return }
				await Tape.play_now(album.uSongs, starting_at: uSong)
			}}.accessibilityAddTraits(.startsMediaSession)
		}
	}
	private var indicating_current: Bool {
		return !can_select_song &&
		LCD.shared.uSong_current == uSong
	}
	private var can_select_song: Bool {
		switch exhibit.selection {
			case .mode_songs: return true
			case .mode_albums, .view: return false
		}
	}
	private static let padding_top: CGFloat = .eight * 7/4
	private static let padding_bottom: CGFloat = .eight * 2
	@ViewBuilder private var highlight: some View {
		Color.accentColor
			.opacity(confirming ? .one_half : .zero)
			.animation(confirming ? nil : .default, value: confirming)
	}
	@ViewBuilder private var border: some View {
		switch exhibit.selection {
			case .view, .mode_albums: EmptyView()
			case .mode_songs(let uSs_selected):
				if uSs_selected.contains(uSong) {
					BorderSelected()
				} else { BorderUnselected() }
		}
	}
	
	@ViewBuilder private func stack_info(
		_ songInfo: SongInfo?,
		_ albumInfo: AlbumInfo?
	) -> some View {
		let title: String? = songInfo?._title
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			Text(title ?? InterfaceText._tilde)
			if
				let artist = songInfo?._artist, let album_artist = albumInfo?._artist,
				artist != "", album_artist != "",
				artist != album_artist
			{
				Text(artist)
					.foregroundStyle(.secondary)
					.font_footnote()
			}
		}
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title].compactMap { $0 })
		.accessibilityAddTraits(.isButton)
	}
	
	private func menu_select(
		_ songInfo: SongInfo?,
		_ albumInfo: AlbumInfo?
	) -> some View {
		Menu {
			Section({ () -> String in
				var result: String = InterfaceText._octothorpe
				guard let songInfo, let albumInfo else { return result }
				result.append(" ")
				result.append({
					guard let track = songInfo._track else { return InterfaceText._tilde }
					
					let f_track = String(track)
					if albumInfo._disc_max <= 1 { return f_track }
					
					let f_disc: String = {
						guard let disc = songInfo._disc else { return InterfaceText._tilde }
						return String(disc)
					}()
					return "\(f_disc)\(InterfaceText._interpunct)\(f_track)"
				}())
				return result
			}()) {
				b_above
				b_below
			}
		} label: {
			if is_selected
			{ EllipsisSelected() }
			else { EllipsisUnselected() }
		}
	}
	private var b_above: some View {
		Button(
			is_selected
			? InterfaceText.Deselect_Up : InterfaceText.Select_Up,
			systemImage: is_selected
			? SF.circle_triangle_up_fill : SF.circle_triangle_up_hollow
		) {
			exhibit.toggle_range(from_uSong: uSong, forward: false)
		}.disabled(!exhibit.can_select_range(from_uSong: uSong, forward: false))
	}
	private var b_below: some View {
		Button(
			is_selected
			? InterfaceText.Deselect_Down : InterfaceText.Select_Down,
			systemImage: is_selected
			? SF.circle_triangle_down_fill : SF.circle_triangle_down_hollow
		) {
			exhibit.toggle_range(from_uSong: uSong, forward: true)
		}.disabled(!exhibit.can_select_range(from_uSong: uSong, forward: true))
	}
	private var is_selected: Bool {
		switch exhibit.selection {
			case .view, .mode_albums: return false
			case .mode_songs(let uSs_selected): return uSs_selected.contains(uSong)
		}
	}
	
	private func tapped() {
		switch exhibit.selection {
			case .mode_albums: return
			case .view:
				confirming = true
			case .mode_songs(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uSong) {
					new_selected.remove(uSong)
				} else { new_selected.insert(uSong) }
				exhibit.selection = .mode_songs(new_selected)
		}
	}
	@State private var confirming = false
}
