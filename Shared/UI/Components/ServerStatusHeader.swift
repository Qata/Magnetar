//
//  ServerStatusHeader.swift
//  Magnetar
//
//  Created by Charlotte Tortorella on 12/7/19.
//  Copyright © 2019 Monadic Consulting. All rights reserved.
//

import Foundation
import SwiftUI

struct ServerStatusHeader: View {
    let status: ServerStatus
    let ids: [String]

    func button(for command: Command, image: SystemImage) -> some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            if api.available(command: command.discriminator) {
                Button {
                    dispatch(async: .command(command))
                } label: {
                    image
                }
                Spacer()
            }
        }
    }
    
    var removeOrDeleteMenu: some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            if api.available(command: .remove) || api.available(command: .deleteData) {
                Menu {
                    if api.available(command: .remove) {
                        Button(
                            "Remove \(ids.count) Jobs"
                        ) {
                            dispatch(async: .command(.remove(ids)))
                        }
                    }
                    if api.available(command: .deleteData) {
                        Button(
                            "Delete Data For \(ids.count) Jobs"
                        ) {
                            dispatch(async: .command(.deleteData(ids)))
                        }
                    }
                } label: {
                    Button {
                    } label: {
                        SystemImage.xmark
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Group {
                    button(for: .start(ids), image: SystemImage.playFill)
                    button(for: .pause(ids), image: SystemImage.pauseFill)
                    button(for: .stop(ids), image: SystemImage.stopFill)
                    removeOrDeleteMenu
                }
                .buttonStyle(.bordered)
                .disabled(ids.isEmpty)
            }
            .padding(.horizontal, 20)
        }
    }
}

enum Comparator: String, CaseIterable, CustomStringConvertible {
    case equals
    case greaterThan
    case lessThan
    case greaterThanOrEqualTo
    case lessThanOrEqualTo
    
    var description: String {
        switch self {
        case .equals:
            return "=="
        case .greaterThan:
            return ">"
        case .lessThan:
            return "<"
        case .greaterThanOrEqualTo:
            return ">="
        case .lessThanOrEqualTo:
            return "<="
        }
    }
}
