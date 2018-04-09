import XCTest
@testable import PanasonicEasyIPsetupCore

final class PanasonicEasyIPsetupCoreTests: XCTestCase {
    func testBuildReconfigurationRequest() {
		// create a camera configuration
		let config = CameraConfiguration(
			macAddress: [0xa8, 0x13, 0x74, 0x76, 0xa8, 0x6b],
			ipV4address: [10, 1, 0, 215],
			netmask: [255, 255, 255, 0],
			gateway: [10, 1, 0, 1],
			primaryDNS: [0, 0, 0, 0],
			secondaryDNS: [0, 0, 0, 0],
			port: 80,
			model: "daddes",
			name: "dinges"
		)
		
		// Build a datagram to request a reconfig of a camera
		let datagram = config.reconfigurationRequest(
			sourceMacAddress: [0x00, 0x1c, 0x42, 0x4b, 0xbb, 0xf8],
			sourceIpAddress: [0x0a, 0x01, 0x00, 0x04]
		)
		
		// Real packet peeped message
		let expectation: [UInt8] = [0, 1, 0, 175, 0, 2, 168, 19, 116, 118, 168, 107, 0, 28, 66, 75, 187, 248, 10, 1, 0, 4, 0, 1, 32, 17, 30, 17, 35, 31, 30, 25, 19, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 1, 0, 1, 0, 0, 32, 0, 4, 10, 1, 0, 215, 0, 33, 0, 4, 255, 255, 255, 0, 0, 34, 0, 4, 10, 1, 0, 1, 0, 35, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 0, 2, 0, 80, 0, 64, 0, 16, 254, 128, 0, 0, 0, 0, 0, 0, 170, 19, 116, 255, 254, 118, 168, 107, 0, 65, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 0, 2, 0, 80, 0, 160, 0, 4, 10, 1, 0, 215, 0, 161, 0, 4, 255, 255, 255, 0, 0, 162, 0, 4, 10, 1, 0, 1, 0, 163, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 166, 0, 1, 146, 255, 255, 29, 83]
		
		// Compare the generated datagram with the packet peeped one
        XCTAssertEqual(datagram, expectation)
    }

	func testBuildConfigurationRequest() {
		let datagram = CameraConfiguration.discoveryRequest(
			from: [0x00, 0x1C, 0x42, 0x4B, 0xBB, 0xF8],
			ipV4address: [0xA9, 0xFE, 0xE0, 0x0E]
		)
		
		// Real packet peeped message
		let expectation: [UInt8] = [0, 1, 0, 42, 0, 13, 0, 0, 0, 0, 0, 0, 0, 28, 66, 75, 187, 248, 169, 254, 224, 14, 0, 0, 32, 17, 30, 17, 35, 31, 30, 25, 19, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 240, 0, 38, 0, 32, 0, 33, 0, 34, 0, 35, 0, 37, 0, 40, 0, 64, 0, 65, 0, 66, 0, 68, 0, 165, 0, 166, 0, 167, 0, 168, 0, 173, 0, 179, 0, 180, 0, 183, 0, 184, 255, 255, 18, 33]
		
		// Compare the generated datagram with the packet peeped one
		XCTAssertEqual(datagram, expectation)
	}
	
	func testParseConfiguration() {
		let expectation = CameraConfiguration(macAddress: [0xa8, 0x13, 0x74, 0x76, 0xa8, 0x6b], ipV4address: [0x0a, 0x01, 0x00, 0xd8], netmask: [255, 255, 255, 0], gateway: [10, 1, 0, 1], primaryDNS: [10, 1, 0, 250], secondaryDNS: [10, 1, 0, 251], port: 80, model: "CAM:HE130K", name: "AW-HE130")

		if let configuration = try? CameraConfiguration(datagram: [0, 1, 1, 117, 0, 1, 168, 19, 116, 118, 168, 107, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 17, 30, 17, 35, 31, 30, 25, 19, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 1, 0, 1, 0, 0, 32, 0, 4, 10, 1, 0, 216, 0, 33, 0, 4, 255, 255, 255, 0, 0, 34, 0, 4, 10, 1, 0, 1, 0, 35, 0, 8, 10, 1, 0, 250, 10, 1, 0, 251, 0, 37, 0, 2, 0, 80, 0, 64, 0, 16, 254, 128, 0, 0, 0, 0, 0, 0, 170, 19, 116, 255, 254, 118, 168, 107, 0, 65, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 0, 2, 0, 80, 0, 69, 0, 2, 0, 64, 0, 160, 0, 4, 10, 1, 0, 216, 0, 161, 0, 4, 255, 255, 255, 0, 0, 162, 0, 4, 10, 1, 0, 1, 0, 163, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 164, 0, 4, 127, 255, 255, 255, 0, 166, 0, 1, 146, 0, 167, 0, 16, 65, 87, 45, 72, 69, 49, 51, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 168, 0, 16, 67, 65, 77, 58, 72, 69, 49, 51, 48, 75, 0, 0, 0, 0, 0, 0, 0, 169, 0, 16, 48, 50, 46, 48, 48, 48, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 170, 0, 16, 48, 46, 48, 48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 177, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 178, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 180, 0, 2, 0, 0, 0, 181, 0, 1, 0, 0, 182, 0, 1, 146, 255, 255, 47, 26]) {
			XCTAssertEqual(configuration, expectation)
		} else {
			XCTFail("Unable to parse datagram")
		}
	}

    static var allTests = [
        ("Reconfiguration request datagram generation", testBuildReconfigurationRequest),
		("Request for configuration announcements datagram generation", testBuildConfigurationRequest),
		("Parse a configuration", testParseConfiguration)
    ]
}
