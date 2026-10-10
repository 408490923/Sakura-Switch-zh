import SwiftUI

struct SettingsView: View {

    let appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text(L10n.tr("settings.title"))
                .font(.title)

            Divider()

            GroupBox(L10n.tr("settings.system")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        L10n.tr("settings.version_format", BundleAppVersionProvider().displayVersion)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox(L10n.tr("settings.connection")) {
                ConnectionStatusView(
                    isConnected: appState.isDeviceConnected,
                    mode: appState.coordinator.transportMode
                )
            }

            GroupBox(L10n.tr("settings.diagnostics")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tr("settings.verbose_logs_on"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(24)
    }
}
