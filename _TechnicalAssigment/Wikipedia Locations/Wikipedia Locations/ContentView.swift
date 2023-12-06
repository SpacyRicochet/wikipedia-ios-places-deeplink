import SwiftUI

struct ContentView: View {
	@State var viewModel: ViewModel = .init()
	
	var body: some View {
		NavigationStack {
			Group {
				switch viewModel.locationState {
					case .idle:
						Button(action: {
							self.viewModel.fetchLocationsTapped()
						}, label: {
							VStack(spacing: 8) {
								Image(systemName: "mappin.and.ellipse")
									.symbolRenderingMode(.palette)
									.foregroundStyle(Color.primary, Color.accentColor)
									.imageScale(.large)
									.font(.title)
								Text("Fetch locations")
							}
						})
					case .fetching:
						VStack {
							ProgressView()
								.controlSize(.extraLarge)
							Text("Please wait…")
						}
					case .success(let locations):
						List(locations, id: \.id, rowContent: { location in
							Button(action: { [location] in
								self.viewModel.locationTapped(location)
							}, label: {
								LocationView(location: location)
							})
							.foregroundColor(.primary)
						})
						.listStyle(.plain)
						.refreshable {
							self.viewModel.fetchLocationsTapped()
						}
				}
			}
			.navigationTitle("Wikipedia Locations")
		}
	}
}

#Preview("Idle") {
	ContentView(viewModel: .init(locationState: .idle))
}

#Preview("Fetching") {
	ContentView(viewModel: .init(locationState: .fetching))
}

#Preview("Success") {
	ContentView(viewModel: .init(locationState: .success(locations: Location.mockList)))
}

struct Location: Identifiable, Hashable, Decodable {
	struct Coordinates: Hashable, Decodable {
		var latitude: Double
		var longitude: Double
	}
	
	var name: String?
	private var lat: Double
	private var lon: Double
	
	init(name: String? = nil, latitude: Double, longitude: Double) {
		self.name = name
		self.lat = latitude
		self.lon = longitude
	}
	
	var id: Int {
		hashValue
	}
	
	var coordinates: Coordinates {
		.init(latitude: lat, longitude: lon)
	}
}

extension Location {
	var wikipediaLink: URL {
		URL(string: "wikipedia://places?WMFLocationLat=\(coordinates.latitude)&WMFLocationLon=\(coordinates.longitude)")!
	}
}

extension Location {
	static var mockList: [Self] { 
		[
			.init(name: "Test", latitude: 6.0, longitude: -4.0),
			.init(name: "Test 2", latitude: 20.0, longitude: 4.0),
			.init(latitude: 40.0, longitude: -3)
		]
	}
}

enum LocationsState {
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
	
	func fetchLocationsTapped() {
		// TODO: Remove debug code
		locationState = .success(locations: Location.mockList)
	}
	
	func locationTapped(_ location: Location) {
		UIApplication.shared.open(location.wikipediaLink)
	}
}

struct LocationView: View {
	let location: Location
	
	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				if let name = location.name {
					Text(name)
						.font(.body)
						.fontWeight(.bold)
				}
				Text("(\(location.coordinates.latitude), \(location.coordinates.longitude))")
					.font(.callout)
			}
			Spacer()
			Image(systemName: "arrow.up.forward.app")
				.symbolRenderingMode(.palette)
				.foregroundStyle(Color.primary, Color.accentColor)
				.imageScale(.large)
		}
	}
}
