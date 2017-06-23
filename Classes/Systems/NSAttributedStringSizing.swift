//
//  NSAttributedStringSizing.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/14/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

final class NSAttributedStringSizing: NSObject, ListDiffable {

    private let textContainer: NSTextContainer
    private let textStorage: NSTextStorage
    private let layoutManager: NSLayoutManager

    let inset: UIEdgeInsets
    let attributedText: NSAttributedString
    let textViewSize: CGSize
    let textSize: CGSize
    let screenScale: CGFloat

    init(
        containerWidth: CGFloat,
        attributedText: NSAttributedString,
        inset: UIEdgeInsets = .zero,
        exclusionPaths: [UIBezierPath] = [],
        maximumNumberOfLines: Int = 0,
        lineFragmentPadding: CGFloat = 0.0,
        allowsNonContiguousLayout: Bool = false,
        hyphenationFactor: CGFloat = 0.0,
        showsInvisibleCharacters: Bool = false,
        showsControlCharacters: Bool = false,
        usesFontLeading: Bool = true,
        screenScale: CGFloat = UIScreen.main.scale
        ) {
        self.attributedText = attributedText
        self.inset = inset
        self.screenScale = screenScale

        let insetWidth = containerWidth - inset.left - inset.right
        textContainer = NSTextContainer(size: CGSize(width: insetWidth, height: 0))
        textContainer.exclusionPaths = exclusionPaths
        textContainer.maximumNumberOfLines = maximumNumberOfLines
        textContainer.lineFragmentPadding = lineFragmentPadding

        layoutManager = NSLayoutManager()
        layoutManager.allowsNonContiguousLayout = allowsNonContiguousLayout
        layoutManager.hyphenationFactor = hyphenationFactor
        layoutManager.showsInvisibleCharacters = showsInvisibleCharacters
        layoutManager.showsControlCharacters = showsControlCharacters
        layoutManager.usesFontLeading = usesFontLeading
        layoutManager.addTextContainer(textContainer)

        // storage implicitly required to use NSLayoutManager + NSTextContainer and find a size
        textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)

        // find the size of the text now that everything is configured
        let bounds = layoutManager.usedRect(for: textContainer)

        var viewSize = bounds.size

        // snap to pixel
        viewSize.width = ceil(viewSize.width * screenScale) / screenScale
        viewSize.height = ceil(viewSize.height * screenScale) / screenScale
        textSize = viewSize

        // adjust for the text view inset (contentInset + textContainerInset)
        viewSize.width += inset.left + inset.right
        viewSize.height += inset.top + inset.bottom
        textViewSize = viewSize
    }

    // MARK: Public API

    func configure(textView: UITextView) {
        textView.attributedText = attributedText
        textView.contentInset = .zero
        textView.textContainerInset = inset

        let textContainer = textView.textContainer
        textContainer.exclusionPaths = self.textContainer.exclusionPaths
        textContainer.maximumNumberOfLines = self.textContainer.maximumNumberOfLines
        textContainer.lineFragmentPadding = self.textContainer.lineFragmentPadding

        let layoutManager = textView.layoutManager
        layoutManager.allowsNonContiguousLayout = self.layoutManager.allowsNonContiguousLayout
        layoutManager.hyphenationFactor = self.layoutManager.hyphenationFactor
        layoutManager.showsInvisibleCharacters = self.layoutManager.showsInvisibleCharacters
        layoutManager.showsControlCharacters = self.layoutManager.showsControlCharacters
        layoutManager.usesFontLeading = self.layoutManager.usesFontLeading
        layoutManager.addTextContainer(textContainer)
    }

    private var _contents: CGImage? = nil
    func contents() -> CGImage? {
        guard _contents == nil else { return _contents }
        UIGraphicsBeginImageContextWithOptions(textSize, true, screenScale)
        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: textSize)).fill()
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
        let contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        _contents = contents
        return contents
    }

    // MARK: ListDiffable

    func diffIdentifier() -> NSObjectProtocol {
        return attributedText
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        if self === object { return true }
        guard let object = object as? NSAttributedStringSizing else { return false }
        return textViewSize == object.textViewSize
    }

}
