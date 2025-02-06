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
						.opacity(( // 2do: Hide from accessibility features.
							!can_select_song &&
							LCD.shared.uSong_current == uSong
						) ? 1 : .zero)
					menu_select(songInfo, albumInfo)
						.imageScale(.large)
						.opacity(can_select_song ? 1 : .zero) // 2do: Accessibility.
				}.dynamicType_default_to_plus_3()
			}
			.padding(.top, .eight * 3/2).padding(.bottom, .eight * 7/4)
			Separator()
		}
		.padding(.horizontal)
		.background { highlight }
		.overlay { border }
		.frame(maxWidth: exhibit.length_artwork)
		.frame(maxWidth: .infinity)
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	private var can_select_song: Bool {
		switch exhibit.selection {
			case .mode_songs: return true
			case .mode_albums, .view: return false
		}
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
	@ViewBuilder private var highlight: some View {
		Color.accentColor
			.opacity(is_highlighted ? .one_half : .zero)
			.animation(
				is_highlighted ? nil : .default,
				value: is_highlighted)
	}
	private var is_highlighted: Bool {
		switch exhibit.selection {
			case .mode_albums, .mode_songs: return false
			case .view: return uSong == exhibit.activated
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
			case .mode_songs(let uSs_selected):
				return uSs_selected.contains(uSong)
		}
	}
	
	private func tapped() {
		switch exhibit.selection {
			case .mode_albums: return
			case .view:
				exhibit.activated = uSong
			case .mode_songs(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uSong) {
					new_selected.remove(uSong)
				} else { new_selected.insert(uSong) }
				exhibit.selection = .mode_songs(new_selected)
		}
	}
}
