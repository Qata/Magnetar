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
        case .login:
            return .arrowClockwise
        case .fetch:
            return .arrowClockwise
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
    let store: SubStore<JobViewModel?, AsyncAction, SyncAction>
    @Environment(\.dismiss) var dismiss
    @State var viewModel: JobViewModel
    
    init?(id: String) {
        store = Global.store.lensing {
            $0.jobs[id]
        }
        guard let viewModel = store.state else {
            return nil
        }
        self._viewModel = .init(initialValue: viewModel)
    }

    var firstSection: some View {
        Section {
            HLabel("Name", text: viewModel.name)
            HLabel("Status", text: viewModel.status)
            HLabel("Size", text: viewModel.size)
            HLabel("Downloaded", text: viewModel.downloaded)
            HLabel("Uploaded", text: viewModel.uploaded)
        }
    }

    var secondSection: some View {
        Section {
            HLabel("ID", text: viewModel.id)
            HLabel("Upload Speed", text: viewModel.uploadSpeed)
            HLabel("Download Speed", text: viewModel.downloadSpeed)
            HLabel("Ratio", text: viewModel.ratio)
            HLabel("ETA", text: viewModel.eta)
        }
    }

    var additionalSection: some View {
        Section {
            ForEach(viewModel.additional.sorted(keyPath: \.name), id: \.name) { field in
                field.isValid.if(
                    true: HLabel(
                        field.name,
                        text: field.description,
                        type: .adHoc
                    )
                )
            }
        }
    }

    var body: some View {
        VStack {
            List {
                firstSection
                secondSection
                additionalSection
            }
            .navigationTitle(viewModel.name)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    CommandsMenu(jobs: [viewModel], image: .playpause) {
                        dismiss()
                    }
                }
            }
        }
        .onReceive(store.$state) {
            viewModel ?= $0
        }
    }
}

private extension JobDetailView {
    struct HLabel: View {
        enum LabelType {
            case preset
            case adHoc
        }

        let label: String
        let text: String
        let type: LabelType

        init(_ label: String, text: CustomStringConvertible, type: LabelType = .preset) {
            self.label = label
            self.text = text.description
            self.type = type
        }

        var body: some View {
            HLabelled(label) {
                Menu {
                    Text(text)
                    Button("Copy", action: copy)
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
    }
}
