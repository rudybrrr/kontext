import SwiftData
import UIKit

@MainActor
final class ShareViewController: UIViewController {
    private let symbol = UIImageView(image: UIImage(systemName: "tray.and.arrow.down.fill"))
    private let message = UILabel()
    private var started = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        symbol.tintColor = .systemBlue
        symbol.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 38, weight: .semibold)
        message.text = "Saving…"
        message.font = .preferredFont(forTextStyle: .headline)
        message.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [symbol, message])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }
        started = true
        Task { await saveSharedItem() }
    }

    private func saveSharedItem() async {
        let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        guard let payload = await SharePayloadParser.parse(providers: providers) else {
            showFailure("Nothing supported was shared.")
            return
        }

        do {
            let container = try CapturePersistence.makeContainer()
            let store = CaptureStore(container: container)
            switch payload {
            case .text(let text):
                try store.captureText(text)
            case .url(let url):
                try store.captureURL(url)
            case .image(let data):
                let media = try await MediaStore().saveImageData(data)
                try store.captureImage(assetPath: media.assetPath, thumbnailPath: media.thumbnailPath)
            }
            symbol.image = UIImage(systemName: "checkmark.circle.fill")
            symbol.tintColor = .systemGreen
            message.text = "Captured"
            try? await Task.sleep(for: .milliseconds(350))
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            showFailure("Couldn’t save this capture.")
        }
    }

    private func showFailure(_ text: String) {
        symbol.image = UIImage(systemName: "exclamationmark.triangle.fill")
        symbol.tintColor = .systemOrange
        message.text = text
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.extensionContext?.cancelRequest(withError: ShareExtensionError.saveFailed)
        })
    }
}

private enum ShareExtensionError: LocalizedError {
    case saveFailed
    var errorDescription: String? { "Capture could not save the shared item." }
}
