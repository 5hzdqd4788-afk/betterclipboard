import Foundation
import Sparkle

@MainActor
final class UpdateService: NSObject {
    static let shared = UpdateService()
    
    private var updaterController: SPUStandardUpdaterController?
    
    private override init() {
        super.init()
    }
    
    /// Вызвать один раз при запуске приложения
    func start() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
    
    /// Вызвать из меню «Проверить обновления»
    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
}

