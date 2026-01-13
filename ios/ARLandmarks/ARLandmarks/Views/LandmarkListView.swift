//
//  LandmarkListView.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import SwiftUI

struct LandmarkListView: View {
    @StateObject private var viewModel = LandmarkViewModel()
    @State private var showARView = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Laden...")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Erneut versuchen") {
                            Task { await viewModel.loadData() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(viewModel.landmarks) { landmark in
                        LandmarkRowView(landmark: landmark)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("AR Landmarks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showARView = true
                    } label: {
                        Image(systemName: "arkit")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .disabled(viewModel.landmarks.isEmpty)
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .fullScreenCover(isPresented: $showARView) {
                ARLandmarkView(landmarks: viewModel.landmarks)
            }
        }
    }
}

#Preview {
    LandmarkListView()
}
