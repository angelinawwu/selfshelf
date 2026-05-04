import Foundation

public struct OLSearchResult: Identifiable, Hashable, Sendable {
    public let id: String
    public let olid: String
    public let title: String
    public let authors: [String]
    public let coverId: Int?
    public let firstPublishYear: Int?
}

public struct OLWorkDetail: Sendable {
    public let olid: String
    public let description: String?
    public let subjects: [String]
}

public enum OLError: Error, LocalizedError {
    case badResponse
    case decoding
    public var errorDescription: String? {
        switch self {
        case .badResponse: return "Couldn't reach Open Library."
        case .decoding: return "Unexpected response from Open Library."
        }
    }
}

public final class OpenLibraryClient: Sendable {
    public static let shared = OpenLibraryClient()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(_ query: String, limit: Int = 20) async throws -> [OLSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var comps = URLComponents(string: "https://openlibrary.org/search.json")!
        comps.queryItems = [
            .init(name: "q", value: trimmed),
            .init(name: "limit", value: String(limit)),
            .init(name: "fields", value: "key,title,author_name,cover_i,first_publish_year"),
        ]
        let (data, resp) = try await session.data(from: comps.url!)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw OLError.badResponse }
        struct Response: Decodable {
            struct Doc: Decodable {
                let key: String
                let title: String
                let author_name: [String]?
                let cover_i: Int?
                let first_publish_year: Int?
            }
            let docs: [Doc]
        }
        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.docs.map { d in
                let olid = d.key.replacingOccurrences(of: "/works/", with: "")
                return OLSearchResult(
                    id: d.key,
                    olid: olid,
                    title: d.title,
                    authors: d.author_name ?? [],
                    coverId: d.cover_i,
                    firstPublishYear: d.first_publish_year
                )
            }
        } catch {
            throw OLError.decoding
        }
    }

    public func workDetail(olid: String) async throws -> OLWorkDetail {
        let url = URL(string: "https://openlibrary.org/works/\(olid).json")!
        let (data, resp) = try await session.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw OLError.badResponse }
        struct Response: Decodable {
            struct Desc: Decodable { let value: String? }
            let description: DescriptionField?
            let subjects: [String]?
        }
        enum DescriptionField: Decodable {
            case string(String)
            case object(String?)
            public init(from decoder: Decoder) throws {
                let c = try decoder.singleValueContainer()
                if let s = try? c.decode(String.self) { self = .string(s); return }
                if let o = try? c.decode([String: String].self) { self = .object(o["value"]); return }
                self = .object(nil)
            }
            var text: String? {
                switch self {
                case .string(let s): return s
                case .object(let s): return s
                }
            }
        }
        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return OLWorkDetail(olid: olid, description: decoded.description?.text, subjects: decoded.subjects ?? [])
        } catch {
            throw OLError.decoding
        }
    }

    public static func coverURL(id: Int, size: CoverSize = .medium) -> URL {
        URL(string: "https://covers.openlibrary.org/b/id/\(id)-\(size.rawValue).jpg")!
    }
}

public enum CoverSize: String, Sendable {
    case small = "S"
    case medium = "M"
    case large = "L"
}
