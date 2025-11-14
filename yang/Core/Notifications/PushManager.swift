import Foundation
import Combine
import UserNotifications

@MainActor
final class PushManager: ObservableObject {
    static let shared = PushManager()
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter: UNUserNotificationCenter
    private let identifierPrefix = "starReminder-"
    private let reminderCount = 3
    private let reminderHour = 14
    private let reminderMinute = 0
    
    init(center: UNUserNotificationCenter = .current()) {
        self.notificationCenter = center
        Task {
            await refreshAuthorizationStatus()
        }
    }
    
    func refreshAuthorizationStatus() async {
        let status = await fetchAuthorizationStatus()
        authorizationStatus = status
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
            let status = await fetchAuthorizationStatus()
            authorizationStatus = status
            return granted && (status == .authorized || status == .provisional)
        } catch {
            print("Push permission request failed: \(error)")
            return false
        }
    }
    
    func scheduleStarReminders(startingFrom completionDate: Date = Date()) async {
        guard await ensureAuthorization() else { return }
        
        removeStarReminders()
        
        let calendar = Calendar.current
        for index in 1...reminderCount {
            guard let baseDate = calendar.date(byAdding: .day, value: index, to: completionDate),
                  let fireDate = calendar.date(
                    bySettingHour: reminderHour,
                    minute: reminderMinute,
                    second: 0,
                    of: baseDate
                  ) else {
                continue
            }
            
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            components.second = 0
            
            let content = UNMutableNotificationContent()
            content.title = "오늘의 순간을 남겨보세요"
            content.body = "하루가 지나 새로운 영상을 찍을 수 있어요"
            content.sound = .default
            content.categoryIdentifier = "star.reminder"
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "\(identifierPrefix)\(index)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await add(request: request)
            } catch {
                print("Failed to schedule \(identifier): \(error)")
            }
        }
        
        logPendingStarReminders()
    }
    
    func removeStarReminders() {
        let identifiers = (1...reminderCount).map { "\(identifierPrefix)\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    private func ensureAuthorization() async -> Bool {
        let status = await fetchAuthorizationStatus()
        authorizationStatus = status
        
        switch status {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return await requestAuthorization()
        default:
            return false
        }
    }
    
    private func fetchAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { (continuation: CheckedContinuation<UNAuthorizationStatus, Never>) in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }
    
    private func add(request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notificationCenter.add(request) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    private func logPendingStarReminders() {
        notificationCenter.getPendingNotificationRequests { [identifierPrefix] requests in
            let starRequests = requests.filter { $0.identifier.hasPrefix(identifierPrefix) }
            guard !starRequests.isEmpty else {
                print("No pending star reminders.")
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            for request in starRequests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let date = trigger.nextTriggerDate() {
                    let formattedDate = formatter.string(from: date)
                    print("Pending reminder \(request.identifier) at \(formattedDate)")
                } else {
                    print("Pending reminder \(request.identifier) with unknown trigger")
                }
            }
        }
    }
}

