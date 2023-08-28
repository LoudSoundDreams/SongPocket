//
//  About - Views.swift
//  LavaRock
//
//  Created by h on 2023-08-20.
//

import SwiftUI

struct TipLoadingRow: View {
	var body: some View {
		LabeledContent(LRString.leaveTip, value: LRString.loadingEllipsis)
			.foregroundStyle(.secondary) // Seems to not affect `LabeledContent`’s `value:` argument
	}
}
struct TipReloadRow: View {
	var body: some View {
		LabeledContent {
			Text(LRString.reload)
		} label: {
			Text(LRString.leaveTip)
				.foregroundStyle(Color.accentColor)
		}
		.accessibilityAddTraits(.isButton)
	}
}
struct TipReadyRow: View {
	var body: some View {
		LabeledContent {
			Text(PurchaseManager.shared.tipPrice ?? "")
		} label: {
			Text(LRString.leaveTip)
				.foregroundStyle(Color.accentColor)
		}
		.accessibilityAddTraits(.isButton)
	}
}
struct TipConfirmingRow: View {
	var body: some View {
		LabeledContent(LRString.leaveTip, value: LRString.confirmingEllipsis)
			.foregroundStyle(.secondary)
	}
}
struct TipThankYouRow: View {
	@Environment(\.colorScheme) private var lighting
	var body: some View {
		LabeledContent(
			LRString.leaveTip,
			value: { () -> String in
				var result = "\(LRString.thankYouExclamationMark) "
				switch lighting {
					case .light:
						result.append("🖤")
					case .dark:
						result.append("🤍")
					@unknown default:
						result.append("🩶")
				}
				return result
			}()
		)
		.foregroundStyle(.secondary)
	}
}

struct ContactRow: View {
	var body: some View {
		LabeledContent {
			Text(verbatim: "linus@songpocket.app")
		} label: {
			Text(LRString.sayHi)
				.foregroundStyle(Color.accentColor)
		}
	}
}
