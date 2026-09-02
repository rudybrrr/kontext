import Foundation

enum VectorCodec {
    static func encode(_ values: [Double]) -> Data {
        var data = Data(capacity: values.count * MemoryLayout<UInt32>.size)
        for value in values {
            var bits = Float(value).bitPattern.littleEndian
            withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
        }
        return data
    }

    static func decode(_ data: Data) -> [Double]? {
        let width = MemoryLayout<UInt32>.size
        guard data.count.isMultiple(of: width) else { return nil }
        return data.withUnsafeBytes { bytes in
            stride(from: 0, to: data.count, by: width).map { offset in
                let bits = UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
                return Double(Float(bitPattern: bits))
            }
        }
    }
}

enum VectorMath {
    static func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double? {
        guard !lhs.isEmpty, lhs.count == rhs.count else { return nil }
        let dot = zip(lhs, rhs).reduce(0) { $0 + $1.0 * $1.1 }
        let lhsMagnitude = sqrt(lhs.reduce(0) { $0 + $1 * $1 })
        let rhsMagnitude = sqrt(rhs.reduce(0) { $0 + $1 * $1 })
        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return nil }
        return dot / (lhsMagnitude * rhsMagnitude)
    }
}
