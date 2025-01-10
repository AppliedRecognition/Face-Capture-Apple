//
//  PageView.swift
//  FaceCapture
//
//  Created by Jakub Dolejs on 10/01/2025.
//

import Foundation
import SwiftUI
import UIKit

struct PageView<Content: View>: UIViewControllerRepresentable {
    let views: [Content]
    @Binding var currentPage: Int
    lazy var viewControllers: [UIHostingController] = self.views.map { UIHostingController(rootView: $0) }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = context.coordinator
        pageVC.delegate = context.coordinator
        
        let initialVC = context.coordinator.viewControllerForIndex(currentPage)
        pageVC.setViewControllers([initialVC], direction: .forward, animated: false)
        return pageVC
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        let currentVC = context.coordinator.viewControllerForIndex(currentPage)
        uiViewController.setViewControllers([currentVC], direction: .forward, animated: false)
    }
    
    // MARK: - Coordinator to Manage Page Control
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageView
        
        init(_ parent: PageView) {
            self.parent = parent
        }
        
        func  viewControllerForIndex(_ index: Int) -> UIViewController {
            return self.parent.viewControllers[index]
        }
        
        // MARK: - Data Source Methods
        
        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = self.parent.viewControllers.firstIndex(of: viewController as! UIHostingController), index > 0 else {
                return nil
            }
            return self.viewControllerForIndex(index - 1)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController,
                                viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = self.parent.viewControllers.firstIndex(of: viewController as! UIHostingController), index + 1 < self.parent.viewControllers.count else {
                return nil
            }
            return self.viewControllerForIndex(index + 1)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController,
                                didFinishAnimating finished: Bool,
                                previousViewControllers: [UIViewController],
                                transitionCompleted completed: Bool) {
            if completed, let currentVC = pageViewController.viewControllers?.first, let index = self.parent.viewControllers.firstIndex(of: currentVC as! UIHostingController) {
                parent.currentPage = index
            }
        }
        
        func presentationCount(for pageViewController: UIPageViewController) -> Int {
            return self.parent.viewControllers.count
        }
        
        func presentationIndex(for pageViewController: UIPageViewController) -> Int {
            guard let currentVC = pageViewController.viewControllers?.first, let index = self.parent.viewControllers.firstIndex(of: currentVC as! UIHostingController) else {
                return 0
            }
            return index
        }
    }
}
