//
//  DelegatedSceneStorageState.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import Foundation

struct DelegatedStorageState<V> {
    var isReady: Bool = false
    var value: V?

    var preparedValue: V? {
        isReady ? value : nil
    }
}
