//
//  LandmarkViewModel.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import Foundation
import Combine

@MainActor
class LandmarkViewModel: ObservableObject {
    @Published var landmarks: [Landmark] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = SupabaseService.shared
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let landmarksTask = service.fetchLandmarks()
            async let categoriesTask = service.fetchCategories()
            let (fetchedLandmarks, fetchedCategories) = try await (landmarksTask, categoriesTask)
            
            landmarks = fetchedLandmarks
            categories = fetchedCategories
        } catch is CancellationError {
            print("Task cancelled")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
