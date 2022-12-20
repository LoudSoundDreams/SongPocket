//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import StoreKit

final class LightingCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectionStyle = .none
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class AvatarCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectionStyle = .none
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class LightingChooser: UISegmentedControl {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		Lighting.allCases.forEach { lighting in
			insertSegment(
				action: UIAction(
					image: {
						let image = lighting.uiImage
						image.accessibilityLabel = lighting.accessibilityLabel
						return image
					}()
				) { _ in
					Task { await MainActor.run {
						Theme.shared.lighting = lighting
					}}
				},
				at: numberOfSegments,
				animated: false)
		}
		selectedSegmentIndex = Lighting.allCases.firstIndex { lightingCase in
			Lighting.preference == lightingCase
		}!
	}
}

final class AvatarChooser: UISegmentedControl {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		Avatar.allCases.forEach { avatarCase in
			insertSegment(
				action: UIAction(
					image: {
						let image = UIImage(systemName: avatarCase.playingSFSymbolName)
						image?.accessibilityLabel = avatarCase.accessibilityLabel
						return image
					}()
				) { _ in
					Avatar.preference = avatarCase
				},
				at: numberOfSegments,
				animated: false)
		}
		selectedSegmentIndex = Avatar.allCases.firstIndex { avatarCase in
			Avatar.preference == avatarCase
		}!
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AccentColorCell: UITableViewCell {
	var representee: AccentColor? = nil {
		didSet {
			freshen_contentConfiguration()
			freshen_selectedBackgroundView()
			freshen_accessoryType()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		Task {
			accessibilityTraits.formUnion(.button)
		}
	}
	
	private func freshen_contentConfiguration() {
		let new_contentConfiguration: UIContentConfiguration
		defer {
			contentConfiguration = new_contentConfiguration
		}
		
		guard let representee = representee else {
			// Should never run
			new_contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var content = UIListContentConfiguration.cell()
		// Text
		content.text = representee.displayName
		// Text color
		content.textProperties.color = representee.uiColor
			.resolvedForIncreaseContrast()
		new_contentConfiguration = content
	}
	
	private func freshen_selectedBackgroundView() {
		let new_selectedBackgroundView: UIView?
		defer {
			selectedBackgroundView = new_selectedBackgroundView
		}
		
		// Similar to in `CellTintingWhenSelected`, except we need to do this manually to reflect “Increase Contrast”.
		let colorView = UIView()
		colorView.backgroundColor = representee?.uiColor
			.resolvedForIncreaseContrast()
			.withAlphaComponentOneHalf()
		new_selectedBackgroundView = colorView
	}
	
	private func freshen_accessoryType() {
		let new_accessoryType: AccessoryType
		defer {
			accessoryType = new_accessoryType
		}
		
		// Don’t compare `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
		if representee == AccentColor.savedPreference() {
			new_accessoryType = .checkmark
		} else {
			new_accessoryType = .none
		}
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		freshen_contentConfiguration()
		freshen_selectedBackgroundView()
		freshen_accessoryType()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading // We shouldn’t have to do this, but as of build 482, without this, if you close Options then open it again, something sets the left inset to 0.
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipLoadingCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		disableWithAccessibilityTrait()
		
		var content = UIListContentConfiguration.cell()
		content.text = LRString.loadingEllipsis
		content.textProperties.color = .secondaryLabel
		contentConfiguration = content
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		configureAsButton()
	}
}
extension TipReloadCell: CellTintingWhenSelected {}
extension TipReloadCell: CellConfigurableAsButton {
	static let buttonText = LRString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		accessibilityTraits.formUnion(.button)
		
		var content = UIListContentConfiguration.valueCell()
		content.text = PurchaseManager.shared.tipTitle
		content.textProperties.color = .tintColor
		content.secondaryText = PurchaseManager.shared.tipPrice
		contentConfiguration = content
	}
}
extension TipReadyCell: CellTintingWhenSelected {}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipConfirmingCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		disableWithAccessibilityTrait()
		
		var content = UIListContentConfiguration.cell()
		content.text = LRString.confirmingEllipsis
		content.textProperties.color = .secondaryLabel
		contentConfiguration = content
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipThankYouCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		isUserInteractionEnabled = false
		
		configure()
	}
	
	private func configure() {
		var content = UIListContentConfiguration.cell()
		content.text = AccentColor.savedPreference().thankYouMessage()
		content.textProperties.color = .secondaryLabel
		content.textProperties.alignment = .center
		contentConfiguration = content
	}
	
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}
