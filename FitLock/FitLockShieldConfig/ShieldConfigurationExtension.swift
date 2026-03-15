import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Shield Configuration Extension
///
/// Customizes the appearance of the shield overlay shown on blocked apps.
/// The shield is displayed at the OS level and cannot be dismissed by the user.
class FitLockShieldConfig: ShieldConfigurationDataSource {

    // MARK: - Application Shield

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    // MARK: - Web Domain Shield

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    // MARK: - Shared Configuration

    private func makeShieldConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "lock.fill"),
            title: ShieldConfiguration.Label(
                text: "FitLock: Goals Not Met",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete your steps and calorie goals to unlock this app.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Check Progress",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue
            // No secondary button — no way to dismiss without meeting goals
        )
    }
}
