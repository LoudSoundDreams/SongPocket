// 2020-04-28

import UIKit
import SwiftUI
import MusicKit

@MainActor @Observable final class Exhibit {
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_librarian), name: .librarian_merged, object: nil)
	}
	
	@ObservationIgnored fileprivate private(set) var artifacts: [Artifact] =
	Exhibit.uAlbums_fresh().map { .row_album($0) } { didSet {
		signal_artifacts += 1
		NotificationCenter.default.post(name: .exhibit_artifacts, object: self)
	}}
	private(set) var signal_artifacts = 0 // Value is meaningless; we’re setting this property to tell SwiftUI to redraw views. (As of iOS 18.3, setting it to the same value again does trigger observers, but I’m being safe.)
	
	var focus: Focus = .covers { didSet {
		refresh_artifacts()
		
		switch focus {
			case .spotlight:
				Global.shared.showcase_is_spotlighting = true
			case .covers, .expanded:
				Global.shared.showcase_is_spotlighting = false
		}
		NotificationCenter.default.post(name: .exhibit_focus, object: self)
	}}
	
	var selection: Selection = .view { didSet {
		NotificationCenter.default.post(name: .exhibit_selection, object: nil)
	}}
	
	var activated: USong? { didSet { // Only use this when `selection == .view` and `focus == .expanded`.
		NotificationCenter.default.post(name: .song_activation, object: nil)
	}}
	
	fileprivate(set) var length_artwork: CGFloat!
}
extension Exhibit {
	fileprivate enum Artifact {
		case row_album(UAlbum)
		case row_song(USong)
	}
	
	enum Focus {
		case covers
		case spotlight(UAlbum)
		case expanded(UAlbum)
	}
	
	enum Selection {
		case view
		case mode_albums(Set<UAlbum>)
		case mode_songs(Set<USong>)
	}
	
	@objc private func reflect_librarian() {
		refresh_artifacts()
	}
	
	@ObservationIgnored fileprivate var rowIDs: [AnyHashable] { artifacts }
	private func refresh_artifacts() {
		artifacts = {
			let uAs_fresh = Self.uAlbums_fresh()
			
			// Merging might have removed the spotlighted or expanded album.
			// Set `focus` only if necessary; it triggers this method.
			switch focus {
				case .covers:
					break
				case .spotlight(let uA_spotlighted):
					if !uAs_fresh.contains(uA_spotlighted)
					{ focus = .covers }
				case .expanded(let uA_expanded):
					if !uAs_fresh.contains(uA_expanded)
					{ focus = .covers }
			}
			
			switch focus {
				case .covers, .spotlight:
					return uAs_fresh.map { .row_album($0) }
				case .expanded(let uA_expanded):
					var result: [Artifact] = []
					uAs_fresh.forEach { uAlbum in
						result.append(.row_album(uAlbum))
						
						if uAlbum == uA_expanded {
							guard
								let album_expanded = Librarian.album_with_uAlbum[uAlbum]?.referencee
							else { return }
							let to_inline: [USong] = album_expanded.uSongs
							result.append(contentsOf: to_inline.map { .row_song($0) })
						}
					}
					return result
			}
		}()
		
		// Merging might have removed selected items or the activated song.
		switch selection {
			case .view:
				if let activated, uSongs(with: [activated]).isEmpty {
					self.activated = nil
				}
			case .mode_albums(let old_selected):
				guard !uAlbums().isEmpty else {
					selection = .view // We could let users manually exit select mode, but they can’t re-enter because the “Select” button exists only on album rows, so don’t leave them in a transient state.
					break
				}
				let selectable = Set(uAlbums(with: old_selected))
				if old_selected != selectable {
					selection = .mode_albums(selectable)
				}
			case .mode_songs(let old_selected):
				guard !uSongs().isEmpty else {
					selection = .view
					break
				}
				let selectable = Set(uSongs(with: old_selected))
				if old_selected != selectable{
					selection = .mode_songs(selectable)
				}
		}
	}
	private static func uAlbums_fresh() -> [UAlbum] {
		guard MusicAuthorization.currentStatus == .authorized
		else { return [] } // Don’t show any albums; show a placeholder.
		return Librarian.the_albums.map { $0.uAlbum }
	}
	
