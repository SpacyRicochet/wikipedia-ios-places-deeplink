import Foundation
import Dependencies
import class SwiftUI.UIApplication

enum LocationsState: Equatable {
	case idle
	case fetching
	case success(locations: [Location])
}

@Observable
class ViewModel {
	var locationState: LocationsState
	var alertMessage: String?
	var isShowingMap: Bool
		
	init(locationState: LocationsState = LocationsState.idle, alertMessage: String? = nil, isShowingMap: Bool = false) {
		self.locationState = locationState
		self.alertMessage = alertMessage
		self.isShowingMap = isShowingMap
	}
	
	@MainActor
	func fetchLocationsTapped() async {
		locationState = .fetching
		await performFetch()
	}
	
	func refreshInitialized() async {
		await performFetch()
	}
	
	private func performFetch() async {
		// Since this only deals with the actual fetch and its aftermath, make sure you have set the correct `locationState` before calling this function.
		do {
			// Since this is the only place we use the client, we don't declare it as a property.
			let locations = try await Dependency(\.locationsClient).wrappedValue.fetch()
			self.locationState = .success(locations: locations)
		} catch {
			self.locationState = .idle
			self.alertMessage = error.localizedDescription
		}
	}
	
	func locationTapped(_ location: Location) {
		UIApplication.shared.open(location.wikipediaLink)
	}
	
	func alertDismissTapped() {
		alertMessage = nil
	}
	
	func showMap() {
		isShowingMap = true
	}
	
	func reset() {
		locationState = .idle
		isShowingMap = false
		alertMessage = nil
	}
}

