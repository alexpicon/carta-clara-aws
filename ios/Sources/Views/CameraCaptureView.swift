//
//  CameraCaptureView.swift
//  Carta Clara
//
//  Document capture: a large rear-camera button with a photo-library fallback.
//
//  The camera button is the biggest target on screen (grandma test, one-
//  handed). Every camera-permission state is handled — granted, denied,
//  undetermined — and a photo-library picker always works as a fallback so a
//  denied permission never dead-ends the user.
//
//  NOTE: the camera does not run in the iOS Simulator. Test on a physical
//  iPhone (see ios/README.md).
//

import AVFoundation
import Combine
import PhotosUI
import SwiftUI

struct CameraCaptureView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var camera = CameraModel()
    @Environment(\.openURL) private var openURL

    @State private var pickedItem: PhotosPickerItem?
    /// Image awaiting the user's confirm/retake decision.
    @State private var pendingImage: UIImage?
    @State private var pickerFailed = false

    var body: some View {
        ZStack {
            CCColor.ink.ignoresSafeArea()

            if let pendingImage {
                confirmView(for: pendingImage)
            } else {
                switch camera.authorizationStatus {
                case .authorized:
                    cameraView
                case .denied, .restricted:
                    permissionDeniedView
                default:
                    LoadingView(message: UIText.loading)
                        .background(CCColor.background)
                }
            }
        }
        .navigationTitle(UIText.cameraTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await camera.requestAccess()
        }
        .onDisappear {
            camera.stopSession()
        }
        // UIImage is not Equatable, so observe the publisher directly rather
        // than using onChange(of:).
        .onReceive(camera.$capturedImage) { newValue in
            if let newValue { pendingImage = newValue }
        }
        .onChange(of: pickedItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadPickedImage(newValue) }
        }
        .alert("No pudimos abrir esa foto", isPresented: $pickerFailed) {
            Button("OK", role: .cancel) {}
        }
    }

    // MARK: Live camera

    private var cameraView: some View {
        VStack(spacing: 0) {
            ZStack {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea(edges: .horizontal)
                // Framing guide.
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.85), lineWidth: 3)
                    .padding(CCSpacing.lg)
                    .accessibilityHidden(true)
            }
            .accessibilityElement()
            .accessibilityLabel("Vista de la cámara")
            .accessibilityHint(UIText.cameraHint)

            controlBar
        }
    }

    private var controlBar: some View {
        VStack(spacing: CCSpacing.md) {
            Text(UIText.cameraHint)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            // Shutter
            Button {
                camera.capturePhoto()
            } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 78, height: 78)
                    Circle().strokeBorder(.white, lineWidth: 4).frame(width: 92, height: 92)
                }
            }
            .frame(width: 96, height: 96)
            .accessibilityLabel(UIText.captureA11y)
            .accessibilityHint(UIText.captureA11yHint)
            .accessibilityAddTraits(.isButton)

            // Library fallback
            PhotosPicker(selection: $pickedItem, matching: .images) {
                Label(UIText.pickFromLibrary, systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(minHeight: 44)
            }
            .accessibilityHint("Elige una foto que ya tienes guardada.")
        }
        .padding(CCSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(CCColor.ink)
    }

    // MARK: Permission denied

    private var permissionDeniedView: some View {
        VStack(spacing: CCSpacing.md) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(CCColor.caution)
                .accessibilityHidden(true)
            Text(UIText.cameraDeniedTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CCColor.ink)
                .multilineTextAlignment(.center)
            Text(UIText.cameraDeniedBody)
                .font(.body)
                .foregroundStyle(CCColor.inkSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: CCSpacing.md) {
                Button(UIText.openSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(CCPrimaryButtonStyle())

                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label(UIText.pickFromLibrary, systemImage: "photo.on.rectangle")
                }
                .buttonStyle(CCSecondaryButtonStyle())
            }
        }
        .padding(CCSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CCColor.background)
    }

    // MARK: Confirm / retake

    private func confirmView(for image: UIImage) -> some View {
        VStack(spacing: CCSpacing.md) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: CCRadius.card))
                .padding(CCSpacing.md)
                .accessibilityLabel("Foto del documento que tomaste")

            Spacer()

            VStack(spacing: CCSpacing.md) {
                Button(UIText.usePhoto) {
                    appState.capturedImage = image
                    camera.stopSession()
                    appState.path.append(.processing)
                }
                .buttonStyle(CCPrimaryButtonStyle())

                Button(UIText.retake) {
                    pendingImage = nil
                    camera.clearCapture()
                    pickedItem = nil
                }
                .buttonStyle(CCSecondaryButtonStyle())
            }
            .padding(CCSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CCColor.background)
    }

    // MARK: Picker loading

    private func loadPickedImage(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                pendingImage = image
            } else {
                pickerFailed = true
            }
        } catch {
            pickerFailed = true
        }
    }
}

// MARK: - Camera model

/// Owns the AVCaptureSession lifecycle. Session configuration and capture run
/// on a private serial queue; @Published updates hop back to the main actor.
final class CameraModel: NSObject, ObservableObject {

    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var capturedImage: UIImage?

    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.cartaclara.camera.session")
    /// Touched only on `sessionQueue`.
    private var hasConfigured = false

    override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Request camera access (if needed) and start the session when authorized.
    func requestAccess() async {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        if current == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
        } else {
            await MainActor.run { self.authorizationStatus = current }
        }
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            startSession()
        }
    }

    /// Configure (once) and start the capture session.
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.hasConfigured {
                self.configure()
                self.hasConfigured = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    /// Stop the session to release the camera and save power.
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    /// Capture a still photo. The result arrives via the delegate callback.
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    /// Clear the last capture so the user can retake.
    func clearCapture() {
        capturedImage = nil
        startSession()
    }

    /// Build the input + output graph. Runs on `sessionQueue`.
    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard
            error == nil,
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
            self.stopSession()
        }
    }
}

// MARK: - Camera preview

/// A UIView backed by AVCaptureVideoPreviewLayer.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    /// UIView whose backing layer is the capture preview layer.
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