	func has_selected_album(_ uAlbum: UAlbum) -> Bool {
		switch selection {
			case .view, .mode_songs: return false
			case .mode_albums(let uAs_selected):
				return uAs_selected.contains(uAlbum)
		}
	}
	func has_selected_song(_ uSong: USong? = nil) -> Bool {
		switch selection {
			case .view, .mode_albums: return false
			case .mode_songs(let uSs_selected):
				guard let uSong else { return true }
				return uSs_selected.contains(uSong)
		}
	}
	func end_selecting_animated() {
		withAnimation {
			selection = .view
		}
	}
	
	func sort_albums(by albumOrder: AlbumOrder) {
		Librarian.sort_albums(uAlbums_to_sort(), by: albumOrder)
		refresh_artifacts()
	}
	func sort_songs(by songOrder: SongOrder) {
		Librarian.sort_songs(uSongs_to_sort(), by: songOrder)
		refresh_artifacts()
	}
	
	func can_sort_albums(by albumOrder: AlbumOrder) -> Bool {
		let to_sort = uAlbums_to_sort()
		guard to_sort.count >= 2 else { return false }
		
		switch selection {
			case .mode_songs, .view: break
			case .mode_albums(let uAs_selected):
				let rs_selected = uAlbums().indices(where: { uAlbum in
					uAs_selected.contains(uAlbum)
				})
				guard rs_selected.ranges.count <= 1 else { return false }
		}
		
		switch albumOrder {
			case .random, .reverse, .recently_added: return true
			case .recently_released: return to_sort.contains {
				nil != AppleCatalog.shared.albumInfo(uAlbum: $0)?._date_released
			}
		}
	}
	func can_sort_songs(by songOrder: SongOrder) -> Bool {
		guard uSongs_to_sort().count >= 2 else { return false }
		
		switch selection {
			case .mode_albums, .view: break
			case .mode_songs(let uSs_selected):
				let rs_selected = uSongs().indices(where: { uSong in
					uSs_selected.contains(uSong)
				})
				guard rs_selected.ranges.count <= 1 else { return false }
		}
		
		return true
	}
	
	private func uAlbums_to_sort() -> Set<UAlbum> {
		let _ = signal_artifacts // In case, for example, after first merge.
		switch selection {
			case .mode_songs: return []
			case .view: return Set(uAlbums())
			case .mode_albums(let uAs_selected): return uAs_selected
		}
	}
	private func uSongs_to_sort() -> Set<USong> {
		let _ = signal_artifacts // In case, for example, focus is an expanded album with 1 song, and merging adds a 2nd song.
		switch selection {
			case .mode_albums: return []
			case .view: return Set(uSongs())
			case .mode_songs(let uSs_selected): return uSs_selected
		}
	}
	
	func reorder_selection(up: Bool, to_limit: Bool) {
		switch selection {
			case .view: return
			case .mode_albums(let uAs_selected):
				if up {
					Librarian.promote_albums(uAs_selected, to_limit: to_limit)
				} else {
					Librarian.demote_albums(uAs_selected, to_limit: to_limit)
				}
			case .mode_songs(let uSs_selected):
				if up {
					Librarian.promote_songs(uSs_selected, to_limit: to_limit)
				} else {
					Librarian.demote_songs(uSs_selected, to_limit: to_limit)
				}
		}
		refresh_artifacts()
		if to_limit {
			switch selection {
				case .view: break
				case .mode_albums: selection = .mode_albums([])
				case .mode_songs: selection = .mode_songs([])
			}
		} else {
			NotificationCenter.default.post(name: .exhibit_selection, object: nil) // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
		}
	}
	
	fileprivate func uAlbums(with chosen: Set<UAlbum>? = nil) -> [UAlbum] {
		return artifacts.compactMap { switch $0 { // `compactMap` rather than `filter` because we’re returning a different type.
			case .row_song: return nil
			case .row_album(let uAlbum):
				guard let chosen else { return uAlbum }
				guard chosen.contains(uAlbum) else { return nil }
				return uAlbum
		}}
	}
	fileprivate func uSongs(with chosen: Set<USong>? = nil) -> [USong] {
		return artifacts.compactMap { switch $0 {
			case .row_album: return nil
			case .row_song(let uSong):
				guard let chosen else { return uSong }
				guard chosen.contains(uSong) else { return nil }
				return uSong
		}}
	}
	func uSongs_scope() -> [USong] { // In display order.
		let _ = signal_artifacts
		switch selection {
			case .mode_songs(let uSs_selected):
				return uSongs(with: uSs_selected)
			case .mode_albums(let uAs_selected):
				var result: [USong] = []
				uAlbums(with: uAs_selected).forEach { uAlbum in // Order matters.
					guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee else { return }
					result.append(contentsOf: lrAlbum.uSongs)
				}
				return result
			case .view:
				break
		}
		switch focus {
			case .spotlight:
				return []
			case .expanded:
				return uSongs()
			case .covers:
				var result: [USong] = []
				uAlbums().forEach { uAlbum in
					guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee else { return }
					result.append(contentsOf: lrAlbum.uSongs)
				}
				return result
		}
	}
	
