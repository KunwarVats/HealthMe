//
//  ContentView.swift
//  MeWatch Watch App
//
//  Created by Kunwar Vats on 15/02/25.
//

import SwiftUI
import WatchKit

struct HealthDataView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    // Icons for each data type
    let icons: [String: String] = [
        "Heart Rate": "heart.fill",
        "Systolic Blood Pressure": "waveform.path.ecg",
        "Diastolic Blood Pressure": "waveform.path.ecg",
        "Blood Glucose": "drop.fill",
        "Oxygen Saturation": "oxygen.level.fill",
        "Body Temperature": "thermometer",
        "Respiratory Rate": "lungs.fill",
        "Resting Heart Rate": "heart.fill",
        "VO2 Max": "figure.walk",
        "Body Mass": "figure.stand",
        "Height": "figure.arms.open",
        "Active Energy Burned": "flame.fill",
        "Dietary Energy Consumed": "applelogo",
        "ECG Classification": "waveform.path.ecg",
        "ECG Average Heart Rate": "heart.fill",
        "Total Sleep Time": "bed.double.fill"
    ]

    var body: some View {
        VStack {
            TabView {
                ForEach(healthKitManager.healthData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    VStack {
                        Image(systemName: icons[key] ?? "questionmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .padding()

                        Text(key)
                            .font(.headline)
                            .padding([.top, .bottom], 2)

                        Text(value)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                    }
                    .padding()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

struct ContentView: View {
    var body: some View {
        HealthDataView()
    }
}

#Preview {
    ContentView()
}
