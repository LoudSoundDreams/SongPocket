// 2020-04-28

import UIKit
import SwiftUI
import MusicKit

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate private(set) var list_items: [AlbumListItem] = AlbumListState.uAlbums_fresh().map { .uAlbum($0) }
	var expansion: Expansion = .collapsed { didSet {
		NotificationCenter.default.post(name: Self.expansion_changed, object: self)
	}}
	var select_mode: SelectMode = .view(nil) { didSet {
		NotificationCenter.default.post(name: Self.selection_changed, object: self)
	}}
	fileprivate(set) var signal_albums_reordered = false // Value is meaningless; we’re using this to tell SwiftUI to redraw views. As of iOS 18.3 beta 1, setting the property to the same value again doesn’t trigger observers.
	fileprivate(set) var signal_songs_reordered = false
	fileprivate(set) var size_viewport: (width: CGFloat, height: CGFloat) = (.zero, .zero)
}
extension AlbumListState {
	fileprivate enum AlbumListItem {
		case uAlbum(UAlbum)
		case uSong(USong)
	}
	fileprivate func refresh_items() {
		list_items = {
			let uAlbums = Self.uAlbums_fresh()
			switch expansion {
				case .collapsed: return uAlbums.map { .uAlbum($0) }
				case .expanded(let uA_expanded):
					// If we removed the expanded album, go to collapsed mode.
					guard
						let i_expanded = uAlbums.firstIndex(where: { $0 == uA_expanded }),
						let lrAlbum = Librarian.album_with_uAlbum[uA_expanded]?.referencee
					else {
						expansion = .collapsed
						return uAlbums.map { .uAlbum($0) }
					}
					
					let uSongs_inline: [AlbumListItem] = lrAlbum.uSongs.map { .uSong($0) }
					var result: [AlbumListItem] = uAlbums.map { .uAlbum($0) }
					result.insert(contentsOf: uSongs_inline, at: i_expanded + 1)
					return result
			}
		}()
		
		// In case we removed items the user was doing something with.
		switch select_mode {
			case .view(let uS_activated):
				if let uS_activated, uSongs(with: [uS_activated]).isEmpty {
					select_mode = .view(nil)
				}
			case .select_albums(let old_selected):
				let selectable = Set(uAlbums(with: old_selected))
				if old_selected != selectable {
					select_mode = .select_albums(selectable)
				}
			case .select_songs(let old_selected):
				guard !uSongs().isEmpty else {
					select_mode = .view(nil)
					break
				}
				let selectable = Set(uSongs(with: old_selected))
				if old_selected != selectable{
					select_mode = .select_songs(selectable)
				}
		}
	}
	private static func uAlbums_fresh() -> [UAlbum] {
		guard MusicAuthorization.currentStatus == .authorized
		else { return [] } // Don’t show any albums; show a placeholder.
		return Librarian.the_albums.map { $0.uAlbum }
	}
	fileprivate func row_identifiers() -> [AnyHashable] {
		return list_items.map { switch $0 {
			case .uAlbum(let uAlbum): return uAlbum
			case .uSong(let uSong): return uSong
		}}
	}
	fileprivate func uAlbums(with chosen: Set<UAlbum>? = nil) -> [UAlbum] {
		return list_items.compactMap { switch $0 { // `compactMap` rather than `filter` because we’re returning a different type.
			case .uSong: return nil
			case .uAlbum(let uAlbum):
				guard let chosen else { return uAlbum }
				guard chosen.contains(uAlbum) else { return nil }
				return uAlbum
		}}
	}
	fileprivate func uSongs(with chosen: Set<USong>? = nil) -> [USong] {
		return list_items.compactMap { switch $0 {
			case .uAlbum: return nil
			case .uSong(let uSong):
				guard let chosen else { return uSong }
				guard chosen.contains(uSong) else { return nil }
				return uSong
		}}
	}
	
