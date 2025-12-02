import Foundation

// Safely decodes optional URLs without failing the entire payload.
extension KeyedDecodingContainer {
    func decodeLossyURL(forKey key: Key) throws -> URL? {
        guard contains(key) else { return nil }
        if let raw = try decodeIfPresent(URL.self, forKey: key) {
            return raw
        }
        if let string = try decodeIfPresent(String.self, forKey: key) {
            return URL(string: string)
        }
        return nil
    }
}
