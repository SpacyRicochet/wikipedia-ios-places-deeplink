import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
struct LocationsClient {
	var fetch: () async throws -> [Location]
}

extension DependencyValues {
	var locationsClient: LocationsClient {
		get { self[LocationsClient.self] }
		set { self[LocationsClient.self] = newValue }
	}
}

extension LocationsClient: TestDependencyKey {
	static let testValue = Self()
	
	static var previewValue: LocationsClient {
		.init(fetch: {
			// We sleep on purpose to give the user the chance to admire the progress view.
			try await Task.sleep(nanoseconds: 1_000_000_000)
			return Location.mockList
		})
	}
}

extension LocationsClient: DependencyKey {
	static var liveValue: LocationsClient {
		.init(
			fetch: {
				let fetchStart = Date()
				let (data, _) = try await URLSession.shared.data(from: URL(string: "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json")!)
				let fetchEnd = Date()
				if fetchEnd.timeIntervalSince(fetchStart) < 0.3 {
					// We sleep on purpose to give the user the chance to admire the progress view.
					try await Task.sleep(nanoseconds: 1_000_000_000)
				}
				let apiResult = try JSONDecoder().decode(APILocations.self, from: data)
				return apiResult.locations
			}
		)
	}
}

fileprivate struct APILocations: Decodable {
	var locations: [Location]
}
