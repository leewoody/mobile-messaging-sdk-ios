//
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

@available(*, deprecated: 0.6.0, renamed: "Digest")
public typealias Hash = Digest

/// Hash functions to calculate Digest.
public struct Digest {
    /// Calculate SHA1 Digest
    /// - parameter bytes: input message
    /// - returns: Digest bytes
    public static func sha1(_ bytes: Array<UInt8>) -> Array<UInt8> {
        return SHA1().calculate(for: bytes)
    }
}