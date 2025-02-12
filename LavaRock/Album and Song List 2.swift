// 2025-02-12

import SwiftUI

struct ExhibitList: View {
	var body: some View { ScrollViewReader { scrollProxy in
		ZStack {
			
			ScrollView {
				LazyVStack(alignment: .leading, spacing: .zero) {
					Rectangle()
						.foregroundStyle(Color.yellow.opacity(.one_half))
						.containerRelativeFrame(.vertical) { length, _axis in
							var result = length
							result /= 2
							return result
						}
					
					ForEach(Librarian.the_albums, id: \.uAlbum) { lrAlbum in
						ZStack {
							Rectangle()
								.foregroundStyle(Color.debug_random())
								.frame(maxWidth: .infinity)
								.aspectRatio(1, contentMode: .fit)
							Text(String(lrAlbum.uAlbum))
								.tag(lrAlbum.uAlbum)
						}
					}
				}
			}
			
			Button("scroll") {
				let uA_random = Librarian.the_albums.randomElement()!.uAlbum
				withAnimation(.linear_quick()) {
					scrollProxy.scrollTo(uA_random, anchor: .center)
				}
			}
			
		}
	}}
}
