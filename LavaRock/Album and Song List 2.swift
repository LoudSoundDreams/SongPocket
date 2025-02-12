// 2025-02-12

import SwiftUI

struct ExhibitList: View {
	var body: some View { GeometryReader { geoProxy in
		let _ = Print()
		let _ = Print(geoProxy.size)
		let _ = Print(geoProxy.safeAreaInsets)
		ScrollViewReader { scrollProxy in ScrollView {
			
			LazyVStack(alignment: .leading, spacing: .zero) {
				strut(centering_square_in: geoProxy.size)
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
				strut(centering_square_in: geoProxy.size)
			}
			
		}}
	}}
	private func strut(centering_square_in size: CGSize) -> some View {
		Rectangle()
			.frame(width: 42, height: {
				let length_square: CGFloat = min(size.width, size.height)
				
				var result: CGFloat = size.height
				result /= 2
				result -= length_square / 2
				return result
			}())
			.foregroundStyle(Color.clear)
	}
}