	func has_album_range(from uA_anchor: UAlbum, forward: Bool) -> Bool {
		guard let i_anchor = uAlbums().firstIndex(where: { $0 == uA_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard uAlbums().indices.contains(i_neighbor) else { return false }
		switch selection {
			case .mode_songs, .view: return true
			case .mode_albums(let uAs_selected):
				let anchor_is_selected = uAs_selected.contains(uA_anchor)
				let neighbor_is_selected = uAs_selected.contains(uAlbums()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	func has_song_range(from uS_anchor: USong, forward: Bool) -> Bool {
		guard let i_anchor = uSongs().firstIndex(where: { $0 == uS_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard uSongs().indices.contains(i_neighbor) else { return false }
		switch selection {
			case .mode_albums: return false
			case .view: return true
			case .mode_songs(let uSs_selected):
				let anchor_is_selected = uSs_selected.contains(uS_anchor)
				let neighbor_is_selected = uSs_selected.contains(uSongs()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	
	func change_album_range(from uA_anchor: UAlbum, forward: Bool) {
		guard let i_anchor = uAlbums().firstIndex(where: { $0 == uA_anchor })
		else { return }
		let old_selected: Set<UAlbum> = {
			switch selection {
				case .mode_songs, .view: return []
				case .mode_albums(let uAs_selected): return uAs_selected
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
		switch selection {
			case .mode_songs:
				return
			case .view:
				withAnimation {
					selection = .mode_albums(new_selected)
				}
			case .mode_albums:
				selection = .mode_albums(new_selected)
		}
	}
	func change_song_range(from uS_anchor: USong, forward: Bool) {
		guard let i_anchor = uSongs().firstIndex(where: { $0 == uS_anchor })
		else { return }
		let old_selected: Set<USong> = {
			switch selection {
				case .mode_albums, .view: return []
				case .mode_songs(let uAs_selected): return uAs_selected
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
		switch selection {
			case .mode_albums:
				return
			case .view:
				withAnimation {
					selection = .mode_songs(new_selected)
				}
			case .mode_songs:
				selection = .mode_songs(new_selected)
		}
	}
}
extension Exhibit.Artifact: Hashable {}
extension Exhibit.Focus: Equatable {}
extension Exhibit.Selection: Equatable {}

// MARK: - View controller

final class ExhibitTVC: LRTableViewController {
	static func init_please() -> Self {
		return UIStoryboard(name: "ExhibitTVC", bundle: nil).instantiateInitialViewController() as! Self
	}
	private let exhibit = Exhibit()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Global.shared.showcase = exhibit // Ideally, whoever initializes this view should also initialize this.
		Global.shared.gallery = self
		
		view.backgroundColor = .clear
		tableView.separatorStyle = .none
		b_sort.preferredMenuElementOrder = .fixed
		b_scope.preferredMenuElementOrder = .fixed
		reflect_selection()
		
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_artifacts), name: .exhibit_artifacts, object: exhibit)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_focus), name: .exhibit_focus, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_selection), name: .exhibit_selection, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_activation), name: .song_activation, object: nil)
	}
	
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		exhibit.length_artwork = Self.length_square_fitting(
			size_frame: view.frame.size,
			safeAreaInsets: view.safeAreaInsets)
		refresh_contentInset(size_frame: view.frame.size)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		// The `size` parameter will later become `view.frame.size`, not `view.bounds.size`.
		exhibit.length_artwork = Self.length_square_fitting(
			size_frame: size,
			safeAreaInsets: view.safeAreaInsets)
		refresh_contentInset(size_frame: size)
	}
	
	private static func length_square_fitting(
		size_frame: CGSize,
		safeAreaInsets: UIEdgeInsets
	) -> CGFloat {
		return min(
			size_frame.width,
			size_frame.height - safeAreaInsets.bottom)
	}
	
	private func refresh_contentInset(size_frame: CGSize) {
		tableView.contentInset = {
			let gutter: CGFloat
			= size_frame.height / 2
			- exhibit.length_artwork / 2
			
			// `adjustedContentInset` is what matters because it determines the scrolling limits, but we can’t set it directly. We can set `contentInset`, but UIKit adds safe area insets to that.
			// As of iOS 18.3 RC, don’t use `contentInsetAdjustmentBehavior = .never`, because it breaks row sizing.
			
			var top: CGFloat = .zero
			top -= view.safeAreaInsets.top // Offsets how `UIScrollView` interprets `contentInset`. Applying it now should make it effectively zero.
			top += gutter
			top = top.rounded(.down) // As of iOS 18.3 developer beta 3, a non-integer value prevents you from rapidly expanding and collapsing albums.
			
			var bottom: CGFloat = .zero
			if WorkingOn.toolbar {
				bottom -= view.safeAreaInsets.bottom
				bottom += gutter
				bottom = bottom.rounded(.up)
			}
			
			return UIEdgeInsets(top: top, left: .zero, bottom: bottom, right: .zero)
		}()
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
							switch MusicAuthorization.currentStatus {
								case .authorized: return
								case .denied, .restricted: Task {
									guard
										let url_settings = URL(string: UIApplication.openSettingsURLString)
									else { return }
									let _ = await UIApplication.shared.open(url_settings)
								}
								case .notDetermined: Task {
									switch await MusicAuthorization.request() {
										case .denied, .restricted, .notDetermined: return
										case .authorized: LavaRock.integrate_Apple_Music()
										@unknown default: return
									}
								}
								@unknown default: return
							}
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if exhibit.artifacts.isEmpty {
				return UIHostingConfiguration {
					Placeholder()
						.accessibilityLabel(InterfaceText.No_music)
						.accessibilityRemoveTraits(.isImage)
				}.margins(.all, .zero)
			}
			return nil
		}()
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !initialized_rowIDs_current {
			initialized_rowIDs_current = true
			rowIDs_current = exhibit.rowIDs
		}
		return exhibit.artifacts.count
	}
	private var initialized_rowIDs_current = false
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch exhibit.artifacts[indexPath.row] {
			case .row_album(let uAlbum):
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
				cell.backgroundColor = .clear
				cell.selectionStyle = .none // Prevents highlighting.
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumRow(uAlbum: uAlbum, exhibit: exhibit)
				}.margins(.all, .zero)
				return cell
			case .row_song(let uSong):
				switch exhibit.focus {
					case .covers, .spotlight: return UITableViewCell() // Should never run
					case .expanded(let uAlbum):
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
						cell.backgroundColor = .clear
						cell.selectionStyle = .none
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(
								uSong: uSong,
								uAlbum: uAlbum,
								exhibit: exhibit)
						}.margins(.all, .zero)
						return cell
				}
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: Events
	
	func spotlight_current() {
		guard
			let uSong = LCD.shared.uSong_current,
			let album = Librarian.album_containing_uSong[uSong]?.referencee
		else { return }
		exhibit.focus = .spotlight(album.uAlbum)
	}
	
	@objc private func reflect_artifacts() {
		Task {
			b_sort.menu = menu_sort()
			b_scope.menu = menu_scope()
			await apply_rowIDs(exhibit.rowIDs, running_before_continuation: {
				self.scroll_to_attraction()
			})
		}
	}
	private func scroll_to_attraction() {
		let artifact_target: Exhibit.Artifact? = {
			switch exhibit.focus {
				case .covers: return nil
				case .expanded(let uA_expanded):
					return .row_album(uA_expanded)
				case .spotlight(let uA_spotlighted):
					return .row_album(uA_spotlighted)
			}
		}()
		guard
			let artifact_target,
			let i_artifact = self.exhibit.artifacts.firstIndex(of: artifact_target)
		else { return }
		tableView.scrollToRow(
			at: IndexPath(row: i_artifact, section: 0),
			at: .top,
			animated: true)
	}
	
	@objc private func reflect_focus() {
		switch exhibit.focus {
			case .spotlight:
				if !WorkingOn.toolbar {
					navigationController?.setToolbarHidden(true, animated: true)
				}
			case .covers, .expanded:
				if !WorkingOn.toolbar {
					navigationController?.setToolbarHidden(false, animated: true)
				}
		}
	}
	
	@objc private func reflect_selection() {
		switch exhibit.selection {
			case .view:
				setToolbarItems([b_sort, .flexibleSpace(), Remote.shared.b_remote, .flexibleSpace(), b_scope], animated: true)
				b_scope.image = image_scope
			case .mode_albums(let uAs_selected):
				setToolbarItems([b_sort, .flexibleSpace(), b_promote, .flexibleSpace(), b_demote, .flexibleSpace(), b_scope], animated: true)
				b_promote.isEnabled = !uAs_selected.isEmpty
				b_demote.isEnabled = b_promote.isEnabled
				b_scope.image = image_scope_highlighted
			case .mode_songs(let uSs_selected):
				setToolbarItems([b_sort, .flexibleSpace(), b_promote, .flexibleSpace(), b_demote, .flexibleSpace(), b_scope], animated: true)
				b_promote.isEnabled = !uSs_selected.isEmpty
				b_demote.isEnabled = b_promote.isEnabled
				b_scope.image = image_scope_highlighted
		}
		b_sort.menu = menu_sort() // In case it’s open.
		b_scope.menu = menu_scope()
	}
	
	@objc private func reflect_activation() {
		guard let activated = exhibit.activated else {
			dismiss(animated: true) // Should be the “Start Playing” action sheet.
			return
		}
		
		guard let view_anchor: UIView = { () -> UITableViewCell? in
			guard let row_activating = exhibit.artifacts.firstIndex(where: { switch $0 {
				case .row_album: return false
				case .row_song(let uSong): return uSong == activated
			}}) else { return nil }
			return tableView.cellForRow(at: IndexPath(row: row_activating, section: 0))
		}() else { return }
		
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		sheet.popoverPresentationController?.sourceView = view_anchor
		sheet.addAction(
			UIAlertAction(title: InterfaceText.Start_Playing, style: .default) { _ in
				self.exhibit.activated = nil
				Task {
					guard let album = Librarian.album_containing_uSong[activated]?.referencee else { return }
					await Tape.play_now(album.uSongs, starting_at: activated)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		sheet.addAction(
			UIAlertAction(title: InterfaceText.Cancel, style: .cancel) { _ in
				self.exhibit.activated = nil
			}
		)
		present(sheet, animated: true)
	}
	
	// MARK: Editing
	
	private lazy var a_done = UIAction(title: InterfaceText.Done, image: UIImage(systemName: SF.select_fill)) { [weak self] _ in self?.exhibit.end_selecting_animated() }
	
	private let b_sort = UIBarButtonItem(title: InterfaceText.Sort, image: UIImage(systemName: SF.sort)!.applying_hierarchical_tint())
	private lazy var b_scope = UIBarButtonItem(title: InterfaceText.More)
	private lazy var image_scope = image_scope_highlighted.applying_hierarchical_tint()
	private let image_scope_highlighted = UIImage(systemName: SF.ellipsis)!
	
	private lazy var b_promote = UIBarButtonItem(primaryAction: a_promote, menu: UIMenu(children: [a_float]))
	private lazy var b_demote = UIBarButtonItem(primaryAction: a_demote, menu: UIMenu(children: [a_sink]))
	
	private lazy var a_promote = UIAction(title: InterfaceText.Move_Up, image: UIImage(systemName: SF.move_up_circle)!.applying_hierarchical_tint()) { [weak self] _ in self?.promote() }
	private lazy var a_demote = UIAction(title: InterfaceText.Move_Down, image: UIImage(systemName: SF.move_down_circle)!.applying_hierarchical_tint()) { [weak self] _ in self?.demote() }
	private lazy var a_float = UIAction(title: InterfaceText.To_Top, image: UIImage(systemName: SF.to_top)) { [weak self] _ in self?.float() }
	private lazy var a_sink = UIAction(title: InterfaceText.To_Bottom, image: UIImage(systemName: SF.to_bottom)) { [weak self] _ in self?.sink() }
	
	// MARK: Scope
	
	private func menu_scope() -> UIMenu {
		var menu_children: [UIMenuElement] = []
		switch exhibit.selection {
			case .view: break
			case .mode_albums, .mode_songs:
				menu_children.append(a_done)
		}
		menu_children.append(
			UIMenu(
				options: .displayInline,
				children: [
					UIDeferredMenuElement.uncached { [weak self] use in
						guard let self else { return }
						let uSongs = exhibit.uSongs_scope()
						let action = UIAction(title: InterfaceText.Play, image: UIImage(systemName: SF.play_hollow)
						) { [weak self] _ in
							guard let self else { return }
							exhibit.end_selecting_animated()
							Task { await Tape.play_now(uSongs) }
						}
						if uSongs.isEmpty { action.attributes.formUnion(.disabled) }
						use([action])
					},
					UIDeferredMenuElement.uncached { [weak self] use in
						guard let self else { return }
						let uSongs = exhibit.uSongs_scope()
						let action = UIAction(title: InterfaceText.Jumble, image: UIImage(systemName: SF.die_random())
						) { [weak self] _ in
							guard let self else { return }
							exhibit.end_selecting_animated()
							Task {
								let jumbled = uSongs.in_any_other_order { $0 == $1 }
								await Tape.play_now(jumbled)
							}
						}
						if uSongs.count <= 1 { action.attributes.formUnion(.disabled) }
						use([action])
					},
					UIDeferredMenuElement.uncached { [weak self] use in
						guard let self else { return }
						let uSongs = exhibit.uSongs_scope()
						let action = UIAction(title: InterfaceText.Add_to_Queue, image: UIImage(systemName: SF.add_to_queue)
						) { [weak self] _ in
							guard let self else { return }
							exhibit.end_selecting_animated()
							Tape.play_later(uSongs)
						}
						if uSongs.isEmpty { action.attributes.formUnion(.disabled) }
						use([action])
					},
				])
		)
		return UIMenu(children: menu_children)
	}
	
	// MARK: Sort
	
	// Including sort commands depends on the type to sort: albums or songs.
	// Enabling sort commands depends on the items to sort:
	// • 2 or more
	// • Contiguous
	// • With useful data
	private func menu_sort() -> UIMenu? {
		return UIMenu(children: {
			switch exhibit.focus {
				case .spotlight: return []
				case .covers: return menu_sections_album_sort
				case .expanded: return menu_sections_song_sort
			}
		}())
	}
	
	private lazy var menu_sections_album_sort: [UIMenuElement] = {
		let sections: [[AlbumOrder]] = [[.recently_added, .recently_released], [.reverse, .random]]
		return sections.map { section in
			UIMenu(
				options: .displayInline,
				children: section.map { order in
					UIDeferredMenuElement.uncached { [weak self] use in
						// Runs each time the button presents the menu
						guard let self else { return }
						let action = UIAction(title: order.name, image: UIImage(systemName: order.sf_symbol)) { [weak self] _ in self?.sort_albums(by: order) }
						if !exhibit.can_sort_albums(by: order) {
							// You must do this inside `UIDeferredMenuElement.uncached`.
							action.attributes.formUnion(.disabled)
						}
						use([action])
					}
				})
		}
	}()
	private lazy var menu_sections_song_sort: [UIMenuElement] = {
		let sections: [[SongOrder]] = [[.track], [.reverse, .random]]
		return sections.map { section in
			UIMenu(
				options: .displayInline,
				children: section.map { order in
					UIDeferredMenuElement.uncached { [weak self] use in
						guard let self else { return }
						let action = UIAction(title: order.name, image: UIImage(systemName: order.sf_symbol)) { [weak self] _ in self?.sort_songs(by: order) }
						if !exhibit.can_sort_songs(by: order) {
							action.attributes.formUnion(.disabled)
						}
						use([action])
					}
				})
		}
	}()
	
	private func sort_albums(by albumOrder: AlbumOrder) {
		Task {
			exhibit.sort_albums(by: albumOrder)
			await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func sort_songs(by songOrder: SongOrder) {
		Task {
			exhibit.sort_songs(by: songOrder)
			await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	// MARK: Reorder
	
	private func promote() {
		Task {
			exhibit.reorder_selection(up: true, to_limit: false)
			await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func demote() {
		Task {
			exhibit.reorder_selection(up: false, to_limit: false)
			await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	private func float() {
		Task {
			exhibit.reorder_selection(up: true, to_limit: true)
			await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func sink() {
		Task {
			exhibit.reorder_selection(up: false, to_limit: true)
			await apply_rowIDs(exhibit.rowIDs)
		}
	}
}
