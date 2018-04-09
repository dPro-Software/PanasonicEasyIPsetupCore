public typealias MacAddress = [UInt8]
public typealias IPv4Address = [UInt8]

func getDict(bytes: [UInt8]) -> [UInt16: CountableRange<Int>] {
	var index: [UInt16: CountableRange<Int>] = [:]
	var cursor = 58
	while cursor < bytes.endIndex - 4 {
		let length = Int(bytes[cursor+2]) << 8 + Int(bytes[cursor+3])
		let id = UInt16(bytes[cursor]) << 8 + UInt16(bytes[cursor+1])
		let range = (cursor+4) ..< (cursor+4+length)
		index[id] = range
		cursor += length + 4
	}
	return index
}

enum Field {
	case ipAddress, netmask, gateway, dns, port, name, model
	
	var index: UInt16 {
		switch self {
		case .ipAddress: return 32
		case .netmask:   return 33
		case .gateway:   return 34
		case .dns:       return 35
		case .port:      return 37
		case .name:      return 167
		case .model:     return 168
		}
	}
	
	var alternateIndex: UInt16 {
		switch self {
		case .ipAddress: return 160
		case .netmask: return 161
		case .gateway: return 162
		case .dns: return 163
		case .port: return 68
		default:
			return 1
		}
	}
}

enum ParseError: Error {
	case fieldNotFound(Field)
	case mismatch(Field)
	case stringDecoding
	case datagramTooSmall
}

public struct CameraConfiguration: Equatable {
	public let macAddress: MacAddress
	public let ipV4address: IPv4Address
	public let netmask: IPv4Address
	public let gateway: IPv4Address
	public let primaryDNS: IPv4Address
	public let secondaryDNS: IPv4Address
	public let port: UInt16
	public let model: String
	public let name: String
	
	public init(datagram: [UInt8]) throws {
		guard datagram.count > 58 else {
			throw ParseError.datagramTooSmall
		}
		macAddress = Array(datagram[6..<12])
		let index = getDict(bytes: datagram)
		
		func getSlice(for field: Field) throws -> ArraySlice<UInt8> {
			guard let range = index[field.index] else {
				throw ParseError.fieldNotFound(field)
			}
			return datagram[range]
		}
		
		func doubleCheck(field: Field) throws -> ArraySlice<UInt8> {
			let slice = try getSlice(for: field)
			guard let alternateRange = index[field.alternateIndex] else {
				throw ParseError.fieldNotFound(field)
			}
			guard slice == datagram[alternateRange] else {
				throw ParseError.mismatch(field)
			}
			return slice
		}
		
		ipV4address = Array(try doubleCheck(field: .ipAddress))
		netmask = Array(try doubleCheck(field: .netmask))
		gateway = Array(try doubleCheck(field: .gateway))
		
		let dnsAddressesRange = try getSlice(for: .dns)
		primaryDNS   = Array(dnsAddressesRange.dropLast( 4))
		secondaryDNS = Array(dnsAddressesRange.dropFirst(4))
		
		let portBytes = try doubleCheck(field: .port)
		port = UInt16(portBytes.first!) << 8 + UInt16(portBytes.last!)
		
		model = String(cString: try getSlice(for: .model).withUnsafeBufferPointer{$0.baseAddress!})
		name  = String(cString: try getSlice(for: .name ).withUnsafeBufferPointer{$0.baseAddress!})
	}
	
	public init(macAddress: MacAddress, ipV4address: IPv4Address, netmask: IPv4Address, gateway: IPv4Address, primaryDNS: IPv4Address, secondaryDNS: IPv4Address, port: UInt16, model: String, name: String) {
		self.macAddress = macAddress
		self.ipV4address = ipV4address
		self.netmask = netmask
		self.gateway = gateway
		self.primaryDNS = primaryDNS
		self.secondaryDNS = secondaryDNS
		self.port = port
		self.model = model
		self.name = name
	}
	
	public static func discoveryRequest(from macAddress: MacAddress, ipV4address: IPv4Address) -> [UInt8] {
		return [ 0x00, 0x01, 0x00, 0x2A, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5], ipV4address[0], ipV4address[1], ipV4address[2], ipV4address[3], 0x00, 0x00, 0x20, 0x11, 0x1E, 0x11, 0x23, 0x1F, 0x1E, 0x19, 0x13, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xF0, 0x00, 0x26, 0x00, 0x20, 0x00, 0x21, 0x00, 0x22, 0x00, 0x23, 0x00, 0x25, 0x00, 0x28, 0x00, 0x40, 0x00, 0x41, 0x00, 0x42, 0x00, 0x44, 0x00, 0xA5, 0x00, 0xA6, 0x00, 0xA7, 0x00, 0xA8, 0x00, 0xAD, 0x00, 0xB3, 0x00, 0xB4, 0x00, 0xB7, 0x00, 0xB8, 0xFF, 0xFF, 0x12, 0x21]
	}
	
	public func reconfigurationRequest(sourceMacAddress: MacAddress, sourceIpAddress: IPv4Address) -> [UInt8] {
		return [0x00, 0x01, 0x00, 0xaf, 0x00, 0x02,
				macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5],
				sourceMacAddress[0], sourceMacAddress[1], sourceMacAddress[2], sourceMacAddress[3], sourceMacAddress[4], sourceMacAddress[5],
				sourceIpAddress[0], sourceIpAddress[1], sourceIpAddress[2], sourceIpAddress[3],
				00, 0x01, 0x20, 0x11, 0x1e, 0x11, 0x23, 0x1f, 0x1e, 0x19, 0x13, 0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x00, 0x01, 0x00, 0x01, 0x00,
				
				0, UInt8(Field.ipAddress.index), 0, 4,
				ipV4address[0], ipV4address[1], ipV4address[2], ipV4address[3],
				
				0, UInt8(Field.netmask.index), 0, 4,
				netmask[0], netmask[1], netmask[2], netmask[3],
				
				0, UInt8(Field.gateway.index), 0, 4,
				gateway[0], gateway[1], gateway[2], gateway[3],
				
				0, UInt8(Field.dns.index), 0, 8,
				primaryDNS[0],   primaryDNS[1],   primaryDNS[2],   primaryDNS[3],
				secondaryDNS[0], secondaryDNS[1], secondaryDNS[2], secondaryDNS[3],
				
				0, UInt8(Field.port.index), 0, 2,
				UInt8(port >> 8), UInt8(port & 0xFF),
				
				0, 64, 0, 16,
				254, 128, 0, 0, 0, 0, 0, 0, 170, 19, 116, 255, 254, 118, 168, 107,
				
				0, 65, 0, 16,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				
				0, 66, 0, 32,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				
				0, UInt8(Field.port.alternateIndex), 0, 2,
				UInt8(port >> 8), UInt8(port & 0xFF),
				
				0, UInt8(Field.ipAddress.alternateIndex), 0, 4,
				ipV4address[0], ipV4address[1], ipV4address[2], ipV4address[3],
				
				0, UInt8(Field.netmask.alternateIndex), 0, 4,
				netmask[0], netmask[1], netmask[2], netmask[3],
				
				0, UInt8(Field.gateway.alternateIndex), 0, 4,
				gateway[0], gateway[1], gateway[2], gateway[3],
				
				0, UInt8(Field.dns.alternateIndex), 0, 8,
				primaryDNS[0],   primaryDNS[1],   primaryDNS[2],   primaryDNS[3],
				secondaryDNS[0], secondaryDNS[1], secondaryDNS[2], secondaryDNS[3],
				
				0, 166, 0, 1,
				146,
				
				0xff, 0xff, 0x1d, 0x53
		]
	}
}
