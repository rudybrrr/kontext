import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct CaptureSheet: View {
    let container: ModelContainer

    @Environment(\.dismiss) private var dismiss
    @State private var kind: CaptureKind = .text
    @State private var text = ""
    @State private var urlText = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        let hasImage = imageData != nil
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(CaptureKind.allCases, id: \.self) { value in
                        Text(value.label).tag(value)
                    }
                }
                .pickerStyle(.segmented)

                Section {
                    switch kind {
                    case .text:
                        TextEditor(text: $text)
                            .frame(minHeight: 180)
                            .accessibilityLabel("Capture text")
                            .accessibilityIdentifier("capture-text")
                    case .url:
                        TextField("https://example.com", text: $urlText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .accessibilityLabel("URL")
                            .accessibilityIdentifier("capture-url")
                    case .image:
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(hasImage ? "Choose another image" : "Choose from Photos", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        if let imageData, let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("Selected image")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Capture error: \(errorMessage)")
                    }
                }
            }
            .navigationTitle("New Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave || isSaving)
                        .accessibilityIdentifier("save-capture")
                }
            }
            .task(id: photoItem) {
                guard let photoItem else { return }
                isSaving = true
                defer { isSaving = false }
                do {
                    imageData = try await photoItem.loadTransferable(type: Data.self)
                    if imageData == nil { errorMessage = "That image could not be read." }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var canSave: Bool {
        switch kind {
        case .text: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .url: !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .image: imageData != nil
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        Task { @MainActor in
            do {
                let store = CaptureStore(container: container)
                switch kind {
                case .text:
                    try store.captureText(text)
                case .url:
                    let value = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let normalized = value.contains("://") ? value : "https://\(value)"
                    guard let url = URL(string: normalized) else { throw CaptureStoreError.unsupportedURL }
                    try store.captureURL(url)
                case .image:
                    guard let imageData else { throw CaptureStoreError.emptyContent }
                    let media = try await MediaStore().saveImageData(imageData)
                    try store.captureImage(assetPath: media.assetPath, thumbnailPath: media.thumbnailPath)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

private extension CaptureKind {
    var label: String {
        switch self {
        case .text: "Text"
        case .url: "URL"
        case .image: "Image"
        }
    }
}
