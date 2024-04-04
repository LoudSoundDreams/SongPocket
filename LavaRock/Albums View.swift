// 2024-04-04

import SwiftUI

struct AxisView: View {
	@State private var numbers: [Int] = Array(1...3)
	@State private var currentNumber: Int? = 2
	
	var body: some View {
		ScrollViewReader { proxy in
			ScrollView(.horizontal) {
				LazyHStack {
					ForEach(numbers, id: \.self) { number in
						ZStack {
							Rectangle().foregroundStyle(Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)))
							Circle().foregroundStyle(Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)))
						}
						.aspectRatio(1, contentMode: .fit)
						.containerRelativeFrame(.horizontal)
						.id(number)
					}
				}.scrollTargetLayout()
			}
			.scrollTargetBehavior(.viewAligned(limitBehavior: .never))
			.scrollPosition(id: $currentNumber)
			.toolbar { ToolbarItemGroup(placement: .bottomBar) {
				Button {
					withAnimation {
						if currentNumber != nil && currentNumber! > 1 {
							currentNumber! -= 1
						}
					}
				} label: { Image(systemName: "arrow.backward") }
					.disabled(currentNumber == 1)
				Spacer()
				Text({ guard let currentNumber else { return "" }; return String(currentNumber) }())
				Spacer()
				Button {
					withAnimation {
						if currentNumber != nil && currentNumber! < numbers.count {
							currentNumber! += 1
						}
					}
				} label: { Image(systemName: "arrow.forward") }
					.disabled(currentNumber == numbers.count)
				Spacer()
				Button {
					withAnimation {
						numbers.append(numbers.count + 1)
					}
				} label: { Image(systemName: "plus") }
			} }
		}
	}
}
