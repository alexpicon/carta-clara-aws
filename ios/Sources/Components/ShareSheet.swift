//
//  ShareSheet.swift
//  Carta Clara
//
//  A SwiftUI wrapper around UIActivityViewController.
//
//  Used by the Response Preparation Packet so the user can AirPrint it or
//  save it as a PDF — the packet is meant to leave the phone and travel to a
//  legal-aid appointment as a physical artifact (DEMO_SCRIPT 2:00).
//

import SwiftUI
import UIKit

/// Presents the system share sheet for the given activity items.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
