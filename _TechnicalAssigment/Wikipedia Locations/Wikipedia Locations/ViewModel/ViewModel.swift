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
	
	init(locationState: LocationsState = LocationsState.idle) {
		self.locationState = locationState
	}
	
	@MainActor
	func fetchLocationsTapped() async {
		locationState = .fetching
		do {
			// Since this is the only place we use the client, we don't declare it as a property.
			let locations = try await Dependency(\.locationsClient).wrappedValue.fetch()
			self.locationState = .success(locations: locations)
		} catch {
			self.locationState = .idle
		}
	}
	
	func locationTapped(_ location: Location) {
		UIApplication.shared.open(location.wikipediaLink)
	}
}

