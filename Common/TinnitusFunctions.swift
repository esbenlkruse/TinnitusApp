//
//  TinnitusFunctions.swift
//  Tinnitus
//
//  Created by Esben Kruse on 18/11/2018.
//  Copyright © 2018 Google. All rights reserved.
//

import Foundation

func getUserName(deviceName: String) -> String {
    return deviceName.split(separator: " ").first.map(String.init)?.lowercased() ?? ""
}
