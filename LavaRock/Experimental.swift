// 2024-04-04

import SwiftUI

struct ButtonPanel: View {
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	var body: some View {
		HStack(spacing: .zero) {
			ZStack {
				Color.black.opacity(.one_eighth)
				Image(systemName: "chevron.forward")
					.rotationEffect({
						if exhibit.is_expanded(uAlbum)
						{ return Angle.degrees(90) }
						return Angle.zero
					}())
					.animation(.linear_quick(), value: exhibit.is_expanded(uAlbum))
					.foregroundStyle(exhibit.has_selected_song() ? .secondary : .primary)
			}
			.onTapGesture {
				switch exhibit.focus {
					case .spotlight: return
					case .covers:
						exhibit.focus = .expanded(uAlbum)
					case .expanded(let uA_expanded):
						if uA_expanded == uAlbum {
							exhibit.focus = .covers
						} else { exhibit.focus = .expanded(uAlbum) }
				}
			}
			.reacting(is_touching_detail)
			.touching($is_touching_detail)
			
			ZStack {
				Color.black.opacity(.one_eighth)
				Image(systemName: "checkmark")
					.foregroundStyle(exhibit.has_selected_song() ? .secondary : .primary)
			}
			.onTapGesture {
				Print(Date(), "select")
			}
			.reacting(is_touching_select)
			.touching($is_touching_select)
		}.disabled(!exhibit.is_viewing)
	}
	@State private var is_touching_detail = false
	@State private var is_touching_select = false
}

extension View {
	func reacting(_ active: Bool) -> some View {
		return self
			.overlay {
				Color.black.opacity(active ? .one_fourth : .zero)
			}
			.animation(active ? nil : .linear_quick(), value: active)
	}
	
	func touching(_ variable: Binding<Bool>) -> some View {
		onLongPressGesture(minimumDuration: .zero) {
		} onPressingChanged: {
			variable.wrappedValue = $0
		}
	}
}

struct TheBar: View {
	var body: some View {
		Button("hop", systemImage: "hare") {
		}
	}
}
