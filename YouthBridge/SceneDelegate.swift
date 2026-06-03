//
//  SceneDelegate.swift
//  YouthBridge
//
//  Created by 이학민 on 6/2/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let tabBar = UITabBarController()
        tabBar.tabBar.tintColor = AppColor.primary
        tabBar.tabBar.backgroundColor = AppColor.background

        let homeNav = UINavigationController(rootViewController: HomeViewController())
        homeNav.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))

        let notifNav = UINavigationController(rootViewController: NotificationsViewController())
        notifNav.tabBarItem = UITabBarItem(title: "알림", image: UIImage(systemName: "bell"), selectedImage: UIImage(systemName: "bell.fill"))

        let myPageNav = UINavigationController(rootViewController: MyPageViewController())
        myPageNav.tabBarItem = UITabBarItem(title: "내 정보", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))

        tabBar.viewControllers = [homeNav, notifNav, myPageNav]

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBar
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

