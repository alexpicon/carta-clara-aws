//
//  PacketPDF.swift
//  Carta Clara
//
//  Renders the Response Preparation Packet to a printable, paginated PDF.
//
//  The packet is meant to leave the phone and travel to a legal-aid
//  appointment (DEMO_SCRIPT 2:00). A clean US-Letter PDF AirPrints, saves to
//  Files, or attaches to Mail — all via the standard share sheet.
//
//  Two pieces:
//   • PacketPrintDocument — a print-optimized SwiftUI layout (black on white,
//     fixed type sizes — print is not the place for Dynamic Type).
//   • PacketPDF.render(packet:) — rasterizes that layout with ImageRenderer
//     and slices it across US-Letter pages with UIGraphicsPDFRenderer.
//

import SwiftUI
import UIKit

// MARK: - Print layout

/// The packet laid out for paper. Fixed widths and type sizes so the printed
/// page is consistent regardless of the user's on-screen text-size setting.
struct PacketPrintDocument: View {
    let packet: PreparationPacket

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Masthead
            VStack(alignment: .leading, spacing: 4) {
                Text(UIText.appName)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                Text(packet.titleEs)
                    .font(.system(size: 22, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Rectangle().fill(Color.black).frame(height: 2)

            textSection(UIText.packetWhatItSays, body: packet.whatThisSaysEs)

            if let deadline = packet.yourDeadline, let label = deadline.labelEs, !label.isEmpty {
                textSection(UIText.packetDeadline, body: label, emphasized: true)
            }

            listSection(UIText.packetDocuments, items: packet.documentsToGatherEs, marker: .checkbox)

            // Extension Request template removed from the packet — providing
            // it implied a recommendation to request more time, which is too
            // close to legal strategy advice (TENETS §3).

            textSection(UIText.packetPhoneScript, body: packet.legalAidPhoneScriptEs, italic: true)

            listSection(UIText.packetQuestions, items: packet.questionsForLawyerEs, marker: .bullet)

            coverSheet(packet.coverSheetEs)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .foregroundColor(.black)
    }

    private enum Marker { case checkbox, bullet }

    private func heading(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .heavy))
            .tracking(0.8)
            .foregroundColor(.black.opacity(0.55))
    }

    private func textSection(_ title: String, body: String, emphasized: Bool = false, italic: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            heading(title)
            Text(body)
                .font(.system(size: emphasized ? 15 : 13, weight: emphasized ? .semibold : .regular))
                .italic(italic)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func monoSection(_ title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            heading(title)
            Text(body)
                .font(.system(size: 12, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(Rectangle().stroke(Color.black.opacity(0.4), lineWidth: 1))
        }
    }

    private func listSection(_ title: String, items: [String], marker: Marker) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            heading(title)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text(marker == .checkbox ? "☐" : "•")
                        .font(.system(size: 13))
                    Text(item)
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func coverSheet(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            heading(UIText.packetCoverSheet)
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
    }
}

// MARK: - PDF renderer

enum PacketPDF {

    /// Render `packet` to a paginated US-Letter PDF in the temp directory.
    /// Returns the file URL, or nil if rendering failed.
    @MainActor
    static func render(packet: PreparationPacket) -> URL? {
        // US Letter at 72 dpi.
        let pageSize = CGSize(width: 612, height: 792)
        let margin: CGFloat = 36
        let contentWidth = pageSize.width - margin * 2
        let pageContentHeight = pageSize.height - margin * 2

        // Rasterize the print layout at the page content width.
        let renderer = ImageRenderer(
            content: PacketPrintDocument(packet: packet).frame(width: contentWidth)
        )
        renderer.proposedSize = ProposedViewSize(width: contentWidth, height: nil)
        renderer.scale = 3 // crisp text when printed

        guard let image = renderer.uiImage, image.size.width > 0 else { return nil }

        // On-page height of the image once scaled to the content width.
        let drawnHeight = image.size.height * (contentWidth / image.size.width)
        let pageCount = max(1, Int(ceil(drawnHeight / pageContentHeight)))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Carta-Clara-Paquete.pdf")

        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        )
        do {
            try pdfRenderer.writePDF(to: url) { context in
                for page in 0..<pageCount {
                    context.beginPage()
                    let cg = context.cgContext
                    // Clip to the page's content area so nothing bleeds into
                    // the margins of the adjacent page slice.
                    cg.saveGState()
                    cg.clip(to: CGRect(x: margin, y: margin,
                                       width: contentWidth, height: pageContentHeight))
                    let yOffset = margin - CGFloat(page) * pageContentHeight
                    image.draw(in: CGRect(x: margin, y: yOffset,
                                          width: contentWidth, height: drawnHeight))
                    cg.restoreGState()
                }
            }
            return url
        } catch {
            return nil
        }
    }
}
