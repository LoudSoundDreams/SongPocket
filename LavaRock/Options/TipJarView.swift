//
//  TipJarView.swift
//  LavaRock
//
//  Created by h on 2022-07-19.
//

import SwiftUI

struct TipJarView: View {
	@ObservedObject private var theme: Theme = .shared
	@ObservedObject private var tipJarViewModel: TipJarViewModel = .shared
	
	init() {
		if tipJarViewModel.status == .notYetFirstLoaded {
			PurchaseManager.shared.requestTipProduct()
		}
	}
	
	var body: some View {
		switch tipJarViewModel.status {
		case .notYetFirstLoaded, .loading:
			Text(LRString.loadingEllipsis)
				.foregroundColor(.secondary)
		case .reload:
			Button {
				PurchaseManager.shared.requestTipProduct()
			} label: {
				Text(LRString.reload)
					.foregroundColor(theme.accentColor.color) // Don’t use the `.accentColor` modifier, because SwiftUI applies “Increase Contrast” twice.
			}
		case .ready:
			Button {
				PurchaseManager.shared.buyTip()
			} label: {
				HStack {
					Text("tip")
						.foregroundColor(theme.accentColor.color) // Don’t use the `.accentColor` modifier, because SwiftUI applies “Increase Contrast” twice.
					Spacer()
					Text("0¢")
						.foregroundColor(.secondary)
				}
			}
		case .confirming:
			Text(LRString.confirmingEllipsis)
				.foregroundColor(.secondary)
		case .thankYou:
			HStack {
				Spacer()
				Text(theme.accentColor.thankYouMessage())
					.foregroundColor(.secondary)
				Spacer()
			}
		}
	}
}
