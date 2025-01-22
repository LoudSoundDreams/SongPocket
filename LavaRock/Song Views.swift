// 2025-01-17

import SwiftUI
import MusicKit

@MainActor struct SongRow: View {
	let uSong: USong
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	private let apple_lib: AppleLibrary = .shared
	var body: some View {
		VStack(spacing: .zero) {
			HStack(alignment: .firstTextBaseline) {
				let songInfo: SongInfo? = {
					guard let mkSong = apple_lib.mkSongs_cache[uSong] else {
						Task { await apple_lib.cache_mkSong(uSong: uSong) } // SwiftUI redraws this view afterward because this view observes the cache.
						return nil
					}
					return SongInfo(
						_disc: mkSong.discNumber,
						_track: mkSong.trackNumber,
						_title: mkSong.title,
						_artist: mkSong.artistName)
				}()
				let albumInfo: AlbumInfo? = apple_lib.albumInfo(uAlbum: uAlbum)
				
				stack_info(songInfo, albumInfo)
				Spacer()
				menu_select(songInfo, albumInfo)
					.dynamicType_default_to_max()
					.imageScale(.large)
			}
			.padding(.horizontal)
			.padding(.leading, .eight * 1/2) // Align with `AlbumLabel`.
			.padding(.top, .eight * 3/2).padding(.bottom, .eight * 7/4)
			Separator().padding(.horizontal).padding(.leading, .eight * 1/2)
		}
		.background { highlight }
		.overlay { border }
		.frame(maxWidth: exhibit.length_artwork)
		.frame(maxWidth: .infinity)
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.onLongPressGesture(minimumDuration: .zero) {
		} onPressingChanged: {
			is_pressing = $0
		}
	}
	@ViewBuilder private var border: some View {
		switch exhibit.selection {
			case .view, .mode_albums: EmptyView()
			case .mode_songs(let uSs_selected):
				let is_selected = uSs_selected.contains(uSong)
				let is_bright = is_selected != is_pressing
				if is_bright {
					BorderSelected()
				} else { BorderUnselected() }
		}
	}
	@ViewBuilder private var highlight: some View {
		let highlighting: Bool = {
			switch exhibit.selection {
				case .mode_albums, .mode_songs: return false
				case .view(let uS_activated):
					if is_pressing { return true }
					return uS_activated == uSong
			}
		}()
		Color.accentColor
			.opacity(highlighting ? .one_half : .zero)
			.animation(highlighting ? nil : .default, value: exhibit.selection)
	}
	@State private var is_pressing = false
	
	@ViewBuilder private func stack_info(
		_ songInfo: SongInfo?,
		_ albumInfo: AlbumInfo?
	) -> some View {
		let title: String? = songInfo?._title
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			Text(title ?? InterfaceText._tilde)
				.foregroundStyle({
					let _ = PlayerState.shared.signal
					let _ = apple_lib.is_merging // I think this should be unnecessary, but I’ve seen the indicator get outdated after deleting a recently played song.
					return ApplicationMusicPlayer.StatusNowPlaying(uSong: uSong).foreground_color
				}())
			if
				let artist_song = songInfo?._artist,
				let artist_album = albumInfo?._artist,
				artist_song != "", artist_album != "",
				artist_song != artist_album
			{
				Text(artist_song)
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
				guard let songInfo, let albumInfo else { return InterfaceText._octothorpe }
				let numbers: String = {
					let f_track: String = {
						guard let track = songInfo._track else { return InterfaceText._tilde }
						return String(track)
					}()
					guard albumInfo._disc_max >= 2 else { return f_track }
					
					let f_disc: String = {
						guard let disc = songInfo._disc else { return InterfaceText._tilde }
						return String(disc)
					}()
					return "\(f_disc)\(InterfaceText._interpunct)\(f_track)"
				}()
				return "\(InterfaceText._octothorpe) \(numbers)"
			}()) {
				switch exhibit.selection {
					case .mode_albums, .mode_songs: EmptyView()
					case .view:
						Button(InterfaceText.Select, systemImage: "checkmark.circle") {
							withAnimation {
								exhibit.selection = .mode_songs([uSong])
							}
						}.disabled(apple_lib.is_merging)
						Divider()
				}
				b_above
				b_below
			}
		} label: {
			if exhibit.has_selected_song(uSong)
			{ IconSelected() }
			else { IconUnselected() }
		}
	}
	private var b_above: some View {
		Button(
			exhibit.has_selected_song(uSong)
			? InterfaceText.Deselect_Up
			: InterfaceText.Select_Up,
			systemImage: exhibit.has_selected_song(uSong)
			? "arrowtriangle.up.circle.fill"
			: "arrowtriangle.up.circle"
		) {
			exhibit.change_song_range(from: uSong, forward: false)
		}.disabled({
			return (exhibit.signal_artifacts && false) ||
			apple_lib.is_merging ||
			!exhibit.has_song_range(from: uSong, forward: false)
		}())
	}
	private var b_below: some View {
		Button(
			exhibit.has_selected_song(uSong)
			? InterfaceText.Deselect_Down
			: InterfaceText.Select_Down,
			systemImage: exhibit.has_selected_song(uSong)
			? "arrowtriangle.down.circle.fill"
			: "arrowtriangle.down.circle"
		) {
			exhibit.change_song_range(from: uSong, forward: true)
		}.disabled({
			return (exhibit.signal_artifacts && false) ||
			apple_lib.is_merging ||
			!exhibit.has_song_range(from: uSong, forward: true)
		}())
	}
	
	private func tapped() {
		switch exhibit.selection {
			case .mode_albums: return
			case .view: NotificationCenter.default.post(name: Self.confirm_play_uSong, object: uSong)
			case .mode_songs(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uSong) {
					new_selected.remove(uSong)
				} else { new_selected.insert(uSong) }
				exhibit.selection = .mode_songs(new_selected)
		}
	}
	static let confirm_play_uSong = Notification.Name("LR_ConfirmPlay")
}
