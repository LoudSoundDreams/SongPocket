//
//  TipJarViewModel.swift
//  LavaRock
//
//  Created by h on 2022-01-22.
//

import StoreKit
import Combine

@MainActor
protocol TipJarUI: AnyObject {
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
	
	weak var ui: TipJarUI? = nil
	
	@Published var status: Status = .notYetFirstLoaded {
		didSet {
			switch self.status {
			case .notYetFirstLoaded: // Should never run
				break
			case .loading:
				ui?.statusBecameLoading()
			case .reload:
				ui?.statusBecameReload()
			case .ready:
				ui?.statusBecameReady()
			case .confirming:
				ui?.statusBecameConfirming()
			case .thankYou:
				ui?.statusBecameThankYou()
				Task {
					try await Task.sleep(nanoseconds: 10_000_000_000)
					
					status = .ready
				}
			}
		}
	}
}
