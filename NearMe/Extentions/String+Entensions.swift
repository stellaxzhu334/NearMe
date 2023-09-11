//
//  String+Entensions.swift
//  NearMe
//
//  Created by Stella Zhu on 2023/9/11.
//

import Foundation

extension String {
    var formatPhoneForCall: String {
        self.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
    }
}
