//
//  TipJarViewModel.swift
//  LavaRock
//
//  Created by h on 2022-01-22.
//

import StoreKit
import Combine

@MainActor
protocol TipJarDelegate: AnyObject {
	func statusBecameLoading()
	func statusBecameReload()
	func statusBecameReady()
	func statusBecameConfirming()
	func statusBecameThankYou()
}

@MainActor
final class TipJarViewModel: ObservableObject {
	private init() {}
	static let shared = TipJarViewModel()
	
	enum Status: Equatable {
		case notYetFirstLoaded
		case loading
		case reload
		case ready
		case confirming
		case thankYou
	}
	
	weak var delegate: TipJarDelegate? = nil
	
	@Published var status: Status = .notYetFirstLoaded {
		didSet {
			switch self.status {
			case .notYetFirstLoaded:
				// Should never run
				break
			case .loading:
				delegate?.statusBecameLoading()
			case .reload:
				delegate?.statusBecameReload()
			case .ready:
				delegate?.statusBecameReady()
			case .confirming:
				delegate?.statusBecameConfirming()
			case .thankYou:
				delegate?.statusBecameThankYou()
				Task {
					try await Task.sleep(nanoseconds: 10_000_000_000)
					
					status = .ready
				}
			}
		}
	}
}
