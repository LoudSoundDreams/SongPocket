// 2025-01-17

import SwiftUI
import MusicKit

@MainActor struct SongRow: View {
	let uSong: USong
	let uAlbum: UAlbum
	let exhibit: Exhibit
	static let nudge_leading: CGFloat = .eight * 1/2
	
	private let catalog: AppleCatalog = .shared
	var body: some View {
		VStack(spacing: .zero) {
			HStack(alignment: .firstTextBaseline) {
				let songInfo: SongInfo? = {
					guard let mkSong = catalog.mkSongs_cache[uSong] else {
						Task { await catalog.cache_mkSong(uSong: uSong) } // SwiftUI redraws this view afterward because this view observes the cache.
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
				Spacer()
				Group {
//					b_select
					menu_select(songInfo, albumInfo)
				}
				.dynamicType_default_to_plus_3()
				.imageScale(.large)
			}
			.padding(.top, .eight * 3/2).padding(.bottom, .eight * 7/4)
			Separator()
		}
		.padding(.horizontal, {
			guard WorkingOn.toolbar else { return nil } // Not `.zero`, but the default.
			return LavaRock.padding_bubbleBar_horizontal + BubbleBar.width_border
		}())
		.padding(.leading, Self.nudge_leading) // Align with outermost toolbar buttons.
		.background { highlight }
		.overlay { border }
		.frame(maxWidth: exhibit.length_artwork)
		.frame(maxWidth: .infinity)
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.touching($is_pressing)
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
				value: exhibit.selection)
	}
	private var is_highlighted: Bool {
		switch exhibit.selection {
			case .mode_albums, .mode_songs: return false
			case .view(let uS_activated):
				if is_pressing { return true }
				return uS_activated == uSong
		}
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
					guard uSong == LCD.shared.uSong_current
					else { return Color.primary }
					if LCD.shared.is_playing {
						return Color.accentColor
					} else { return Color.accentColor.opacity(.one_half) }
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
	
	private var b_select: some View {
		Button {
		} label: {
			Image(systemName: SF.select_fill).accessibilityLabel(InterfaceText.Select).accessibilityRemoveTraits(.isSelected)
				.symbolRenderingMode(.hierarchical)
		}
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
						Button(InterfaceText.Select, systemImage: SF.select_hollow) {
							withAnimation {
								exhibit.selection = .mode_songs([uSong])
							}
						}.disabled(catalog.is_merging)
						Divider()
				}
				b_above
				b_below
			}
		} label: {
			if exhibit.has_selected_song(uSong)
			{ EllipsisSelected() }
			else { EllipsisUnselected() }
		}
	}
	private var b_above: some View {
		Button(
			exhibit.has_selected_song(uSong)
			? InterfaceText.Deselect_Up : InterfaceText.Select_Up,
			systemImage: exhibit.has_selected_song(uSong)
			? SF.deselect_up : SF.select_up
		) {
			exhibit.change_song_range(from: uSong, forward: false)
		}.disabled({
			return (exhibit.signal_artifacts && false) ||
			catalog.is_merging ||
			!exhibit.has_song_range(from: uSong, forward: false)
		}())
	}
	private var b_below: some View {
		Button(
			exhibit.has_selected_song(uSong)
			? InterfaceText.Deselect_Down : InterfaceText.Select_Down,
			systemImage: exhibit.has_selected_song(uSong)
			? SF.deselect_down : SF.select_down
		) {
			exhibit.change_song_range(from: uSong, forward: true)
		}.disabled({
			return (exhibit.signal_artifacts && false) ||
			catalog.is_merging ||
			!exhibit.has_song_range(from: uSong, forward: true)
		}())
	}
	
	private func tapped() {
		switch exhibit.selection {
			case .mode_albums: return
			case .view: NotificationCenter.default.post(name: .confirm_play, object: uSong)
			case .mode_songs(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uSong) {
					new_selected.remove(uSong)
				} else { new_selected.insert(uSong) }
				exhibit.selection = .mode_songs(new_selected)
		}
	}
}
