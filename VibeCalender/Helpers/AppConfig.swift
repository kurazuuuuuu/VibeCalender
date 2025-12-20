//
//  AppConfig.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/20.
//

import Combine
import Foundation

class AppConfig: ObservableObject {
  static let shared = AppConfig()

  // デバッグモードフラグ
  @Published var isDebugMode: Bool = true
}
