import CoreGraphics
import Foundation
import ImageIO

let outputPath = CommandLine.arguments[1]
let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fatalError("Unable to create icon context")
}

let teal = CGColor(red: 0.05, green: 0.21, blue: 0.20, alpha: 1)
let tealLight = CGColor(red: 0.08, green: 0.31, blue: 0.29, alpha: 1)
let cream = CGColor(red: 0.99, green: 0.97, blue: 0.90, alpha: 1)
let coral = CGColor(red: 0.96, green: 0.53, blue: 0.32, alpha: 1)

context.setFillColor(teal)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

let inset: CGFloat = 74
let field = CGPath(
    roundedRect: CGRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2),
    cornerWidth: 190,
    cornerHeight: 190,
    transform: nil
)
context.setFillColor(tealLight)
context.addPath(field)
context.fillPath()

context.setStrokeColor(cream)
context.setLineWidth(84)
context.setLineCap(.round)
context.setLineJoin(.round)

let vertical = CGMutablePath()
vertical.move(to: CGPoint(x: 336, y: 252))
vertical.addLine(to: CGPoint(x: 336, y: 772))
context.addPath(vertical)
context.strokePath()

let loop = CGMutablePath()
loop.move(to: CGPoint(x: 336, y: 772))
loop.addLine(to: CGPoint(x: 548, y: 772))
loop.addCurve(to: CGPoint(x: 648, y: 586), control1: CGPoint(x: 648, y: 772), control2: CGPoint(x: 706, y: 694))
loop.addCurve(to: CGPoint(x: 548, y: 430), control1: CGPoint(x: 706, y: 478), control2: CGPoint(x: 648, y: 430))
loop.addLine(to: CGPoint(x: 336, y: 430))
context.addPath(loop)
context.strokePath()

let leg = CGMutablePath()
leg.move(to: CGPoint(x: 510, y: 430))
leg.addLine(to: CGPoint(x: 704, y: 252))
context.addPath(leg)
context.strokePath()

context.setStrokeColor(coral)
context.setLineWidth(42)
context.setLineCap(.round)
context.setLineJoin(.round)
let arrow = CGMutablePath()
arrow.move(to: CGPoint(x: 748, y: 292))
arrow.addLine(to: CGPoint(x: 748, y: 566))
arrow.move(to: CGPoint(x: 676, y: 494))
arrow.addLine(to: CGPoint(x: 748, y: 566))
arrow.addLine(to: CGPoint(x: 820, y: 494))
context.addPath(arrow)
context.strokePath()

guard let image = context.makeImage(), let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outputPath) as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Unable to encode icon")
}
CGImageDestinationAddImage(destination, image, nil)
CGImageDestinationFinalize(destination)
