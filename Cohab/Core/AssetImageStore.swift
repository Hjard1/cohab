import Foundation
import UIKit
import Supabase

/// Stores user-uploaded asset photos and receipts.
///
/// Signed-in users: private Supabase Storage bucket `asset-images` with a
/// deterministic path `{householdId}/{assetId}/{kind}.jpg` — replacing an
/// image is an upsert to the same path, and RLS policies gate access to
/// household members. Signed-out (memory mode) users: local Documents folder.
enum AssetImageStore {
    enum Kind: String {
        case photo
        case receipt
    }

    private static let bucket = "asset-images"

    private static func path(householdId: UUID, assetId: UUID, kind: Kind) -> String {
        "\(householdId.uuidString)/\(assetId.uuidString)/\(kind.rawValue).jpg"
    }

    private static func localURL(assetId: UUID, kind: Kind) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AssetImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(assetId.uuidString)_\(kind.rawValue).jpg")
    }

    /// Downscale and JPEG-encode for storage.
    static func compress(_ image: UIImage, maxDimension: CGFloat = 1600) -> Data? {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }

    /// Save (or replace) an image. Returns immediately-usable UIImage.
    @discardableResult
    static func save(_ image: UIImage, kind: Kind, householdId: UUID, assetId: UUID,
                     signedIn: Bool) async throws -> UIImage {
        guard let data = compress(image) else { throw CocoaError(.coderInvalidValue) }
        if signedIn {
            _ = try await supabase.storage
                .from(bucket)
                .upload(path: path(householdId: householdId, assetId: assetId, kind: kind),
                        file: data,
                        options: FileOptions(contentType: "image/jpeg", upsert: true))
        } else {
            try data.write(to: localURL(assetId: assetId, kind: kind), options: .atomic)
        }
        return image
    }

    static func load(kind: Kind, householdId: UUID, assetId: UUID,
                     signedIn: Bool) async -> UIImage? {
        if signedIn {
            do {
                let data = try await supabase.storage
                    .from(bucket)
                    .download(path: path(householdId: householdId, assetId: assetId, kind: kind))
                return UIImage(data: data)
            } catch {
                return nil
            }
        }
        let url = localURL(assetId: assetId, kind: kind)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(kind: Kind, householdId: UUID, assetId: UUID,
                       signedIn: Bool) async {
        if signedIn {
            _ = try? await supabase.storage
                .from(bucket)
                .remove(paths: [path(householdId: householdId, assetId: assetId, kind: kind)])
        } else {
            try? FileManager.default.removeItem(at: localURL(assetId: assetId, kind: kind))
        }
    }
}
