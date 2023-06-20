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
					.foregroundStyle(.secondary)
			case .reload:
				Button {
					PurchaseManager.shared.requestTipProduct()
				} label: {
					Text(LRString.reload)
						.foregroundStyle(theme.accentColor.color) // Don’t use the `.accentColor` modifier, because SwiftUI applies “Increase Contrast” twice.
				}
			case .ready:
				Button {
					PurchaseManager.shared.buyTip()
				} label: {
					HStack {
						Text("tip")
							.foregroundStyle(theme.accentColor.color) // Don’t use the `.accentColor` modifier, because SwiftUI applies “Increase Contrast” twice.
						Spacer()
						Text("0¢")
							.foregroundStyle(.secondary)
					}
				}
			case .confirming:
				Text(LRString.confirmingEllipsis)
					.foregroundStyle(.secondary)
			case .thankYou:
				TipThankYouView()
		}
	}
}
