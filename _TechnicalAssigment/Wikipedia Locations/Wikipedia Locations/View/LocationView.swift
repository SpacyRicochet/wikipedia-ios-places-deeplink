import SwiftUI

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
