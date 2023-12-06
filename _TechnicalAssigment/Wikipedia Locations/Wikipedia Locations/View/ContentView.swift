import SwiftUI

struct ContentView: View {
	@State var viewModel: ViewModel = .init()
	
	var body: some View {
		NavigationStack {
			Group {
				switch viewModel.locationState {
					case .idle:
						Button(action: {
							Task(priority: .userInitiated) {
								await self.viewModel.fetchLocationsTapped()
							}
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
							await self.viewModel.fetchLocationsTapped()
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
