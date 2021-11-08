//
//  Collections and Albums Levels - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-31.
//

import UIKit

final class TheseContainersCell: UITableViewCell {
	enum Mode {
		case enabled
		case disabledWithDisclosureIndicator
		case disabledWithNoDisclosureIndicator // Don't use `UITableViewCell.isEditing`; it's always `false` because that's what we return in `LibraryTVC.tableView(_:canEditRowAt:)`.
		// You must also reload the row yourself when entering and exiting editing mode.
	}
	
	@IBOutlet private var allLabel: UILabel!
	
	final func configure(mode: Mode) {
		switch mode {
		case .enabled:
			allLabel.textColor = .label
			enableWithAccessibilityTrait()
			accessoryType = .disclosureIndicator
		case .disabledWithDisclosureIndicator:
			allLabel.textColor = .placeholderText
			disableWithAccessibilityTrait()
			accessoryType = .disclosureIndicator
		case .disabledWithNoDisclosureIndicator:
			allLabel.textColor = .placeholderText
			disableWithAccessibilityTrait()
			accessoryType = .none
		}
	}
}
