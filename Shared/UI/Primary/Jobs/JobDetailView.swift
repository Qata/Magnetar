import SwiftUI

struct CommandButton<Content: View>: View {
    let dispatch = Global.store.writeOnly(async: { $0 })

    let title: Text?
    let command: Command
    let status: Status
    let invalidStatuses: [Status]
    let api: APIDescriptor
    let content: (_ title: Text?, _ image: SystemImage, _ action: @escaping () -> Void) -> Content

    init(
        title: Bool,
        command: ([String]) -> Command,
        viewModel: JobViewModel,
        invalidStatuses: [Status],
        api: APIDescriptor,
        content: @escaping (_ title: Text?, _ image: SystemImage, _ action: @escaping () -> Void) -> Content
    ) {
        self.command = command([viewModel.id])
        self.title = title
            .if(
                true: self.command.discriminator.description
            ).map(Text.init)
        self.status = viewModel.status
        self.invalidStatuses = invalidStatuses
        self.api = api
        self.content = content
    }
    
    var body: some View {
        if api.available(command: command.discriminator) {
            content(
                title,
                image,
                { dispatch(async: .command(command)) }
            )
        }
    }
    
    var image: SystemImage {
        switch command {
        case .requestToken:
            return .arrowClockwise
        case .fetch:
            return .arrowClockwise
        case .startNow:
            return .playFill
        case .start:
            return .playFill
        case .stop:
            return .stopFill
        case .pause:
            return .pauseFill
        case .remove:
            return .xmark
        case .deleteData:
            return .xmarkBin
        case .addURI:
            return .linkBadgePlus
        case .addFile:
            return .docFillBadgePlus
        }
    }
}

struct JobDetailView: View {
    struct HLabel: View {
        enum LabelType {
            case preset
            case adHoc
        }
        
        let label: String
        let text: String
        let binding: Binding<String>
        let type: LabelType

        init(_ label: String, text: String, detail: Binding<String>, type: LabelType = .preset) {
            self.label = label
            self.text = text
            self.binding = detail
            self.type = type
        }

        var body: some View {
            HLabelled(label) {
                Menu {
                    Text(text)
                    Button("Copy", action: copy)
                    Button("View", action: view)
                    if type == .adHoc {
                        Button("Rename", action: rename)
                    }
                } label: {
                    Text(text)
                        .lineLimit(nil)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        
        func copy() {
            UIPasteboard.general.string = text
        }
        
        func rename() {
            
        }
        
        func view() {
            binding.wrappedValue = text
        }
    }

    @State var detailViewText = ""
    let viewModel: JobViewModel

    @ViewBuilder
    func button(disabledIf invalidStatuses: [Status] = [], command: @escaping ([String]) -> Command) -> some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            CommandButton(
                title: false,
                command: command,
                viewModel: viewModel,
                invalidStatuses: invalidStatuses,
                api: api
            ) { title, image, action in
                Button(action: action) {
                    Label {
                        title
                    } icon: {
                        image
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    func button(image: SystemImage, text: String? = nil, action: @escaping () -> Void) -> AnyView {
        .init(
            Button(action: action) {
                HStack {
                    image
                    text.map(Text.init)
                }
            }
            .buttonStyle(.bordered)
        )
    }

    @ViewBuilder
    var buttons: some View {
        OptionalStoreView(\.persistent.selectedServer?.api) { api, dispatch in
            button(
                image: .playFill,
                action: { dispatch(async: .command(.start([viewModel.id]))) }
            ).disabled(
                !api.available(command: .start)
                || [.downloading, .seeding].contains(viewModel.status)
            )
            Spacer()
            if api.jobs.status[.paused] != nil {
                button(
                    image: .pauseFill,
                    action: { dispatch(async: .command(.pause([viewModel.id]))) }
                ).disabled(
                    !api.available(command: .pause)
                    || [.paused, .stopped].contains(viewModel.status)
                )
                Spacer()
            }
            button(
                image: .stopFill,
                action: { dispatch(async: .command(.stop([viewModel.id]))) }
            )
            .disabled(
                !api.available(command: .stop)
                || viewModel.status == .stopped
            )
            Spacer()
            Menu {
                Button("Remove") {
                    dispatch(async: .command(.remove([viewModel.id])))
                }
                .disabled(!api.available(command: .remove))
                Button("Delete Data") {
                    dispatch(async: .command(.deleteData([viewModel.id])))
                }
                .disabled(!api.available(command: .deleteData))
            } label: {
                button(image: .xmark, action: {})
            }
            .disabled(![.remove, .deleteData].contains(where: api.available))
        }
    }

    var body: some View {
        List {
            Section {
                HLabel("Name", text: viewModel.name, detail: $detailViewText)
                HLabel("Status", text: viewModel.status.description, detail: $detailViewText)
                HLabel("Size", text: viewModel.size.description, detail: $detailViewText)
                HLabel("Downloaded", text: viewModel.downloaded.description, detail: $detailViewText)
                HLabel("Uploaded", text: viewModel.uploaded.description, detail: $detailViewText)
            }
            Section {
                HLabel("ID", text: viewModel.id, detail: $detailViewText)
                HLabel("Upload Speed", text: viewModel.uploadSpeed.description, detail: $detailViewText)
                HLabel("Download Speed", text: viewModel.downloadSpeed.description, detail: $detailViewText)
                HLabel("Ratio", text: viewModel.ratio.description, detail: $detailViewText)
                HLabel("ETA", text: viewModel.eta.description, detail: $detailViewText)
            }

            Section {
                ForEach(viewModel.additional.sorted(keyPath: \.name), id: \.name) { field in
                    field.isValid.if(
                        true: HLabel(
                            field.name,
                            text: field.description,
                            detail: $detailViewText,
                            type: .adHoc
                        )
                    )
                }
            }
        }
        .navigationTitle(viewModel.name)
        .overlay {
            NavigationLink(
                isActive: .init(
                    get: {
                        !detailViewText.isEmpty
                    },
                    set: { _ in
                        detailViewText.removeAll()
                    }
                )
            ) {
                ScrollView(.vertical) {
                    Text(detailViewText)
                        .lineLimit(nil)
                        .padding()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Copy") {
                            UIPasteboard.general.string = detailViewText
                        }
                    }
                }
            } label: {
                EmptyView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                buttons
            }
        }
    }
}
