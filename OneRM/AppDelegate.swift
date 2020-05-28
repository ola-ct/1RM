// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import UIKit
import CoreData
import Foundation

enum AppError: Error {
    case initialized
    case notInitialized
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if NSUbiquitousKeyValueStore.default.object(forKey: Key.barWeight.rawValue) == nil {
            NSUbiquitousKeyValueStore.default.set(defaultBarWeight, forKey: Key.barWeight.rawValue)
        }
        if NSUbiquitousKeyValueStore.default.object(forKey: Key.massUnit.rawValue) == nil {
            NSUbiquitousKeyValueStore.default.set(defaultMassUnit, forKey: Key.massUnit.rawValue)
        }
        if NSUbiquitousKeyValueStore.default.object(forKey: Key.plates.rawValue) == nil {
            NSUbiquitousKeyValueStore.default.set(defaultPlates, forKey: Key.plates.rawValue)
        }
        if NSUbiquitousKeyValueStore.default.object(forKey: Key.maxPercent.rawValue) == nil {
            NSUbiquitousKeyValueStore.default.set(defaultMaxPercent, forKey: Key.maxPercent.rawValue)
        }
        if NSUbiquitousKeyValueStore.default.object(forKey: Key.minPercent.rawValue) == nil {
            NSUbiquitousKeyValueStore.default.set(defaultMinPercent, forKey: Key.minPercent.rawValue)
        }
        if NSUbiquitousKeyValueStore.default.object(forKey: Key.percentStep.rawValue) == nil {
            NSUbiquitousKeyValueStore.default.set(defaultPercentStep, forKey: Key.percentStep.rawValue)
        }
        if NSUbiquitousKeyValueStore.default.object(forKey: Key.formulas.rawValue) == nil {
            NSUbiquitousKeyValueStore.default.set([Formula.brzycki.rawValue], forKey: Key.formulas.rawValue)
        }

        if let idToken = FileManager.default.ubiquityIdentityToken,
            let newTokenData = try? NSKeyedArchiver.archivedData(withRootObject: idToken, requiringSecureCoding: true) {
            NSUbiquitousKeyValueStore.default.set(newTokenData, forKey: "net.ersatzworld.OneRM.UbiquityIdentityToken")
            debugPrint("net.ersatzworld.OneRM.UbiquityIdentityToken = \(newTokenData)")
        } else {
            NSUbiquitousKeyValueStore.default.removeObject(forKey: "net.ersatzworld.OneRM.UbiquityIdentityToken")
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(iCloudAvailabilityChanged),
                                               name: Notification.Name.NSUbiquityIdentityDidChange,
                                               object: nil)

//        NSUbiquitousKeyValueStore.default.set(false, forKey: "appSuccessfullyInitialized")
//        if isFirstStart() {
//            addDefaultEntities(completeFirstLaunch)
//        }

        UINavigationBar.appearance().backgroundColor = UIColor(named: "Olive")
        UINavigationBar.appearance().barTintColor = UIColor(named: "Olive")
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UINavigationBar.appearance().tintColor = .white

//        let alertController = UIAlertController(title: NSLocalizedString("Choose storage", comment: ""),
//                                      message: NSLocalizedString("Should your data be stored in iCloud and available on all your devices?", comment: ""),
//                                      preferredStyle: .actionSheet)
//        let actionLocal = UIAlertAction(title: NSLocalizedString("Local only", comment: ""), style: .default, handler: { action in debugPrint(action) })
//        let actionCloud = UIAlertAction(title: NSLocalizedString("Use iCloud", comment: ""), style: .default, handler: { action in debugPrint(action) })
//        alertController.addAction(actionLocal)
//        alertController.addAction(actionCloud)

        return true
    }

    @objc func iCloudAvailabilityChanged(notification: Notification) {
        debugPrint("AppDelegate.iCloudAvailabilityChanged()", notification)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "OneRM")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                debugPrint("Unresolved error \(error), \(error.userInfo)")
            }
        })
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: "NSPersistentStoreRemoteChangeNotificationOptionKey")
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nserror = error as NSError
                debugPrint("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension AppDelegate {

    func isFirstStart() -> Bool {
        return !NSUbiquitousKeyValueStore.default.bool(forKey: "appSuccessfullyInitialized")
    }

    func completeFirstLaunch(_ error: AppError) {
        if error == .initialized {
            NSUbiquitousKeyValueStore.default.set(true, forKey: "appSuccessfullyInitialized")
        } else {
            debugPrint("ERROR: 1st launch not successfully completed")
        }
    }

    func addDefaultEntities(_ completionHandler: (_ error: AppError) -> Void) {

        let exercises = defaultExercises.enumerated().map { ExerciseData(name: $0.1, order: Int16($0.0)) }
        // swiftlint:disable:next force_try
        try! LiftDataManager.shared.save(exercises: exercises)

        let units = defaultUnits.map { UnitData(name: $0) }
        // swiftlint:disable:next force_try
        try! LiftDataManager.shared.save(units: units)

        completionHandler(.initialized)
    }
}
