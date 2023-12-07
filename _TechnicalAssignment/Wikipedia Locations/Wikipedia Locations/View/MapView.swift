import SwiftUI
import MapKit

struct MapView: View {
	@Environment(\.dismiss) var dismiss

	@State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: -33.447487, longitude: -70.673676), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
	
	let buttonHandler: (Location) -> Void
	
	var body: some View {
		ZStack {
			Map(coordinateRegion: $mapRegion)
				.ignoresSafeArea()
			Image(systemName: "smallcircle.circle")
				.font(.largeTitle)
				.fontWeight(.heavy)
				.symbolRenderingMode(.hierarchical)
				.foregroundColor(.accent)
				.accessibilityLabel("Current location; latitude \(mapRegion.center.latitude) and longitude \(mapRegion.center.longitude)")
			VStack {
				Spacer()
				Button { 
					buttonHandler(.init(latitude: mapRegion.center.latitude, longitude: mapRegion.center.longitude))
				} label: {
					Text("Open Wikipedia")
						.font(.headline)
					Image(systemName: "arrow.up.forward.app")
				}
				.foregroundColor(.white)
				.padding()
				.background(.accent.opacity(0.9))
				.clipShape(.capsule)
				.accessibilityHint("Double-tap to open Wikipedia for articles in the area")
			}
		}
		.navigationTitle("Pick your location")
		.accessibilityAction(.escape, {
			self.dismiss()
		})
		.toolbar(content: {
			Button {
				dismiss()
			} label: {
				Image(systemName: "xmark.circle.fill")
					.font(.title)
					.padding()
			}
			.accessibilityLabel("Dismiss")
		})
	}
}

#Preview {
	NavigationView {
		MapView(buttonHandler: {_ in })
	}
}
