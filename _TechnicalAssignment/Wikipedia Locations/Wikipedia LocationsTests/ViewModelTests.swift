import XCTest
@testable import Wikipedia_Locations
import Dependencies
import ConcurrencyExtras

final class ViewModelTests: XCTestCase {
	func test_fetchLocationsTapped_withSuccess_performsAsExpected() async throws {
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
	
	func test_fetchLocationsTapped_withError_performsAsExpected() async throws {
		enum SomeError: Error {
			case any
		}
		// ConcurrencyExtras provides this serial executor which forces Tasks to be executed serially and predictably.
		await withMainSerialExecutor {
			// We use Dependencies to stub out the locations client with a predictable version.
			await withDependencies {
				$0.locationsClient = .init(fetch: {
					await Task.yield()
					throw SomeError.any
				})
			} operation: {
				let sut = ViewModel(locationState: .idle)
				let task = Task { await sut.fetchLocationsTapped() }
				await Task.yield()
				XCTAssertEqual(sut.locationState, .fetching)
				
				await task.value
				guard case .idle = sut.locationState else {
					XCTFail("Invalid view model state. Expected: .idle; Actual: \(sut.locationState)")
					return
				}
				XCTAssertNotNil(sut.alertMessage)
			}
		}
	}
	
	func test_refreshInitialized_withSuccess_performsAsExpected() async throws {
		let locationsBeforeFetch: [Location] = [
			.init(name: "Listen", latitude: 0.0, longitude: 4.0),
			.init(latitude: 24.0, longitude: 1.0),
		]
		let locationsAfterFetch: [Location] = [
			.init(name: "Hey!", latitude: 42.0, longitude: -3.0),
			.init(name: "Listen", latitude: 0.0, longitude: 4.0),
			.init(latitude: 24.0, longitude: 1.0),
		]
		// ConcurrencyExtras provides this serial executor which forces Tasks to be executed serially and predictably.
		await withMainSerialExecutor {

			// We use Dependencies to stub out the locations client with a predictable version.
			await withDependencies {
				$0.locationsClient = .init(fetch: {
					await Task.yield()
					return locationsAfterFetch
				})
			} operation: {
				let sut = ViewModel(locationState: .success(locations: locationsBeforeFetch))
				let task = Task { await sut.refreshInitialized() }
				await Task.yield()
				guard case .success(let sutLocationsBeforeFetch) = sut.locationState else {
					XCTFail("Invalid view model state. Expected: .success(<locations>); Actual: \(sut.locationState)")
					return
				}
				XCTAssertEqual(
					sutLocationsBeforeFetch,
					locationsBeforeFetch
				)

				await task.value
				guard case .success(let sutLocationsAfterFetch) = sut.locationState else {
					XCTFail("Invalid view model state. Expected: .success(<locations>); Actual: \(sut.locationState)")
					return
				}
				XCTAssertEqual(
					sutLocationsAfterFetch,
					locationsAfterFetch
				)
			}
		}
	}
	
	func test_refreshInitialized_withError_performsAsExpected() async throws {
		let locationsBeforeFetch: [Location] = [
			.init(name: "Listen", latitude: 0.0, longitude: 4.0),
			.init(latitude: 24.0, longitude: 1.0),
		]
		// ConcurrencyExtras provides this serial executor which forces Tasks to be executed serially and predictably.
		await withMainSerialExecutor {
			// We use Dependencies to stub out the locations client with a predictable version.
			await withDependencies {
				$0.locationsClient = .init(fetch: {
					await Task.yield()
					throw SomeError.any
				})
			} operation: {
				let sut = ViewModel(locationState: .success(locations: locationsBeforeFetch))
				let task = Task { await sut.refreshInitialized() }
				await Task.yield()
				guard case .success(let sutLocationsBeforeFetch) = sut.locationState else {
					XCTFail("Invalid view model state. Expected: .success(<locations>); Actual: \(sut.locationState)")
					return
				}
				XCTAssertEqual(
					sutLocationsBeforeFetch,
					locationsBeforeFetch
				)

				await task.value
				guard case .idle = sut.locationState else {
					XCTFail("Invalid view model state. Expected: .idle; Actual: \(sut.locationState)")
					return
				}
				XCTAssertNotNil(sut.alertMessage)
			}
		}
	}
	
	func test_alertDismissTapped_setsAlertMessageToNil() throws {
		let sut = ViewModel(locationState: .idle, alertMessage: "Hey! Listen")
		sut.alertDismissTapped()
		XCTAssertNil(sut.alertMessage)
	}
	
	func test_resetApp_resetsViewModelToInitialState() {
		let sut = ViewModel()
		sut.locationState = .fetching
		sut.alertMessage = "Error"
		sut.isShowingMap = true
		
		sut.reset()
		XCTAssertEqual(sut.locationState, .idle)
		XCTAssertNil(sut.alertMessage)
		XCTAssertFalse(sut.isShowingMap)
	}
}

private enum SomeError: Error {
	case any
}
