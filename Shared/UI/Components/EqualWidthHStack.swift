//
//  EqualWidthHStack.swift
//  Magnetar
//
//  Created by Charles Maria Tor on 14/6/22.
//

import SwiftUI

//struct EqualWidthHStack: Layout {
//    func sizeThatFits(
//        proposal: ProposedViewSize,
//        subviews: Subviews,
//        cache: inout ()
//    ) -> CGSize {
//        let maxSize = maxSize(subviews: subviews)
//        let spacings = spacings(subviews: subviews)
//        let totalSpacing = spacings.reduce(0.0, +)
//
//        return CGSize(
//            width: maxSize.width * CGFloat(subviews.count) + totalSpacing,
//            height: maxSize.height
//        )
//    }
//
//    func placeSubviews(
//        in bounds: CGRect,
//        proposal: ProposedViewSize,
//        subviews: Subviews,
//        cache: inout ()
//    ) {
//        let maxSize = maxSize(subviews: subviews)
//        let spacing = spacings(subviews: subviews)
//
//        let size = ProposedViewSize(
//            width: maxSize.width,
//            height: maxSize.height
//        )
//        var x = bounds.minX + maxSize.width / 2
//
//        for index in subviews.indices {
//            subviews[index].place(
//                at: CGPoint(x: x, y: bounds.midY),
//                anchor: .center,
//                proposal: size
//            )
//            x += maxSize.width + spacing[index]
//        }
//    }
//
//    private func spacings(subviews: Subviews) -> [CGFloat] {
//        let spacing: [CGFloat] = subviews.indices.map { index in
//            guard index < subviews.count - 1 else {
//                return 0.0
//            }
//
//            return subviews[index].spacing.distance(
//                to: subviews[index + 1].spacing,
//                along: .horizontal
//            )
//        }
//        return spacing
//    }
//
//    private func maxSize(subviews: Subviews) -> CGSize {
//        let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
//        let maxSize: CGSize = subviewSizes.reduce(.zero) { current, size in
//            CGSize(
//                width: max(current.width, size.width),
//                height: max(current.height, size.height)
//            )
//        }
//        return maxSize
//    }
//}
