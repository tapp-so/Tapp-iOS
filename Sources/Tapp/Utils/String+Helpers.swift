//
//  File.swift
//  Tapp
//
//  Created by Alex Stergiou on 10/04/2025.
//

import Foundation

extension String {
    public static var empty: String {
        return ""
    }

    public static var emptyNSString: NSString {
        return String.empty as NSString
    }
}
