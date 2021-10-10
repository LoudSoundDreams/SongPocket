//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import StoreKit

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	private func configure() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.reload
		if #available(iOS 15, *) { // See comments in `AllowAccessCell`.
			configuration.textProperties.color = UIColor.tintColor
		} else {
			configuration.textProperties.color = self.tintColor
		}
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) { // See comments in `AllowAccessCell`.
		} else {
			configure()
		}
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	private func configure() {
		guard
			let tipProduct = PurchaseManager.shared.tipProduct,
			let tipPriceFormatter = PurchaseManager.shared.tipPriceFormatter
		else {
			contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var configuration = UIListContentConfiguration.valueCell()
		configuration.text = tipProduct.localizedTitle
		if #available(iOS 15, *) { // See comments in `AllowAccessCell`.
			configuration.textProperties.color = UIColor.tintColor
		} else {
			configuration.textProperties.color = AccentColor.savedPreference().uiColor
		}
		configuration.secondaryText = tipPriceFormatter.string(from: tipProduct.price)
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) { // See comments in `AllowAccessCell`.
		} else {
			configure()
		}
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipThankYouCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		isUserInteractionEnabled = false
		
		configure()
	}
	
	private func configure() {
		var configuration = UIListContentConfiguration.cell()
		let heartEmoji = AccentColor.savedPreference().heartEmoji
		let thankYouMessage = heartEmoji + LocalizedString.tipThankYouMessageWithPaddingSpaces + heartEmoji
		configuration.text = thankYouMessage
		configuration.textProperties.color = .secondaryLabel
		configuration.textProperties.alignment = .center
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}
