import SwiftUI
import AppKit
import Installer

struct SDCardBrowserView: View {
    @Bindable var coordinator: InstallationCoordinator

    @State private var currentPath = "/"
    @State private var items: [InstallationCoordinator.SDCardItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isDropTarget = false
    @State private var isUploading = false
    @State private var uploadFileName: String?
    @State private var itemPendingDeletion: InstallationCoordinator.SDCardItem?
    @State private var isDeleting = false

    @State private var showCreateFolderDialog = false
    @State private var newFolderName = ""

    @State private var itemPendingRename: InstallationCoordinator.SDCardItem?
    @State private var renameText = ""

    private struct UploadConflict {
        let sourceURL: URL
        let existingItem: InstallationCoordinator.SDCardItem
    }

    @State private var uploadConflict: UploadConflict?

    @State private var editingFileName: String?
    @State private var editingStatus: String?
    @State private var editWatcher: Task<Void, Never>?

    private struct PendingEdit {
        let localURL: URL
        let remoteName: String
        let parentPath: String
        let modificationDate: Date?
    }

    @State private var pendingEdit: PendingEdit?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Navigation

            HStack(spacing: 8) {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .disabled(currentPath == "/" || isLoading)
                .help(L10n.tr("common.back"))

                HStack(spacing: 6) {
                    Image(systemName: "externaldrive.fill")
                        .foregroundStyle(.secondary)

                    Text(currentPath)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(height: 28)
                .background(.quaternary.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Button {
                    showCreateFolderDialog = true
                    newFolderName = ""
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading || isUploading || isDeleting)
                .help(L10n.tr("sd.new_folder"))

                Button {
                    Task {
                        await reload()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                .help(L10n.tr("common.refresh"))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // MARK: - Contents

            if isLoading && items.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text(L10n.tr("sd.reading"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    Text(errorMessage)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    Button(L10n.tr("common.retry")) {
                        Task {
                            await reload()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                List(items) { item in
                    HStack(spacing: 10) {
                        Image(
                            systemName: item.isDirectory
                                ? "folder.fill"
                                : "doc.fill"
                        )
                        .foregroundStyle(
                            item.isDirectory
                                ? Color.accentColor
                                : Color.secondary
                        )
                        .frame(width: 20)

                        Text(item.name)
                            .lineLimit(1)

                        Spacer()

                        if !item.isDirectory {
                            Text(formatSize(item.size))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .overlay {
                        SDCardDragSourceView(
                            item: item,
                            parentPath: currentPath,
                            coordinator: coordinator,
                            onDoubleClick: {
                                if item.isDirectory {
                                    openDirectory(item.name)
                                } else {
                                    Task {
                                        await openFileForEditing(item)
                                    }
                                }
                            }
                        )
                    }
                    .contextMenu {
                        Button {
                            if item.isDirectory {
                                openDirectory(item.name)
                            } else {
                                Task {
                                    await openFileForEditing(item)
                                }
                            }
                        } label: {
                            Label(
                                item.isDirectory ? L10n.tr("common.open_folder") : L10n.tr("common.open"),
                                systemImage: item.isDirectory ? "folder" : "doc"
                            )
                        }

                        Button {
                            itemPendingRename = item
                            renameText = item.name
                        } label: {
                            Label(L10n.tr("common.rename"), systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            itemPendingDeletion = item
                        } label: {
                            Label(L10n.tr("common.delete"), systemImage: "trash")
                        }
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // MARK: - Status

            HStack {
                if isLoading || isUploading || isDeleting {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(L10n.sdBrowserItemCount(items.count))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .overlay {
            if isDropTarget {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        Color.accentColor,
                        style: StrokeStyle(
                            lineWidth: 3,
                            dash: [8, 5]
                        )
                    )
                    .padding(6)
                    .allowsHitTesting(false)
            }
        }
        .onDrop(
            of: [.fileURL],
            isTargeted: $isDropTarget
        ) { providers in
            handleDrop(providers)
        }
        .alert(
            L10n.tr("sd.delete.title"),
            isPresented: Binding(
                get: { itemPendingDeletion != nil },
                set: { if !$0 { itemPendingDeletion = nil } }
            ),
            presenting: itemPendingDeletion
        ) { item in
            Button(L10n.tr("common.cancel"), role: .cancel) {
                itemPendingDeletion = nil
            }

            Button(L10n.tr("common.delete"), role: .destructive) {
                Task {
                    await deleteItem(item)
                }
            }
        } message: { item in
            Text(
                item.isDirectory
                    ? L10n.tr("sd.delete.folder_message", item.name)
                    : L10n.tr("sd.delete.file_message", item.name)
            )
        }
        .alert(
            L10n.tr("sd.conflict.title"),
            isPresented: Binding(
                get: { uploadConflict != nil },
                set: { if !$0 { uploadConflict = nil } }
            ),
            presenting: uploadConflict
        ) { conflict in
            Button(L10n.tr("common.cancel"), role: .cancel) {
                uploadConflict = nil
            }

            Button(L10n.tr("sd.conflict.keep_both")) {
                Task {
                    await resolveConflictKeepBoth(conflict)
                }
            }

            Button(L10n.tr("sd.conflict.replace"), role: .destructive) {
                Task {
                    await resolveConflictReplace(conflict)
                }
            }
        } message: { conflict in
            Text(
                L10n.tr("sd.conflict.message", conflict.existingItem.name)
            )
        }
        .alert(
            L10n.tr("sd.edit.changed_title"),
            isPresented: Binding(
                get: { pendingEdit != nil },
                set: { if !$0 { pendingEdit = nil } }
            ),
            presenting: pendingEdit
        ) { edit in
            Button(L10n.tr("sd.edit.discard"), role: .destructive) {
                editingStatus = L10n.tr("sd.edit.not_sent")
                pendingEdit = nil
            }

            Button(L10n.tr("common.save")) {
                Task {
                    await savePendingEdit(edit)
                }
            }

            Button(L10n.tr("common.cancel"), role: .cancel) {
                pendingEdit = nil
            }
        } message: { edit in
            Text(
                L10n.tr("sd.edit.save_prompt", edit.remoteName)
            )
        }
        .sheet(isPresented: $showCreateFolderDialog) {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.tr("sd.new_folder"))
                    .font(.headline)

                TextField(L10n.tr("sd.new_folder_placeholder"), text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await createFolder()
                        }
                    }

                HStack {
                    Spacer()

                    Button(L10n.tr("common.cancel")) {
                        showCreateFolderDialog = false
                    }

                    Button(L10n.tr("common.create")) {
                        Task {
                            await createFolder()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(
                        newFolderName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .padding(20)
            .frame(width: 360)
        }
        .sheet(
            isPresented: Binding(
                get: { itemPendingRename != nil },
                set: { if !$0 { itemPendingRename = nil } }
            )
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.tr("common.rename"))
                    .font(.headline)

                TextField(L10n.tr("sd.rename_placeholder"), text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await renamePendingItem()
                        }
                    }

                HStack {
                    Spacer()

                    Button(L10n.tr("common.cancel")) {
                        itemPendingRename = nil
                    }

                    Button(L10n.tr("common.rename")) {
                        Task {
                            await renamePendingItem()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(
                        renameText.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .padding(20)
            .frame(width: 360)
        }
        .task {
            await reload()
        }
    }

    // MARK: - Navigation

    private func openDirectory(_ name: String) {
        if currentPath == "/" {
            currentPath = "/\(name)"
        } else {
            currentPath += "/\(name)"
        }

        items = []

        Task {
            await reload()
        }
    }

    private func goBack() {
        guard currentPath != "/" else { return }

        var components = currentPath
            .split(separator: "/")
            .map(String.init)

        if !components.isEmpty {
            components.removeLast()
        }

        currentPath = components.isEmpty
            ? "/"
            : "/" + components.joined(separator: "/")

        items = []

        Task {
            await reload()
        }
    }

    // MARK: - Loading

    @MainActor
    private func reload() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            items = try await coordinator.browseSDCard(path: currentPath)
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Open / Edit / Sync

    @MainActor
    private func openFileForEditing(
        _ item: InstallationCoordinator.SDCardItem
    ) async {
        guard !item.isDirectory else { return }

        editWatcher?.cancel()
        errorMessage = nil
        editingFileName = item.name
        editingStatus = L10n.tr("sd.opening", item.name)

        let parentPath = currentPath

        let editDirectory = URL(
            fileURLWithPath:
                "/private/tmp/sakuraswitch_download_edit_\(UUID().uuidString)",
            isDirectory: true
        )

        do {
            try FileManager.default.createDirectory(
                at: editDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            editingFileName = nil
            editingStatus = nil
            errorMessage =
                L10n.tr("sd.error.temp_folder", error.localizedDescription)
            return
        }

        let localURL = editDirectory.appendingPathComponent(
            item.name,
            isDirectory: false
        )

        do {
            try await coordinator.downloadSDCardFile(
                directoryPath: parentPath,
                fileName: item.name,
                destinationURL: localURL
            )

            guard NSWorkspace.shared.open(localURL) else {
                throw NSError(
                    domain: "SakuraSwitch",
                    code: 2001,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            L10n.tr("sd.error.cannot_open", item.name)
                    ]
                )
            }

            editingStatus = L10n.tr("sd.opened", item.name)

            let initialDate = modificationDate(localURL)

            editWatcher = Task {
                await watchEditedFile(
                    localURL: localURL,
                    remoteName: item.name,
                    parentPath: parentPath,
                    initialDate: initialDate
                )
            }

        } catch {
            editingFileName = nil
            editingStatus = nil
            errorMessage =
                L10n.tr("sd.error.open", error.localizedDescription)
        }
    }

    private func modificationDate(_ url: URL) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(
            atPath: url.path
        )

        return attrs?[.modificationDate] as? Date
    }

    @MainActor
    private func watchEditedFile(
        localURL: URL,
        remoteName: String,
        parentPath: String,
        initialDate: Date?
    ) async {
        let lastDate = initialDate

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))

            guard !Task.isCancelled else { return }

            guard FileManager.default.fileExists(
                atPath: localURL.path
            ) else {
                return
            }

            let newDate = modificationDate(localURL)

            guard newDate != nil, newDate != lastDate else {
                continue
            }

            /*
             * Даём редактору закончить атомарное сохранение файла.
             */
            try? await Task.sleep(for: .milliseconds(800))

            guard !Task.isCancelled else { return }

            pendingEdit = PendingEdit(
                localURL: localURL,
                remoteName: remoteName,
                parentPath: parentPath,
                modificationDate: newDate
            )

            editingStatus =
                L10n.tr("sd.edit.pending", remoteName)

            return
        }
    }

    @MainActor
    private func savePendingEdit(
        _ edit: PendingEdit
    ) async {
        editingStatus =
            L10n.tr("sd.syncing", edit.remoteName)

        do {
            try await coordinator.deleteSDCardItem(
                parentPath: edit.parentPath,
                itemName: edit.remoteName
            )

            try await coordinator.uploadSDCardFile(
                edit.localURL,
                destinationPath: edit.parentPath
            )

            editingStatus =
                L10n.tr("sd.synced", edit.remoteName)

            pendingEdit = nil

            if currentPath == edit.parentPath {
                await reload()
            }

        } catch {
            editingStatus = L10n.tr("sd.error.sync")
            errorMessage =
                L10n.tr("sd.error.save_changes", error.localizedDescription)
        }
    }

    // MARK: - Create / Rename

    @MainActor
    private func createFolder() async {
        let name = newFolderName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !name.isEmpty else { return }

        do {
            try await coordinator.createSDCardFolder(
                parentPath: currentPath,
                folderName: name
            )

            showCreateFolderDialog = false
            newFolderName = ""

            await reload()

        } catch {
            errorMessage =
                L10n.tr("sd.error.create_folder", error.localizedDescription)
        }
    }

    @MainActor
    private func renamePendingItem() async {
        guard let item = itemPendingRename else { return }

        let newName = renameText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !newName.isEmpty else { return }

        do {
            try await coordinator.renameSDCardItem(
                parentPath: currentPath,
                oldName: item.name,
                newName: newName
            )

            itemPendingRename = nil
            renameText = ""

            await reload()

        } catch {
            errorMessage =
                L10n.tr("sd.error.rename", error.localizedDescription)
        }
    }

    // MARK: - Delete

    @MainActor
    private func deleteItem(
        _ item: InstallationCoordinator.SDCardItem
    ) async {
        guard !isDeleting else { return }

        isDeleting = true
        errorMessage = nil

        defer {
            isDeleting = false
            itemPendingDeletion = nil
        }

        do {
            try await coordinator.deleteSDCardItem(
                parentPath: currentPath,
                itemName: item.name
            )

            await reload()

        } catch {
            errorMessage =
                L10n.tr("sd.error.delete", error.localizedDescription)
        }
    }

    // MARK: - Drag & Drop

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !isUploading else { return false }

        let fileProviders = providers.filter {
            $0.hasItemConformingToTypeIdentifier("public.file-url")
        }

        guard !fileProviders.isEmpty else {
            return false
        }

        Task {
            await uploadDroppedFiles(fileProviders)
        }

        return true
    }

    @MainActor
    private func uploadDroppedFiles(_ providers: [NSItemProvider]) async {

        guard !isUploading else {
            return
        }

        isUploading = true
        errorMessage = nil

        defer {
            isUploading = false
            uploadFileName = nil
        }

        do {

            for provider in providers {

                let url: URL =
                    try await withCheckedThrowingContinuation {
                        (continuation: CheckedContinuation<URL, any Error>) in

                        provider.loadItem(
                            forTypeIdentifier: "public.file-url",
                            options: nil
                        ) { item, error in

                            if let error {
                                continuation.resume(
                                    throwing: error
                                )
                                return
                            }

                            if let data = item as? Data,
                               let url = URL(
                                   dataRepresentation: data,
                                   relativeTo: nil
                               ) {

                                continuation.resume(
                                    returning: url
                                )
                                return
                            }

                            if let url = item as? URL {

                                continuation.resume(
                                    returning: url
                                )
                                return
                            }

                            continuation.resume(
                                throwing: NSError(
                                    domain: "SakuraSwitch",
                                    code: 1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            L10n.tr("sd.error.item_path")
                                    ]
                                )
                            )
                        }
                    }

                uploadFileName =
                    url.lastPathComponent

                let values =
                    try url.resourceValues(
                        forKeys: [
                            .isDirectoryKey,
                            .isRegularFileKey,
                            .isSymbolicLinkKey
                        ]
                    )

                if values.isSymbolicLink == true {
                    continue
                }

                let existing =
                    items.first {
                        $0.name.caseInsensitiveCompare(
                            url.lastPathComponent
                        ) == .orderedSame
                    }

                // MARK: Folder -> Switch

                if values.isDirectory == true {

                    if let existing {

                        guard existing.isDirectory else {

                            throw NSError(
                                domain: "SakuraSwitch",
                                code: 2,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        L10n.tr("sd.error.name_exists", url.lastPathComponent)
                                ]
                            )
                        }

                    } else {

                        try await coordinator.ensureSDCardFolderForRecursiveUpload(
                            parentPath: currentPath,
                            folderName: url.lastPathComponent
                        )
                    }

                    let remoteFolderPath =
                        currentPath == "/"
                        ? "/\(url.lastPathComponent)"
                        : "\(currentPath)/\(url.lastPathComponent)"

                    try await coordinator
                        .uploadSDCardDirectoryContents(
                            url,
                            destinationPath: remoteFolderPath
                        )

                    continue
                }

                // MARK: File -> Switch

                guard values.isRegularFile == true else {

                    throw NSError(
                        domain: "SakuraSwitch",
                        code: 3,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                L10n.tr("sd.error.source_not_file")
                        ]
                    )
                }

                if let existing {

                    uploadConflict =
                        UploadConflict(
                            sourceURL: url,
                            existingItem: existing
                        )

                    return
                }

                try await coordinator.uploadSDCardFile(
                    url,
                    destinationPath: currentPath
                )
            }

            await reload()

        } catch {

            errorMessage =
                L10n.tr("sd.error.copy", error.localizedDescription)
        }
    }

    // MARK: - Upload Conflict

    @MainActor
    private func resolveConflictReplace(
        _ conflict: UploadConflict
    ) async {
        uploadConflict = nil
        isUploading = true
        uploadFileName = conflict.sourceURL.lastPathComponent
        errorMessage = nil

        defer {
            isUploading = false
            uploadFileName = nil
        }

        do {
            try await coordinator.deleteSDCardItem(
                parentPath: currentPath,
                itemName: conflict.existingItem.name
            )

            try await coordinator.uploadSDCardFile(
                conflict.sourceURL,
                destinationPath: currentPath
            )

            await reload()

        } catch {
            errorMessage =
                L10n.tr("sd.error.replace", error.localizedDescription)
        }
    }

    @MainActor
    private func resolveConflictKeepBoth(
        _ conflict: UploadConflict
    ) async {
        uploadConflict = nil
        isUploading = true
        errorMessage = nil

        defer {
            isUploading = false
            uploadFileName = nil
        }

        do {
            let fm = FileManager.default

            let originalURL = conflict.sourceURL
            let ext = originalURL.pathExtension
            let base = originalURL.deletingPathExtension().lastPathComponent

            var index = 1
            var candidateName: String

            while true {
                candidateName = ext.isEmpty
                    ? "\(base) (\(index))"
                    : "\(base) (\(index)).\(ext)"

                if !items.contains(where: {
                    $0.name.caseInsensitiveCompare(candidateName) == .orderedSame
                }) {
                    break
                }

                index += 1
            }

            uploadFileName = candidateName

            let stagingDirectory = URL(
                fileURLWithPath:
                    "/private/tmp/sakuraswitch_upload_\(UUID().uuidString)",
                isDirectory: true
            )

            try fm.createDirectory(
                at: stagingDirectory,
                withIntermediateDirectories: true
            )

            let tempURL = stagingDirectory.appendingPathComponent(
                candidateName,
                isDirectory: false
            )

            try fm.copyItem(
                at: originalURL,
                to: tempURL
            )

            defer {
                try? fm.removeItem(at: stagingDirectory)
            }

            try await coordinator.uploadSDCardFile(
                tempURL,
                destinationPath: currentPath
            )

            await reload()

        } catch {
            errorMessage =
                L10n.tr("sd.error.save_copy", error.localizedDescription)
        }
    }

    // MARK: - Formatting

    private var statusText: String {
        if let editingStatus {
            return editingStatus
        }

        if isDeleting {
            return L10n.tr("sd.status.deleting")
        }

        if isUploading {
            return uploadFileName.map {
                L10n.tr("sd.status.copying", $0, currentPath)
            } ?? L10n.tr("sd.status.copying_file")
        }

        if isLoading {
            return L10n.tr("sd.status.reading", currentPath)
        }

        return currentPath == "/"
            ? L10n.sdBrowserRoot
            : currentPath
    }

    private func formatSize(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(
            fromByteCount: Int64(bytes),
            countStyle: .file
        )
    }
}
