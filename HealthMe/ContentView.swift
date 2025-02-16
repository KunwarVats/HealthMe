//
//  ContentView.swift
//  HealthMe
//
//  Created by Kunwar Vats on 11/02/25.
//
import SwiftUI

struct HealthDataView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some View {
        List {
            ForEach(healthKitManager.healthData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .font(.headline)
                    Spacer()
                    Text(value)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
