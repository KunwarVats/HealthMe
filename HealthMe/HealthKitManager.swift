import HealthKit
import SwiftUI

public class HealthKitManager: ObservableObject {
    private var healthStore = HKHealthStore()
    
    @Published var healthData: [String: String] = [:]
    
    init() {
        #if !targetEnvironment(simulator)
        requestAuthorization()
        #else
        fetchDummyData()
        #endif
    }
    
    // Request authorization for HealthKit access
    public func requestAuthorization() {
        let healthKitTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.electrocardiogramType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { success, error in
            if success {
                self.fetchHealthData()
            } else {
                print("Authorization failed: \(String(describing: error))")
            }
        }
    }
    
    // Fetch all health data
    public func fetchHealthData() {
        let healthDataTypes: [HKQuantityTypeIdentifier: String] = [
            .heartRate: "Heart Rate",
            .bloodPressureSystolic: "Systolic Blood Pressure",
            .bloodPressureDiastolic: "Diastolic Blood Pressure",
            .bloodGlucose: "Blood Glucose",
            .oxygenSaturation: "Oxygen Saturation",
            .bodyTemperature: "Body Temperature",
            .respiratoryRate: "Respiratory Rate",
            .restingHeartRate: "Resting Heart Rate",
            .vo2Max: "VO2 Max",
            .bodyMass: "Body Mass",
            .height: "Height",
            .activeEnergyBurned: "Active Energy Burned",
            .dietaryEnergyConsumed: "Dietary Energy Consumed"
        ]
        
        for (typeIdentifier, displayName) in healthDataTypes {
            fetchLatestSample(for: typeIdentifier, displayName: displayName)
        }
        
        // Fetch ECG data
        fetchECGSamples()
        
        // Fetch sleep analysis data
        fetchSleepAnalysis()
    }
    
    // Fetch the latest sample for a specific HealthKit data type
    public func fetchLatestSample(for identifier: HKQuantityTypeIdentifier, displayName: String) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { query, results, error in
            if let result = results?.first as? HKQuantitySample {
                let unit = self.getUnit(for: identifier)
                let value = result.quantity.doubleValue(for: unit)
                DispatchQueue.main.async {
                    self.healthData[displayName] = String(format: "%.2f", value)
                }
            } else {
                DispatchQueue.main.async {
                    self.healthData[displayName] = "N/A"
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch ECG samples
    public func fetchECGSamples() {
        let ecgType = HKObjectType.electrocardiogramType()
        let query = HKSampleQuery(sampleType: ecgType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            if let ecgSamples = results as? [HKElectrocardiogram] {
                for ecg in ecgSamples {
                    let classification = ecg.classification
                    let heartRate = ecg.averageHeartRate?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
                    DispatchQueue.main.async {
                        self.healthData["ECG Classification"] = "\(classification)"
                        self.healthData["ECG Average Heart Rate"] = String(format: "%.2f bpm", heartRate)
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    
    // Fetch sleep analysis data
    public func fetchSleepAnalysis() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { query, results, error in
            if let sleepSamples = results as? [HKCategorySample] {
                var totalSleepTime: TimeInterval = 0
                for sample in sleepSamples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                        totalSleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                DispatchQueue.main.async {
                    self.healthData["Total Sleep Time"] = self.formatTimeInterval(totalSleepTime)
                }
            }
        }
        healthStore.execute(query)
    }
    
    // Get the appropriate unit for a HealthKit data type
    public func getUnit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {
        switch identifier {
        case .heartRate, .restingHeartRate:
            return HKUnit(from: "count/min")
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return HKUnit.millimeterOfMercury()
        case .bloodGlucose:
            return HKUnit(from: "mg/dL")
        case .oxygenSaturation:
            return HKUnit.percent()
        case .bodyTemperature:
            return HKUnit.degreeCelsius()
        case .respiratoryRate:
            return HKUnit(from: "count/min")
        case .vo2Max:
            return HKUnit(from: "mL/kg·min")
        case .bodyMass:
            return HKUnit.gramUnit(with: .kilo)
        case .height:
            return HKUnit.meter()
        case .activeEnergyBurned, .dietaryEnergyConsumed:
            return HKUnit.kilocalorie()
        default:
            return HKUnit.count()
        }
    }
    
    // Format a time interval into hours and minutes
    public func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    // Provide dummy data for the simulator
    public func fetchDummyData() {
        let dummyData: [String: String] = [
            "Heart Rate": "72 bpm",
            "Systolic Blood Pressure": "120 mmHg",
            "Diastolic Blood Pressure": "80 mmHg",
            "Blood Glucose": "90 mg/dL",
            "Oxygen Saturation": "98%",
            "Body Temperature": "36.5 °C",
            "Respiratory Rate": "16 breaths/min",
            "Resting Heart Rate": "60 bpm",
            "VO2 Max": "45 mL/kg·min",
            "Body Mass": "70 kg",
            "Height": "1.75 m",
            "Active Energy Burned": "500 kcal",
            "Dietary Energy Consumed": "2000 kcal",
            "ECG Classification": "Sinus Rhythm",
            "ECG Average Heart Rate": "72 bpm",
            "Total Sleep Time": "7h 30m"
        ]
        self.healthData = dummyData
    }
}
