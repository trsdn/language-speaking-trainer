import CoreGraphics
import SwiftUI

/// A small red-on-black logo derived from the Google Material Symbols icon `emoji_language`.
///
/// The path data is extracted from the official Material Symbols font (see `docs/brand`).
struct LogoMarkView: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)

            MaterialSymbolEmojiLanguageShape()
                .fill(Color(red: 1.0, green: 0.176, blue: 0.176)) // #FF2D2D
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct MaterialSymbolEmojiLanguageShape: Shape {
    // Extracted from docs/brand/logo-emoji-language-red-black.svg (the `d=` attribute)
    private static let svgPathData: String = "M629 16Q517 16 433.0 83.0Q349 150 323 254Q364 252 403.0 260.5Q442 269 477 287H681Q683 298 683.5 311.0Q684 324 684 336Q684 346 684.0 356.5Q684 367 682 378H610Q627 395 640.0 415.0Q653 435 664 457H828Q807 492 773.5 519.0Q740 546 699 557Q703 576 705.0 596.0Q707 616 707 636Q810 611 877.0 527.0Q944 443 944 332Q944 201 852.5 108.5Q761 16 629 16ZM533 120Q525 141 518.5 162.5Q512 184 508 208H430Q447 177 473.5 154.5Q500 132 533 120ZM629 108Q643 132 653.5 157.0Q664 182 669 208H588Q590 202 603.5 167.0Q617 132 629 108ZM726 120Q759 132 785.5 154.5Q812 177 829 208H751Q748 185 741.0 163.0Q734 141 726 120ZM762 287H861Q863 297 864.0 308.5Q865 320 865 332Q865 344 864.5 355.5Q864 367 861 378H762Q763 367 763.5 357.0Q764 347 764 336Q764 324 763.5 311.5Q763 299 762 287ZM332 314Q200 314 108.0 406.0Q16 498 16 630Q16 761 108.0 852.5Q200 944 332 944Q463 944 555.0 853.0Q647 762 647 629Q647 498 555.0 406.0Q463 314 332 314ZM332 392Q430 392 499.0 461.5Q568 531 568 629Q568 727 499.0 796.0Q430 865 332 865Q234 865 164.5 796.0Q95 727 95 629Q95 531 164.5 461.5Q234 392 332 392ZM226 653Q242 653 253.5 664.5Q265 676 265 694Q265 709 253.0 720.5Q241 732 225 732Q209 732 197.5 720.5Q186 709 186 693Q186 676 197.5 664.5Q209 653 226 653ZM332 467Q382 467 421.0 494.5Q460 522 478 566H186Q204 522 243.0 494.5Q282 467 332 467ZM438 653Q454 653 465.5 664.5Q477 676 477 694Q477 709 465.5 720.5Q454 732 438 732Q421 732 410.0 720.5Q399 709 399 693Q399 676 410.0 664.5Q421 653 438 653ZM332 629Q332 629 332.0 629.0Q332 629 332 629Q332 629 332.0 629.0Q332 629 332 629Q332 629 332.0 629.0Q332 629 332 629Q332 629 332.0 629.0Q332 629 332 629Z"

    // Matches the SVG’s transform: translate(80, 1040) scale(1, -1)
    private static let svgToViewTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 80, ty: 1040)

    // SVG canvas size used by the generated logo (see svg width/height/viewBox).
    private static let canvasSize: CGFloat = 1120

    func path(in rect: CGRect) -> Path {
        let base = Self.basePath

        let scale = min(rect.width, rect.height) / Self.canvasSize
        let dx = (rect.width - Self.canvasSize * scale) / 2
        let dy = (rect.height - Self.canvasSize * scale) / 2

        return base.applying(CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale))
    }

    private static let basePath: Path = {
        var p = Path()

        let tokens = SVGPathTokenizer.tokenize(Self.svgPathData)
        var i = 0

        func nextNumber() -> Double {
            guard i < tokens.count, case let .number(v) = tokens[i] else {
                return 0
            }
            i += 1
            return v
        }

        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var currentCommand: Character? = nil

        while i < tokens.count {
            if case let .command(c) = tokens[i] {
                currentCommand = c
                i += 1
            }

            guard let cmd = currentCommand else { break }

            switch cmd {
            case "M":
                // First pair is a move; subsequent pairs are implicit "L".
                let x = nextNumber(); let y = nextNumber()
                current = CGPoint(x: x, y: y)
                p.move(to: current)
                subpathStart = current

                while i < tokens.count, tokens[i].isNumber {
                    let lx = nextNumber(); let ly = nextNumber()
                    current = CGPoint(x: lx, y: ly)
                    p.addLine(to: current)
                }

            case "L":
                while i < tokens.count, tokens[i].isNumber {
                    let x = nextNumber(); let y = nextNumber()
                    current = CGPoint(x: x, y: y)
                    p.addLine(to: current)
                }

            case "H":
                while i < tokens.count, tokens[i].isNumber {
                    let x = nextNumber()
                    current = CGPoint(x: x, y: current.y)
                    p.addLine(to: current)
                }

            case "V":
                while i < tokens.count, tokens[i].isNumber {
                    let y = nextNumber()
                    current = CGPoint(x: current.x, y: y)
                    p.addLine(to: current)
                }

            case "Q":
                while i < tokens.count, tokens[i].isNumber {
                    let cx = nextNumber(); let cy = nextNumber()
                    let x = nextNumber(); let y = nextNumber()
                    current = CGPoint(x: x, y: y)
                    p.addQuadCurve(to: current, control: CGPoint(x: cx, y: cy))
                }

            case "C":
                while i < tokens.count, tokens[i].isNumber {
                    let c1x = nextNumber(); let c1y = nextNumber()
                    let c2x = nextNumber(); let c2y = nextNumber()
                    let x = nextNumber(); let y = nextNumber()
                    current = CGPoint(x: x, y: y)
                    p.addCurve(to: current, control1: CGPoint(x: c1x, y: c1y), control2: CGPoint(x: c2x, y: c2y))
                }

            case "Z":
                p.closeSubpath()
                current = subpathStart

            default:
                // The generated path currently uses only absolute commands we handle above.
                // If it changes upstream, we prefer a harmless fallback over crashing.
                break
            }
        }

        return p.applying(Self.svgToViewTransform)
    }()
}

private enum SVGPathToken {
    case command(Character)
    case number(Double)

    var isNumber: Bool {
        if case .number = self { return true }
        return false
    }
}

private enum SVGPathTokenizer {
    static func tokenize(_ s: String) -> [SVGPathToken] {
        var out: [SVGPathToken] = []
        var numberBuf = ""

        func flushNumber() {
            guard !numberBuf.isEmpty else { return }
            if let v = Double(numberBuf) {
                out.append(.number(v))
            }
            numberBuf = ""
        }

        for ch in s {
            if ch.isLetter {
                flushNumber()
                out.append(.command(ch))
                continue
            }

            if ch == "-" || ch == "." || ch.isNumber {
                numberBuf.append(ch)
                continue
            }

            // separators: spaces, commas, etc.
            flushNumber()
        }

        flushNumber()
        return out
    }
}
