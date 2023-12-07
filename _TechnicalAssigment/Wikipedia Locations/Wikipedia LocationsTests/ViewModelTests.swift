import XCTest
@testable import Wikipedia_Locations
import Dependencies
import ConcurrencyExtras

final class ViewModelTests: XCTestCase {
	func test_fetchLocationsTapped_performsAsExpected() async throws {
		// ConcurrencyExtras provides this serial executor which forces Tasks to be executed serially and predictably.
		await withMainSerialExecutor {
			// We use Dependencies to stub out the locations client with a predictable version.
			await withDependencies {
				$0.locationsClient = .init(fetch: {
					await Task.yield()
					return [
						.init(name: "Hey!", latitude: 42.0, longitude: -3.0),
						.init(name: "Listen", latitude: 0.0, longitude: 4.0),
						.init(latitude: 24.0, longitude: 1.0),
					]
				})
			} operation: {
				let sut = ViewModel(locationState: .idle)
				let task = Task { await sut.fetchLocationsTapped() }
				await Task.yield()
				XCTAssertEqual(sut.locationState, .fetching)
				
				await task.value
				guard case .success(let locations) = sut.locationState else {
					XCTFail("Invalid view model state. Expected: .success(<locations>); Actual: \(sut.locationState)")
					return
				}
				XCTAssertEqual(
					locations,
					[
						.init(name: "Hey!", latitude: 42.0, longitude: -3.0),
						.init(name: "Listen", latitude: 0.0, longitude: 4.0),
						.init(latitude: 24.0, longitude: 1.0),
					]
				)
			}
		}
	}
}
