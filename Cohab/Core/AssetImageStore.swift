import Foundation
import UIKit
import Supabase

/// Stores user-uploaded asset photos and per-contribution receipts.
///
/// Signed-in users: private Supabase Storage bucket `asset-images`.
/// Asset photo: `{householdId}/{assetId}/photo.jpg` — replacing the photo is
/// an upsert to the same path, and RLS policies gate access to household
/// members. Contribution receipt: `{householdId}/{assetId}/receipts/
/// {contributionId}.jpg`. Signed-out (memory mode) users: local Documents
/// folder. The remote asset photo is always mirrored to the local disk cache
/// so it displays instantly the next time the asset is opened.
enum AssetImageStore {
    enum Kind: String {
        case photo
    }

    private static let bucket = "asset-images"

    private static func path(householdId: UUID, assetId: UUID, kind: Kind) -> String {
        "\(householdId.uuidString)/\(assetId.uuidString)/\(kind.rawValue).jpg"
    }

    private static func receiptPath(householdId: UUID, assetId: UUID, contributionId: UUID) -> String {
        "\(householdId.uuidString)/\(assetId.uuidString)/receipts/\(contributionId.uuidString).jpg"
    }

    private static func localURL(assetId: UUID, kind: Kind) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AssetImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(assetId.uuidString)_\(kind.rawValue).jpg")
    }

    private static func localReceiptURL(contributionId: UUID) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AssetImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(contributionId.uuidString)_receipt.jpg")
    }

    /// In-memory cache of receipt lookups so the contribution history list
    /// doesn't re-download (or re-attempt a missing download) on every open.
    /// A cached nil means "known to have no receipt". Receipts are uploaded
    /// once, at contribution creation, so a stale nil only costs the partner
    /// a receipt badge until the next app launch.
    private static var receiptMemoryCache: [UUID: UIImage?] = [:]

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

    // MARK: - Asset photo

    /// Save (or replace) the asset photo. Returns immediately-usable UIImage.
    /// Always mirrors to the local disk cache so the photo renders instantly.
    @discardableResult
    static func save(_ image: UIImage, kind: Kind, householdId: UUID, assetId: UUID,
                     signedIn: Bool) async throws -> UIImage {
        guard let data = compress(image) else { throw CocoaError(.coderInvalidValue) }
        try? data.write(to: localURL(assetId: assetId, kind: kind), options: .atomic)
        if signedIn {
            _ = try await supabase.storage
                .from(bucket)
                .upload(path: path(householdId: householdId, assetId: assetId, kind: kind),
                        file: data,
                        options: FileOptions(contentType: "image/jpeg", upsert: true))
        }
        return image
    }

    /// Synchronously returns the locally cached asset photo, if present.
    static func loadCached(assetId: UUID) -> UIImage? {
        guard let data = try? Data(contentsOf: localURL(assetId: assetId, kind: .photo)) else { return nil }
        return UIImage(data: data)
    }

    static func load(kind: Kind, householdId: UUID, assetId: UUID,
                     signedIn: Bool) async -> UIImage? {
        if signedIn {
            do {
                let data = try await supabase.storage
                    .from(bucket)
                    .download(path: path(householdId: householdId, assetId: assetId, kind: kind))
                // Refresh the disk cache only when the remote copy changed
                let url = localURL(assetId: assetId, kind: kind)
                if (try? Data(contentsOf: url)) != data {
                    try? data.write(to: url, options: .atomic)
                }
                return UIImage(data: data)
            } catch {
                return nil
            }
        }
        return loadCached(assetId: assetId)
    }

    static func delete(kind: Kind, householdId: UUID, assetId: UUID,
                       signedIn: Bool) async {
        try? FileManager.default.removeItem(at: localURL(assetId: assetId, kind: kind))
        if signedIn {
            _ = try? await supabase.storage
                .from(bucket)
                .remove(paths: [path(householdId: householdId, assetId: assetId, kind: kind)])
        }
    }

    // MARK: - Contribution receipts

    /// Save (or replace) the receipt attached to a contribution.
    @discardableResult
    static func saveReceipt(_ image: UIImage, contributionId: UUID, householdId: UUID,
                            assetId: UUID, signedIn: Bool) async throws -> UIImage {
        guard let data = compress(image) else { throw CocoaError(.coderInvalidValue) }
        try? data.write(to: localReceiptURL(contributionId: contributionId), options: .atomic)
        if signedIn {
            _ = try await supabase.storage
                .from(bucket)
                .upload(path: receiptPath(householdId: householdId, assetId: assetId,
                                          contributionId: contributionId),
                        file: data,
                        options: FileOptions(contentType: "image/jpeg", upsert: true))
        }
        receiptMemoryCache[contributionId] = image
        return image
    }

    /// Load a contribution's receipt, or nil if it has none. Local disk cache
    /// first (instant, and the only copy when signed out), then remote.
    static func loadReceipt(contributionId: UUID, householdId: UUID, assetId: UUID,
                            signedIn: Bool) async -> UIImage? {
        if let cached = receiptMemoryCache[contributionId] { return cached }
        let result: UIImage?
        if let data = try? Data(contentsOf: localReceiptURL(contributionId: contributionId)),
           let image = UIImage(data: data) {
            result = image
        } else if signedIn,
                  let data = try? await supabase.storage
                    .from(bucket)
                    .download(path: receiptPath(householdId: householdId, assetId: assetId,
                                                contributionId: contributionId)) {
            try? data.write(to: localReceiptURL(contributionId: contributionId), options: .atomic)
            result = UIImage(data: data)
        } else {
            result = nil
        }
        receiptMemoryCache[contributionId] = result
        return result
    }

    /// Best-effort removal of a contribution's receipt (local + remote).
    static func deleteReceipt(contributionId: UUID, householdId: UUID, assetId: UUID,
                              signedIn: Bool) async {
        receiptMemoryCache.removeValue(forKey: contributionId)
        try? FileManager.default.removeItem(at: localReceiptURL(contributionId: contributionId))
        if signedIn {
            _ = try? await supabase.storage
                .from(bucket)
                .remove(paths: [receiptPath(householdId: householdId, assetId: assetId,
                                            contributionId: contributionId)])
        }
    }
}
