import SwiftUI
import CoreImage.CIFilterBuiltins

enum QRCode {
    /// Crisp QR: integer upscale in CoreImage, drawn with no interpolation.
    static func image(_ text: String, scale: Int = 8) -> NSImage? {
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(text.utf8)
        f.correctionLevel = "M"
        guard let out = f.outputImage else { return nil }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale)))
        let rep = NSCIImageRep(ciImage: scaled)
        let img = NSImage(size: rep.size)
        img.addRepresentation(rep)
        return img
    }
}

struct QRView: View {
    let text: String
    var size: CGFloat = 150
    var body: some View {
        Group {
            if let img = QRCode.image(text) {
                Image(nsImage: img).interpolation(.none).resizable().scaledToFit()
            } else { Color.clear }
        }
        .padding(8).frame(width: size, height: size)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("QR code for \(text)")
    }
}
