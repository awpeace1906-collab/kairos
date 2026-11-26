import Foundation
import PDFKit
import UIKit
import Vision

/// On-device text extraction for Local Protocols imports. No network: Vision
/// (VNRecognizeTextRequest, .accurate) for photos and scanned PDF pages, PDFKit
/// for PDF pages that carry a text layer. Every line keeps its bounding box and
/// source (file, page) so the review screen can zoom to it.
enum ImportPipeline {
    enum Path: String, Codable { case textLayer = "text_layer", ocr }

    struct Line: Codable, Equatable {
        var text: String
        /// Normalized 0–1, origin top-left, in the page/photo image.
        var box: CGRect
        var sourceIndex: Int
        var page: Int?
        var path: Path
    }

    struct PageResult {
        let sourceIndex: Int
        let page: Int?
        let path: Path
        let image: UIImage      // what the review screen zooms into
        let lines: [Line]
    }

    enum ImportError: LocalizedError {
        case locked, unreadable, noText
        var errorDescription: String? {
            switch self {
            case .locked: return "This PDF is password-protected and the password didn't open it."
            case .unreadable: return "This file couldn't be read."
            case .noText: return "No text was found."
            }
        }
    }

    // MARK: - Photos

    static func recognize(image: UIImage, sourceIndex: Int, page: Int? = nil) async throws -> PageResult {
        guard let cg = image.normalizedUp().cgImage else { throw ImportError.unreadable }
        let lines = try await recognizeText(cg).map { Line(text: $0.text, box: $0.box, sourceIndex: sourceIndex, page: page, path: .ocr) }
        return PageResult(sourceIndex: sourceIndex, page: page, path: .ocr, image: image, lines: orderByColumns(lines))
    }

    static func recognizeText(_ cg: CGImage) async throws -> [(text: String, box: CGRect)] {
        try await Task.detached(priority: .userInitiated) {
            let req = VNRecognizeTextRequest()
            req.recognitionLevel = .accurate
            try VNImageRequestHandler(cgImage: cg, options: [:]).perform([req]) // synchronous
            return (req.results ?? []).compactMap { o -> (text: String, box: CGRect)? in
                guard let s = o.topCandidates(1).first?.string else { return nil }
                // Vision boxes are normalized with origin bottom-left.
                let b = o.boundingBox
                return (s, CGRect(x: b.minX, y: 1 - b.maxY, width: b.width, height: b.height))
            }
        }.value
    }

    // MARK: - PDFs

    /// Opens a PDF, unlocking it with `password` if needed.
    static func openPDF(_ url: URL, password: String? = nil) throws -> PDFDocument {
        guard let doc = PDFDocument(url: url) else { throw ImportError.unreadable }
        if doc.isLocked {
            guard let password, doc.unlock(withPassword: password) else { throw ImportError.locked }
        }
        return doc
    }

    /// A page with a usable text layer uses it (line boxes from text
    /// selections); otherwise the page is rendered at ≥ 300 dpi and run through
    /// the same Vision recognition as photos.
    static func extract(page: PDFPage, index: Int, sourceIndex: Int) async throws -> PageResult {
        let image = render(page, dpi: 300)
        let text = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty, let sel = page.selection(for: page.bounds(for: .mediaBox)) {
            let bounds = page.bounds(for: .mediaBox)
            let lines: [Line] = sel.selectionsByLine().compactMap { l in
                let s = (l.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !s.isEmpty else { return nil }
                let r = l.bounds(for: page)
                let box = CGRect(x: (r.minX - bounds.minX) / bounds.width, y: 1 - (r.maxY - bounds.minY) / bounds.height,
                                 width: r.width / bounds.width, height: r.height / bounds.height)
                return Line(text: s, box: box, sourceIndex: sourceIndex, page: index, path: .textLayer)
            }
            if !lines.isEmpty {
                return PageResult(sourceIndex: sourceIndex, page: index, path: .textLayer, image: image, lines: orderByColumns(lines))
            }
        }
        return try await recognize(image: image, sourceIndex: sourceIndex, page: index)
    }

    static func render(_ page: PDFPage, dpi: CGFloat) -> UIImage {
        let bounds = page.bounds(for: .mediaBox)
        let scale = dpi / 72
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            ctx.cgContext.translateBy(x: -bounds.minX, y: -bounds.minY)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }

    static func thumbnail(_ page: PDFPage) -> UIImage { page.thumbnail(of: CGSize(width: 160, height: 220), for: .mediaBox) }

    // MARK: - Reading order

    /// Column by column (x clusters: a new column starts where the gap between
    /// line left edges exceeds 15% of the width), then top to bottom.
    static func orderByColumns(_ lines: [Line], gap: CGFloat = 0.15) -> [Line] {
        guard !lines.isEmpty else { return [] }
        let xs = lines.map(\.box.minX).sorted()
        var starts: [CGFloat] = [xs[0]]
        for (a, b) in zip(xs, xs.dropFirst()) where b - a > gap { starts.append(b) }
        func column(_ l: Line) -> Int { starts.lastIndex { l.box.minX >= $0 - 0.0001 } ?? 0 }
        return lines.sorted { a, b in
            let ca = column(a), cb = column(b)
            return ca != cb ? ca < cb : a.box.minY < b.box.minY
        }
    }
}

extension UIImage {
    /// Redraws so pixel data matches `.up` orientation (camera photos are often rotated).
    func normalizedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat(); format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }

    /// The region of a normalized (top-left) box, padded, for the review zoom.
    func crop(normalized box: CGRect, pad: CGFloat = 0.02) -> UIImage? {
        let img = normalizedUp()
        guard let cg = img.cgImage else { return nil }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        let r = CGRect(x: (box.minX - pad) * w, y: (box.minY - pad) * h, width: (box.width + 2 * pad) * w, height: (box.height + 2 * pad) * h)
            .intersection(CGRect(x: 0, y: 0, width: w, height: h))
        guard !r.isEmpty, let c = cg.cropping(to: r.integral) else { return nil }
        return UIImage(cgImage: c)
    }
}
