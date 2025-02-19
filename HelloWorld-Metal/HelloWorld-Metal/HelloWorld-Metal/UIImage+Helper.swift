import UIKit

extension UIImage {
  func resized(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
    return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
  }

  func normalized() -> [Float32]? {
    guard let cgImage = self.cgImage else { return nil }
    let w = cgImage.width
    let h = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * w
    let bitsPerComponent = 8

    // Render image into our buffer so we have access to pixel bytes
    var rawBytes: [UInt8] = [UInt8](repeating: 0, count: w * h * 4)
    rawBytes.withUnsafeMutableBytes { ptr in
      if let context = CGContext(data: ptr.baseAddress,
                                 width: w,
                                 height: h,
                                 bitsPerComponent: bitsPerComponent,
                                 bytesPerRow: bytesPerRow,
                                 space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        context.draw(cgImage, in: rect)
      }
    }

    var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: w * h * 3)
    // normalize the pixel buffer
    // see https://pytorch.org/hub/pytorch_vision_resnet/ for more detail
    for index in 0 ..< w * h {
      normalizedBuffer[index] = (Float32(rawBytes[index * 4 + 0]) / 255.0 - 0.485) / 0.229 // R
      normalizedBuffer[w * h + index] = (Float32(rawBytes[index * 4 + 1]) / 255.0 - 0.456) / 0.224 // G
      normalizedBuffer[w * h * 2 + index] = (Float32(rawBytes[index * 4 + 2]) / 255.0 - 0.406) / 0.225 // B
    }
    return normalizedBuffer
  }
}
