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
    let dispatch = Global.store.writeOnly(async: { $0 })
    
    var status: ServerStatus
    
    var body: some View {
        VStack {
//            Text(status.description)
//                .accessibility(label: Text("Server status"))
//                .accessibility(value: Text(status.description))
//                .accessibility(addTraits: .isHeader)
            HStack {
                Button {
                    dispatch(async: .command(.start([])))
                } label: {
                    SystemImage.playFill
                }
                .buttonStyle(.bordered)
                Spacer()
                Button {
                    dispatch(async: .command(.pause([])))
                } label: {
                    SystemImage.pauseFill
                }
                .buttonStyle(.bordered)
                Spacer()
                Button {
                    dispatch(async: .command(.stop([])))
                } label: {
                    SystemImage.stopFill
                }
                .buttonStyle(.bordered)
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

struct ConditionalCommandView: View {
    @State var field: Job.Field.Descriptor.PresetField = .name
    @State var comparator: Comparator = .equals
    
    var body: some View {
        Form {
            Picker("Field", selection: $field) {
                ForEach(Job.Field.Descriptor.PresetField.allCases, id: \.self) { value in
                    Text(value.description)
                        .tag(value)
                }
            }
            Picker("Comparator", selection: $comparator) {
                ForEach(Comparator.allCases, id: \.self) { value in
                    Text(value.description)
                        .tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
