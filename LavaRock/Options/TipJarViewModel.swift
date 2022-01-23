//
//  TipJarViewModel.swift
//  LavaRock
//
//  Created by h on 2022-01-22.
//

import StoreKit
import Combine

protocol TipJarDelegate: AnyObject {
	func statusBecameLoading()
	func statusBecameReload()
	func statusBecameReady()
	func statusBecameConfirming()
	func statusBecameThankYou()
}

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
			DispatchQueue.main.async {
				switch self.status {
				case .notYetFirstLoaded:
					// Should never run
					break
				case .loading:
					self.delegate?.statusBecameLoading()
				case .reload:
					self.delegate?.statusBecameReload()
				case .ready:
					self.delegate?.statusBecameReady()
				case .confirming:
					self.delegate?.statusBecameConfirming()
				case .thankYou:
					self.delegate?.statusBecameThankYou()
					Task {
						try await Task.sleep(nanoseconds: 10_000_000_000)
						
						self.status = .ready
					}
				}
			}
		}
	}
}
