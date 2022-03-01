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
        case .addMagnet:
            return .linkBadgePlus
        case .addFile:
            return .docFillBadgePlus
        }
    }
}

struct JobDetailView: View {
    struct HLabel: View {
        let label: String
        let text: String
        
        init(_ label: String, text: String) {
            self.label = label
            self.text = text
        }
        
        var body: some View {
            HLabelled(label) {
                Spacer()
                Text(text)
                    .foregroundColor(.secondary)
            }
        }
    }

    @StateObject var server = Global.store.lensing(state: { $0.selectedServer })
    let viewModel: JobViewModel
    
    @ViewBuilder
    func button(disabledIf invalidStatuses: [Status] = [], command: @escaping ([String]) -> Command) -> some View {
        if let api = server.state?.api {
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
        
        
        switch server.state?.api {
        case let api?:
            
            button(
                image: .playFill,
                action: { server.dispatch(async: .command(.start([viewModel.id]))) }
            ).disabled(
                !api.available(command: .start)
                || [.downloading, .seeding].contains(viewModel.status)
            )
            Spacer()
            if server.state?.api.jobs.status[.paused] != nil {
                button(
                    image: .pauseFill,
                    action: { server.dispatch(async: .command(.pause([viewModel.id]))) }
                ).disabled(
                    !api.available(command: .pause)
                    || [.paused, .stopped].contains(viewModel.status)
                )
                Spacer()
            }
            button(
                image: .stopFill,
                action: { server.dispatch(async: .command(.stop([viewModel.id]))) }
            )
            .disabled(
                !api.available(command: .stop)
                || viewModel.status == .stopped
            )
            Spacer()
            Menu {
                Button("Remove") {
                    server.dispatch(async: .command(.remove([viewModel.id])))
                }
                .disabled(!api.available(command: .remove))
                Button("Delete Data") {
                    server.dispatch(async: .command(.deleteData([viewModel.id])))
                }
                .disabled(!api.available(command: .deleteData))
            } label: {
                button(image: .xmark, action: {})
            }
            .disabled(![.remove, .deleteData].contains(where: api.available))
        case nil:
            EmptyView()
        }
    }

    var body: some View {
        List {
            Section(viewModel.name) {
                HLabel("Status", text: viewModel.status.description)
                HLabel("Size", text: viewModel.size.description)
                HLabel("Downloaded", text: viewModel.downloaded.description)
                HLabel("Uploaded", text: viewModel.uploaded.description)
            }
            Section {
                HStack {
                    buttons
                }
            }
            Section(viewModel.id) {
                HLabel("Upload Speed", text: viewModel.uploadSpeed.description)
                HLabel("Download Speed", text: viewModel.downloadSpeed.description)
                HLabel("Ratio", text: viewModel.ratio.description)
                HLabel("ETA", text: viewModel.eta.description)
            }

            Section {
                ForEach(viewModel.additional, id: \.name) { field in
                    if !field.description.isEmpty {
                        HLabel(field.name, text: field.description)
                    }
                }
            }
        }
    }
}
