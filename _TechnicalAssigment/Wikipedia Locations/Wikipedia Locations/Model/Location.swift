import Foundation

struct Location: Identifiable, Hashable, Decodable {
	struct Coordinates: Hashable, Decodable {
		var latitude: Double
		var longitude: Double
	}
	
	var name: String?
	private var lat: Double
	private var long: Double
	
	init(name: String? = nil, latitude: Double, longitude: Double) {
		self.name = name
		self.lat = latitude
		self.long = longitude
	}
	
	var id: Int {
		hashValue
	}
	
	var coordinates: Coordinates {
		.init(latitude: lat, longitude: long)
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


