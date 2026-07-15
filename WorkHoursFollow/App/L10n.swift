import Foundation

enum L10n {
    enum Tab {
        static let overview = String(localized: "tab.overview", defaultValue: "Overview")
        static let entries = String(localized: "tab.entries", defaultValue: "Entries")
        static let history = String(localized: "tab.history", defaultValue: "History")
        static let settings = String(localized: "tab.settings", defaultValue: "Settings")
    }

    enum Overview {
        static let currentPeriod = String(localized: "overview.current_period", defaultValue: "Current Pay Period")
        static func elapsedDays(_ elapsed: Int) -> String {
            String(format: String(localized: "overview.elapsed_days", defaultValue: "%lld of 14 days"), elapsed)
        }
        static func nextPayday(_ date: String) -> String {
            String(format: String(localized: "overview.next_payday", defaultValue: "Next payday: %@"), date)
        }
        static let addWorkTime = String(localized: "overview.add_work_time", defaultValue: "Add Work Time")
        static let unavailableTitle = String(localized: "overview.unavailable.title", defaultValue: "Current Period Unavailable")
        static let unavailableDescription = String(localized: "overview.unavailable.description", defaultValue: "The current pay period couldn’t be calculated.")
    }

    enum Entries {
        static let title = String(localized: "entries.title", defaultValue: "Entries")
        static let currentPeriod = String(localized: "entries.current_period", defaultValue: "Current Pay Period")
        static let noWorkTime = String(localized: "entries.no_work_time", defaultValue: "No work time recorded for this period.")
        static let addTime = String(localized: "entries.add_time", defaultValue: "Add Time for a Day")
        static let deleteDialogTitle = String(localized: "entries.delete_dialog.title", defaultValue: "Delete Work Entry?")
        static let deleteDialogMessage = String(localized: "entries.delete_dialog.message", defaultValue: "This work entry will be permanently removed.")
        static let deleteDialogDelete = String(localized: "entries.delete_dialog.delete", defaultValue: "Delete")
        static let deleteDialogCancel = String(localized: "entries.delete_dialog.cancel", defaultValue: "Cancel")
        static let deleteErrorTitle = String(localized: "entries.delete_error.title", defaultValue: "Couldn’t Delete Work Entry")
        static let deleteErrorMessage = String(localized: "entries.delete_error.message", defaultValue: "The entry is still here. Please try deleting it again.")
        static let deleteErrorOk = String(localized: "entries.delete_error.ok", defaultValue: "OK")
    }

    enum Editor {
        static let titleAdd = String(localized: "editor.title.add", defaultValue: "Add Work Time")
        static let titleEdit = String(localized: "editor.title.edit", defaultValue: "Edit Work Time")
        static let cancel = String(localized: "editor.cancel", defaultValue: "Cancel")
        static let save = String(localized: "editor.save", defaultValue: "Save")
        static let date = String(localized: "editor.date", defaultValue: "Date")
        static let dateLabel = String(localized: "editor.date.label", defaultValue: "Work date")
        static let dateHint = String(localized: "editor.date.hint", defaultValue: "Choose today or an earlier work date")
        static let duration = String(localized: "editor.duration", defaultValue: "Total Time Worked")
        static let durationHours = String(localized: "editor.duration.hours", defaultValue: "Hours")
        static let durationMinutes = String(localized: "editor.duration.minutes", defaultValue: "Minutes")
        static let earningsRate = String(localized: "editor.earnings.rate", defaultValue: "Rate")
        static func earningsRateFormat(_ rate: String) -> String {
            String(format: String(localized: "editor.earnings.rate_format", defaultValue: "%@ / hour"), rate)
        }
        static let earningsEstimated = String(localized: "editor.earnings.estimated", defaultValue: "Estimated earned")
        static let validationDate = String(localized: "editor.validation.date", defaultValue: "Choose today or an earlier date.")
        static let validationDuration = String(localized: "editor.validation.duration", defaultValue: "Enter a work duration greater than zero.")
        static let validationRate = String(localized: "editor.validation.rate", defaultValue: "The hourly rate must be greater than zero. Check Settings and try again.")
        static let duplicateTitle = String(localized: "editor.alert.duplicate.title", defaultValue: "Entry Already Exists")
        static let duplicateMessage = String(localized: "editor.alert.duplicate.message", defaultValue: "There is already work time recorded for this date.")
        static let duplicateEdit = String(localized: "editor.alert.duplicate.edit", defaultValue: "Edit Existing Entry")
        static let duplicateReplace = String(localized: "editor.alert.duplicate.replace", defaultValue: "Replace")
        static let duplicateCancel = String(localized: "editor.alert.duplicate.cancel", defaultValue: "Cancel")
        static let persistenceTitle = String(localized: "editor.alert.persistence.title", defaultValue: "Couldn’t Save Work Time")
        static let persistenceMessage = String(localized: "editor.alert.persistence.message", defaultValue: "Your changes are still here. Please try saving again.")
        static let persistenceOk = String(localized: "editor.alert.persistence.ok", defaultValue: "OK")
        static let validationTitle = String(localized: "editor.alert.validation.title", defaultValue: "Check Work Time")
        static let validationOk = String(localized: "editor.alert.validation.ok", defaultValue: "OK")
    }

    enum Settings {
        static let restoredTitle = String(localized: "settings.notice.restored.title", defaultValue: "Safe Defaults Restored")
        static let restoredMessage = String(localized: "settings.notice.restored.message", defaultValue: "Missing or invalid settings were replaced with the documented $23 CAD biweekly defaults.")
        static let failedTitle = String(localized: "settings.notice.failed.title", defaultValue: "Settings Need Attention")
        static let failedMessage = String(localized: "settings.notice.failed.message", defaultValue: "The app couldn’t save replacement settings. Safe defaults will be used for this session.")
        static let ok = String(localized: "settings.notice.ok", defaultValue: "OK")
        
        static let title = String(localized: "settings.title", defaultValue: "Settings")
        static let sectionEarnings = String(localized: "settings.section.earnings", defaultValue: "Earnings")
        static let hourlyRate = String(localized: "settings.hourly_rate", defaultValue: "Hourly Rate")
        static let currency = String(localized: "settings.currency", defaultValue: "Currency")
        static let sectionGoals = String(localized: "settings.section.goals", defaultValue: "Goals")
        static let targetEarnings = String(localized: "settings.target_earnings", defaultValue: "Earnings Target (Per Cycle)")
        static let save = String(localized: "settings.save", defaultValue: "Save Changes")
    }

    static let appName = String(localized: "app.name", defaultValue: "Work Hours Follow")
}