	func has_album_range(from uA_anchor: UAlbum, forward: Bool) -> Bool {
		guard let i_anchor = uAlbums().firstIndex(where: { $0 == uA_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard uAlbums().indices.contains(i_neighbor) else { return false }
		switch select_mode {
			case .select_songs, .view: return true
			case .select_albums(let uAs_selected):
				let anchor_is_selected = uAs_selected.contains(uA_anchor)
				let neighbor_is_selected = uAs_selected.contains(uAlbums()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	func has_song_range(from uS_anchor: USong, forward: Bool) -> Bool {
		guard let i_anchor = uSongs().firstIndex(where: { $0 == uS_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard uSongs().indices.contains(i_neighbor) else { return false }
		switch select_mode {
			case .select_albums: return false
			case .view: return true
			case .select_songs(let uSs_selected):
				let anchor_is_selected = uSs_selected.contains(uS_anchor)
				let neighbor_is_selected = uSs_selected.contains(uSongs()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	
	func change_album_range(from uA_anchor: UAlbum, forward: Bool) {
		guard let i_anchor = uAlbums().firstIndex(where: { $0 == uA_anchor })
		else { return }
		let old_selected: Set<UAlbum> = {
			switch select_mode {
				case .select_songs, .view: return []
				case .select_albums(let uAs_selected): return uAs_selected
			}
		}()
		let inserting: Bool = !old_selected.contains(uA_anchor)
		let new_selected: Set<UAlbum> = {
			var result = old_selected
			var i_in_range = i_anchor
			while true {
				guard uAlbums().indices.contains(i_in_range) else { break }
				let uA_in_range = uAlbums()[i_in_range]
				
				if inserting {
					guard !result.contains(uA_in_range) else { break }
					result.insert(uA_in_range)
				} else {
					guard result.contains(uA_in_range) else { break }
					result.remove(uA_in_range)
				}
				if forward { i_in_range += 1 } else { i_in_range -= 1 }
			}
			return result
		}()
		switch select_mode {
			case .select_songs: break
			case .view:
				withAnimation {
					select_mode = .select_albums(new_selected)
				}
			case .select_albums:
				select_mode = .select_albums(new_selected)
		}
	}
	func change_song_range(from uS_anchor: USong, forward: Bool) {
		guard let i_anchor = uSongs().firstIndex(where: { $0 == uS_anchor })
		else { return }
		let old_selected: Set<USong> = {
			switch select_mode {
				case .select_albums, .view: return []
				case .select_songs (let uAs_selected): return uAs_selected
			}
		}()
		let inserting: Bool = !old_selected.contains(uS_anchor)
		let new_selected: Set<USong> = {
			var result = old_selected
			var i_in_range = i_anchor
			while true {
				guard uSongs().indices.contains(i_in_range) else { break }
				let uS_in_range = uSongs()[i_in_range]
				
				if inserting {
					guard !result.contains(uS_in_range) else { break }
					result.insert(uS_in_range)
				} else {
					guard result.contains(uS_in_range) else { break }
					result.remove(uS_in_range)
				}
				if forward { i_in_range += 1 } else { i_in_range -= 1 }
			}
			return result
		}()
		switch select_mode {
			case .select_albums: break
			case .view:
				withAnimation {
					select_mode = .select_songs(new_selected)
				}
			case .select_songs:
				select_mode = .select_songs(new_selected)
		}
	}
	
	enum Expansion: Equatable {
		case collapsed
		case expanded(UAlbum)
	}
	@ObservationIgnored fileprivate static let expansion_changed = Notification.Name("LR_AlbumExpandingOrCollapsing")
	
	enum SelectMode: Equatable {
		case view(USong?)
		case select_albums(Set<UAlbum>)
		case select_songs(Set<USong>) // Should always be within the same album.
	}
	@ObservationIgnored fileprivate static let selection_changed = Notification.Name("LR_SelectModeOrSelectionChanged")
}

// MARK: - View controller

final class AlbumTable: LRTableViewController {
	static func init_from_storyboard() -> Self {
		return UIStoryboard(name: "AlbumTable", bundle: nil).instantiateInitialViewController()!
	}
	
	private let list_state = AlbumListState()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(Color(white: .one_eighth))
		tableView.separatorStyle = .none
		b_sort.preferredMenuElementOrder = .fixed
		b_focused.preferredMenuElementOrder = .fixed
		reflect_selection()
		
		NotificationCenter.default.addObserver(self, selector: #selector(refresh_list_items), name: AppleLibrary.did_merge, object: nil)
		Remote.shared.weak_tvc_albums = self
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_expansion), name: AlbumListState.expansion_changed, object: list_state)
		NotificationCenter.default.addObserver(self, selector: #selector(confirm_play), name: SongRow.confirm_play_uSong, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_selection), name: AlbumListState.selection_changed, object: list_state)
	}
	
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		tableView.contentInset.top = Self.top_inset(
			size_view: view.frame.size,
			safeAreaInsets: view.safeAreaInsets)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		list_state.size_viewport = (width: size.width, height: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
		tableView.contentInset.top = Self.top_inset(
			size_view: size,
			safeAreaInsets: view.safeAreaInsets) // Hopefully doesn’t change later.
	}
	
	private static func top_inset(
		size_view: CGSize,
		safeAreaInsets: UIEdgeInsets
	) -> CGFloat {
		let length_square: CGFloat = min(
			size_view.width,
			(size_view.height - safeAreaInsets.bottom)
		)
		
		let result: CGFloat = .zero
		- safeAreaInsets.top // Offsets how `UIScrollView` interprets `contentInset`. Applying it now should make it 0.
		+ (size_view.height / 2)
		- (length_square / 2) // Half the height of a square fitting the window width.
		- (safeAreaInsets.bottom / 2)
		return result
	}
	
	// MARK: Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		refresh_placeholder()
		return 1
	}
	private func refresh_placeholder() {
		contentUnavailableConfiguration = {
			guard MusicAuthorization.currentStatus == .authorized else {
				return UIHostingConfiguration {
					ContentUnavailableView {
						Text(InterfaceText._welcome_title).bold() // As of iOS 18.2 developer beta 4, the Settings app uses this for “No Fonts Installed”.
					} description: {
						Text(InterfaceText._welcome_subtitle)
					} actions: {
						Button(InterfaceText.Start) {
							Task {
								switch MusicAuthorization.currentStatus {
									case .authorized: break // Should never run
									case .notDetermined:
										switch await MusicAuthorization.request() {
											case .denied, .restricted, .notDetermined: break
											case .authorized: LavaRock.integrate_Apple_Music()
											@unknown default: break
										}
									case .denied, .restricted:
										guard let url_settings = URL(string: UIApplication.openSettingsURLString) else { return }
										let _ = await UIApplication.shared.open(url_settings)
									@unknown default: break
								}
							}
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if list_state.list_items.isEmpty {
				return UIHostingConfiguration {
					Image(systemName: "music.note")
						.foregroundStyle(Color(white: .one_half))
						.font(.title)
						.accessibilityLabel(InterfaceText.No_music)
						.accessibilityRemoveTraits(.isImage)
				}.margins(.all, .zero)
			}
			return nil
		}()
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !has_set_ids_rows_onscreen {
			has_set_ids_rows_onscreen = true
			ids_rows_onscreen = list_state.row_identifiers()
		}
		return list_state.list_items.count
	}
	private var has_set_ids_rows_onscreen = false
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch list_state.list_items[indexPath.row] {
			case .uAlbum(let uAlbum):
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
				cell.backgroundColor = .clear
				cell.selectedBackgroundView = {
					let result = UIView()
					result.backgroundColor = .tintColor.withAlphaComponent(.one_half)
					return result
				}()
				list_state.size_viewport = (
					width: view.frame.width,
					height: view.frame.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumRow(uAlbum: uAlbum, list_state: list_state)
				}.margins(.all, .zero)
				return cell
			case .uSong(let uSong):
				switch list_state.expansion {
					case .collapsed: return UITableViewCell() // Should never run
					case .expanded(let uAlbum_expanded):
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
						cell.backgroundColor = .clear
						cell.selectedBackgroundView = {
							let result = UIView()
							result.backgroundColor = .tintColor.withAlphaComponent(.one_half)
							return result
						}()
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(
								uSong: uSong,
								uAlbum: uAlbum_expanded,
								list_state: list_state)
						}.margins(.all, .zero)
						return cell
				}
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: Events
	
	@objc private func refresh_list_items() {
		Task {
			list_state.refresh_items()
			b_sort.menu = menu_sort()
			b_focused.menu = menu_focused()
			guard await apply_ids_rows(list_state.row_identifiers()) else { return }
		}
	}
	
	func show_current() {
		guard
			let uSong_current = ApplicationMusicPlayer.uSong_current,
			let album_target = Librarian.album_containing_uSong[uSong_current]?.referencee
		else { return }
		let uAlbum_target = album_target.uAlbum
		guard let row_target = list_state.list_items.firstIndex(where: { switch $0 {
			case .uSong: return false
			case .uAlbum(let uAlbum): return uAlbum == uAlbum_target
		}}) else { return }
		tableView.performBatchUpdates {
			tableView.scrollToRow(at: IndexPath(row: row_target, section: 0), at: .top, animated: true)
		} completion: { _ in
			self.list_state.expansion = .expanded(uAlbum_target)
		}
	}
	
	@objc private func reflect_expansion() {
		switch list_state.expansion {
			case .collapsed:
				Task {
					list_state.refresh_items() // Immediately proceed to update the table view; don’t wait until a separate `Task`. As of iOS 17.6 developer beta 2, `UITableView` has a bug where it might call `cellForRowAt` with invalidly large `IndexPath`s: it’s trying to draw subsequent rows after we change a cell’s height in a `UIHostingConfiguration`, but forgetting to call `numberOfRowsInSection` first.
					b_sort.menu = menu_sort()
					b_focused.menu = menu_focused()
					let _ = await apply_ids_rows(list_state.row_identifiers())
				}
			case .expanded(let uA_to_expand):
				Task {
					guard list_state.uAlbums().contains(where: { $0 == uA_to_expand }) else { return }
					list_state.refresh_items()
					b_sort.menu = menu_sort()
					b_focused.menu = menu_focused()
					let _ = await apply_ids_rows(list_state.row_identifiers(), running_before_continuation: {
						let row_target: Int = self.list_state.list_items.firstIndex(where: { switch $0 {
							case .uSong: return false
							case .uAlbum(let uAlbum): return uAlbum == uA_to_expand
						}})!
						self.tableView.scrollToRow(at: IndexPath(row: row_target, section: 0), at: .top, animated: true)
					})
				}
		}
	}
	
	@objc private func reflect_selection() {
		switch list_state.select_mode {
			case .view(let uS_activated):
				setToolbarItems([b_sort, .flexibleSpace(), Remote.shared.b_remote, .flexibleSpace(), b_focused], animated: true)
				b_sort.menu = menu_sort()
				b_focused.menu = menu_focused()
				b_focused.image = image_focused
				if uS_activated == nil {
					dismiss(animated: true) // In case “confirm play” action sheet is presented.
				}
			case .select_albums(let uAs_selected):
				setToolbarItems([b_sort, .flexibleSpace(), b_album_promote, .flexibleSpace(), b_album_demote, .flexibleSpace(), b_focused], animated: true)
				b_album_promote.isEnabled = !uAs_selected.isEmpty
				b_album_demote.isEnabled = b_album_promote.isEnabled
				b_sort.menu = menu_sort() // In case it’s open.
				b_focused.menu = menu_focused()
				b_focused.image = image_focused_highlighted
			case .select_songs(let uSs_selected):
				setToolbarItems([b_sort, .flexibleSpace(), b_song_promote, .flexibleSpace(), b_song_demote, .flexibleSpace(), b_focused], animated: true)
				b_song_promote.isEnabled = !uSs_selected.isEmpty
				b_song_demote.isEnabled = b_song_promote.isEnabled
				b_sort.menu = menu_sort()
				b_focused.menu = menu_focused()
				b_focused.image = image_focused_highlighted
		}
	}
	
	@objc private func confirm_play(notification: Notification) {
		guard
			let uSong_activated = notification.object as? USong,
			let view_popover_anchor: UIView = { () -> UITableViewCell? in
				guard let row_activated = list_state.list_items.firstIndex(where: { switch $0 {
					case .uAlbum: return false
					case .uSong(let uSong): return uSong == uSong_activated
				}}) else { return nil }
				return tableView.cellForRow(at: IndexPath(row: row_activated, section: 0))
			}()
		else { return }
		
		list_state.select_mode = .view(uSong_activated) // The UI is clearer if we leave the row selected while the action sheet is onscreen. You must eventually deselect the row in every possible scenario after this moment.
		
		let action_sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		action_sheet.popoverPresentationController?.sourceView = view_popover_anchor
		action_sheet.addAction(
			UIAlertAction(title: InterfaceText.Start_Playing, style: .default) { _ in
				self.list_state.select_mode = .view(nil)
				Task {
					guard let album_chosen = Librarian.album_containing_uSong[uSong_activated]?.referencee else { return }
					await ApplicationMusicPlayer._shared?.play_now(
						album_chosen.uSongs,
						starting_at: uSong_activated)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		action_sheet.addAction(
			UIAlertAction(title: InterfaceText.Cancel, style: .cancel) { _ in
				self.list_state.select_mode = .view(nil)
			}
		)
		present(action_sheet, animated: true)
	}
	
	// MARK: Editing
	
	private lazy var a_end_selecting = UIAction(title: InterfaceText.Done, image: UIImage(systemName: "checkmark.circle.fill")) { [weak self] _ in self?.end_selecting_animated() }
	private func end_selecting_animated() {
		withAnimation {
			self.list_state.select_mode = .view(nil)
		}
	}
	
	private let b_sort = UIBarButtonItem(title: InterfaceText.Sort, image: UIImage(systemName: "arrow.up.arrow.down.circle.fill")?.applying_hierarchical_tint())
	private lazy var b_focused = UIBarButtonItem(title: InterfaceText.More)
	private lazy var image_focused = image_focused_highlighted?.applying_hierarchical_tint()
	private let image_focused_highlighted = UIImage(systemName: "ellipsis.circle.fill")
	
	private lazy var b_album_promote = UIBarButtonItem(primaryAction: a_album_promote, menu: UIMenu(children: [a_album_float]))
	private lazy var b_album_demote = UIBarButtonItem(primaryAction: a_album_demote, menu: UIMenu(children: [a_album_sink]))
	
	private lazy var b_song_promote = UIBarButtonItem(primaryAction: a_song_promote, menu: UIMenu(children: [a_song_float]))
	private lazy var b_song_demote = UIBarButtonItem(primaryAction: a_song_demote, menu: UIMenu(children: [a_song_sink]))
	
	private lazy var a_album_promote = UIAction(title: InterfaceText.Move_Up, image: UIImage.move_up.applying_hierarchical_tint()) { [weak self] _ in self?.promote_albums() }
	private lazy var a_album_demote = UIAction(title: InterfaceText.Move_Down, image: UIImage.move_down.applying_hierarchical_tint()) { [weak self] _ in self?.demote_albums() }
	private lazy var a_album_float = UIAction(title: InterfaceText.To_Top, image: UIImage.to_top) { [weak self] _ in self?.float_albums() }
	private lazy var a_album_sink = UIAction(title: InterfaceText.To_Bottom, image: UIImage.to_bottom) { [weak self] _ in self?.sink_albums() }
	
	private lazy var a_song_promote = UIAction(title: InterfaceText.Move_Up, image: UIImage.move_up.applying_hierarchical_tint()) { [weak self] _ in self?.promote_songs() }
	private lazy var a_song_demote = UIAction(title: InterfaceText.Move_Down, image: UIImage.move_down.applying_hierarchical_tint()) { [weak self] _ in self?.demote_songs() }
	private lazy var a_song_float = UIAction(title: InterfaceText.To_Top, image: UIImage.to_top) { [weak self] _ in self?.float_songs() }
	private lazy var a_song_sink = UIAction(title: InterfaceText.To_Bottom, image: UIImage.to_bottom) { [weak self] _ in self?.sink_songs() }
	
	// MARK: Focused
	
	private func menu_sort() -> UIMenu? {
		return UIMenu(
			children: {
				switch list_state.expansion {
					case .collapsed: return menu_sections_album_sort
					case .expanded: return menu_sections_song_sort
				}
			}()
		)
	}
	
	private func menu_focused() -> UIMenu {
		var submenus_inline: [UIMenu] = []
		switch list_state.select_mode {
			case .view: break
			case .select_albums, .select_songs:
				submenus_inline.append(UIMenu(
					options: .displayInline,
					children: [
						a_end_selecting,
					]
				))
		}
		submenus_inline.append(UIMenu(
			options: .displayInline,
			children: [
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let uSongs = uSongs_focused()
					let action = UIAction(title: InterfaceText.Play, image: UIImage(systemName: "play")) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							await ApplicationMusicPlayer._shared?.play_now(uSongs)
						}
					}
					if uSongs.isEmpty { action.attributes.formUnion(.disabled) }
					use([action])
				},
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let uSongs = uSongs_focused()
					let action = UIAction(title: InterfaceText.Randomize(for_localeLanguageIdentifiers: Locale.preferredLanguages), image: UIImage.random_die()) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							// Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
							let uSongs_reordered = uSongs.in_any_other_order { $0 == $1 }
							await ApplicationMusicPlayer._shared?.play_now(uSongs_reordered)
						}
					}
					if uSongs.count <= 1 { action.attributes.formUnion(.disabled) }
					use([action])
				},
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let uSongs = uSongs_focused()
					let action = UIAction(title: InterfaceText.Add_to_Queue, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							await ApplicationMusicPlayer._shared?.play_later(uSongs)
						}
					}
					if uSongs.isEmpty { action.attributes.formUnion(.disabled) }
					use([action])
				},
			]
		))
		return UIMenu(children: submenus_inline)
	}
	private func uSongs_focused() -> [USong] { // In display order.
		switch list_state.select_mode {
			case .select_albums(let uAs_selected):
				var result: [USong] = []
				list_state.uAlbums(with: uAs_selected).forEach { uAlbum in // Order matters.
					guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee else { return }
					result.append(contentsOf: lrAlbum.uSongs)
				}
				return result
			case .select_songs(let uSs_selected):
				return list_state.uSongs(with: uSs_selected)
			case .view:
				switch list_state.expansion {
					case .collapsed:
						var result: [USong] = []
						list_state.uAlbums().forEach { uAlbum in
							guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee else { return }
							result.append(contentsOf: lrAlbum.uSongs)
						}
						return result
					case .expanded:
						return list_state.uSongs()
				}
		}
	}
	
	// MARK: Sorting
	
	private lazy var menu_sections_album_sort: [UIMenu] = {
		let groups: [[AlbumOrder]] = [[.recently_added, .recently_released], [.reverse, .random]]
		return groups.map { albumOrders in
			UIMenu(options: .displayInline, children: albumOrders.map { order in
				UIDeferredMenuElement.uncached { [weak self] use in
					// Runs each time the button presents the menu
					guard let self else { return }
					let action = order.action { [weak self] in self?.sort_albums(by: order) }
					if !can_sort_albums(by: order) { action.attributes.formUnion(.disabled) } // You must do this inside `UIDeferredMenuElement.uncached`.
					use([action])
				}
			})
		}
	}()
	private func can_sort_albums(by album_order: AlbumOrder) -> Bool {
		let uAlbums = uAlbums_to_sort()
		guard uAlbums.count >= 2 else { return false }
		switch list_state.select_mode {
			case .select_songs, .view: break
			case .select_albums(let uAs_selected):
				let rs_selected = list_state.uAlbums().indices(where: { uAlbum in
					uAs_selected.contains(uAlbum)
				})
				guard rs_selected.ranges.count <= 1 else { return false }
		}
		switch album_order {
			case .random, .reverse, .recently_added: return true
			case .recently_released: return uAlbums.contains {
				nil != AppleLibrary.shared.albumInfo(uAlbum: $0)?._date_released
			}
		}
	}
	private lazy var menu_sections_song_sort: [UIMenu] = {
		let groups: [[SongOrder]] = [[.track], [.reverse, .random]]
		return groups.map { songOrders in
			UIMenu(options: .displayInline, children: songOrders.map { order in
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let action = order.action { [weak self] in self?.sort_songs(by: order) }
					var enabling = true
					if uSongs_to_sort().count <= 1 { enabling = false }
					switch list_state.select_mode {
						case .select_albums, .view: break
						case .select_songs(let uSs_selected):
							let rs_selected = list_state.uSongs().indices(where: { uSong in
								uSs_selected.contains(uSong)
							})
							if rs_selected.ranges.count >= 2 { enabling = false }
					}
					if !enabling { action.attributes.formUnion(.disabled) }
					use([action])
				}
			})
		}
	}()
	
	private func sort_albums(by albumOrder: AlbumOrder) {
		Task {
			Librarian.sort_albums(uAlbums_to_sort(), by: albumOrder)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func sort_songs(by songOrder: SongOrder) {
		Task {
			Librarian.sort_songs(uSongs_to_sort(), by: songOrder)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	private func uAlbums_to_sort() -> Set<UAlbum> {
		switch list_state.select_mode {
			case .select_songs: return []
			case .view: return Set(list_state.uAlbums())
			case .select_albums(let uAs_selected): return uAs_selected
		}
	}
	private func uSongs_to_sort() -> Set<USong> {
		switch list_state.select_mode {
			case .select_albums: return []
			case .view: return Set(list_state.uSongs())
			case .select_songs(let uSs_selected): return uSs_selected
		}
	}
	
	// MARK: Moving up and down
	
	private func promote_albums() {
		Task {
			guard case let .select_albums(uAs_selected) = list_state.select_mode else { return }
			Librarian.promote_albums(uAs_selected, to_limit: false)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle() // Refresh “select range” commands.
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state) // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func promote_songs() {
		Task {
			guard case let .select_songs(uSs_selected) = list_state.select_mode else { return }
			Librarian.promote_songs(uSs_selected, to_limit: false)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state)
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	private func demote_albums() {
		Task {
			guard case let .select_albums(uAs_selected) = list_state.select_mode else { return }
			Librarian.demote_albums(uAs_selected, to_limit: false)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state)
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func demote_songs() {
		Task {
			guard case let .select_songs(uSs_selected) = list_state.select_mode else { return }
			Librarian.demote_songs(uSs_selected, to_limit: false)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state)
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	// MARK: To top and bottom
	
	private func float_albums() {
		Task {
			guard case let .select_albums(uAs_selected) = list_state.select_mode else { return }
			Librarian.promote_albums(uAs_selected, to_limit: true)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			list_state.select_mode = .select_albums([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func float_songs() {
		Task {
			guard case let .select_songs(uSs_selected) = list_state.select_mode else { return }
			Librarian.promote_songs(uSs_selected, to_limit: true)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			list_state.select_mode = .select_songs([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	private func sink_albums() {
		Task {
			guard case let .select_albums(uAs_selected) = list_state.select_mode else { return }
			Librarian.demote_albums(uAs_selected, to_limit: true)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			list_state.select_mode = .select_albums([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func sink_songs() {
		Task {
			guard case let .select_songs(uSs_selected) = list_state.select_mode else { return }
			Librarian.demote_songs(uSs_selected, to_limit: true)
			Librarian.save()
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			list_state.select_mode = .select_songs([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
}
