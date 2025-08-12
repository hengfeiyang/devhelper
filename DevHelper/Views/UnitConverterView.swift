// Copyright 2025 Hengfei Yang.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import SwiftUI
import FirebaseAnalytics

struct UnitConverterView: View {
    let screenName = "Unit Converter"
    @State private var selectedCategory: UnitCategory = .data
    @State private var fromUnit: String = ""
    @State private var toUnit: String = ""
    @State private var inputValue: String = ""
    @State private var outputValue: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Category Selection
            Picker("Category", selection: $selectedCategory) {
                ForEach(UnitCategory.allCases, id: \.self) { category in
                    Text(category.title)
                        .tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedCategory) { _, newCategory in
                let units = newCategory.units
                fromUnit = units.first?.name ?? ""
                toUnit = units.count > 1 ? units[1].name : units.first?.name ?? ""
                convertUnits()
            }
            
            HStack(spacing: 40) {
                // From Unit
                VStack(alignment: .leading, spacing: 10) {
                    Text("From")
                        .font(.headline)
                    
                    Picker("From Unit", selection: $fromUnit) {
                        ForEach(selectedCategory.units, id: \.name) { unit in
                            Text(unit.symbol)
                                .tag(unit.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: fromUnit) { _, _ in
                        convertUnits()
                    }
                    
                    TextField("Enter value", text: $inputValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: inputValue) { _, _ in
                            convertUnits()
                        }
                }
                
                Image(systemName: "arrow.right")
                    .font(.title)
                    .foregroundColor(.blue)
                
                // To Unit
                VStack(alignment: .leading, spacing: 10) {
                    Text("To")
                        .font(.headline)
                    
                    Picker("To Unit", selection: $toUnit) {
                        ForEach(selectedCategory.units, id: \.name) { unit in
                            Text(unit.symbol)
                                .tag(unit.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: toUnit) { _, _ in
                        convertUnits()
                    }
                    
                    TextField("Result", text: $outputValue)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(.horizontal, 0)
            
            // Swap Button
            Button("Swap Units") {
                let temp = fromUnit
                fromUnit = toUnit
                toUnit = temp
                convertUnits()
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadState()
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: screenName
            ])
        }
        .onDisappear {
            saveState()
        }
    }
    
    private func convertUnits() {
        guard let inputDouble = Double(inputValue),
              let fromUnitData = selectedCategory.units.first(where: { $0.name == fromUnit }),
              let toUnitData = selectedCategory.units.first(where: { $0.name == toUnit }) else {
            outputValue = ""
            return
        }
        
        let result: Double
        
        if selectedCategory == .temperature {
            result = convertTemperature(inputDouble, from: fromUnitData.name, to: toUnitData.name)
        } else {
            // Convert to base unit first, then to target unit
            let baseValue = inputDouble * fromUnitData.toBaseMultiplier
            result = baseValue / toUnitData.toBaseMultiplier
        }
        
        // Format the result properly, removing only trailing zeros
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        outputValue = formatter.string(from: NSNumber(value: result)) ?? "0"
    }
    
    private func convertTemperature(_ value: Double, from fromUnit: String, to toUnit: String) -> Double {
        // Convert from source to Celsius first
        let celsius: Double
        switch fromUnit {
        case "celsius":
            celsius = value
        case "fahrenheit":
            celsius = (value - 32) * 5/9
        case "kelvin":
            celsius = value - 273.15
        default:
            celsius = value
        }
        
        // Convert from Celsius to target unit
        switch toUnit {
        case "celsius":
            return celsius
        case "fahrenheit":
            return celsius * 9/5 + 32
        case "kelvin":
            return celsius + 273.15
        default:
            return celsius
        }
    }
    
    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(selectedCategory.title, forKey: "UnitConverter.selectedCategory")
        defaults.set(fromUnit, forKey: "UnitConverter.fromUnit")
        defaults.set(toUnit, forKey: "UnitConverter.toUnit")
        defaults.set(inputValue, forKey: "UnitConverter.inputValue")
        defaults.set(outputValue, forKey: "UnitConverter.outputValue")
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        
        if let categoryTitle = defaults.string(forKey: "UnitConverter.selectedCategory") {
            selectedCategory = UnitCategory.allCases.first { $0.title == categoryTitle } ?? .data
        }
        
        fromUnit = defaults.string(forKey: "UnitConverter.fromUnit") ?? ""
        toUnit = defaults.string(forKey: "UnitConverter.toUnit") ?? ""
        inputValue = defaults.string(forKey: "UnitConverter.inputValue") ?? ""
        outputValue = defaults.string(forKey: "UnitConverter.outputValue") ?? ""
        
        // If no saved units, set defaults for current category
        if fromUnit.isEmpty || toUnit.isEmpty {
            let units = selectedCategory.units
            fromUnit = units.first?.name ?? ""
            toUnit = units.count > 1 ? units[1].name : units.first?.name ?? ""
        }
        
        // If we have input value, trigger conversion
        if !inputValue.isEmpty {
            convertUnits()
        }
    }
}

enum UnitCategory: String, CaseIterable {
    case data, time, length, weight, temperature, area, volume
    
    var title: String {
        switch self {
        case .data: return "Data"
        case .time: return "Time"
        case .length: return "Length"
        case .weight: return "Weight"
        case .temperature: return "Temperature"
        case .area: return "Area"
        case .volume: return "Volume"
        }
    }
    
    var units: [UnitData] {
        switch self {
        case .data:
            return [
                UnitData(name: "bit", symbol: "bit", toBaseMultiplier: 0.125),
                UnitData(name: "byte", symbol: "Byte", toBaseMultiplier: 1.0),
                UnitData(name: "kilobyte", symbol: "KB", toBaseMultiplier: 1024.0),
                UnitData(name: "megabyte", symbol: "MB", toBaseMultiplier: 1024.0 * 1024.0),
                UnitData(name: "gigabyte", symbol: "GB", toBaseMultiplier: 1024.0 * 1024.0 * 1024.0),
                UnitData(name: "terabyte", symbol: "TB", toBaseMultiplier: 1024.0 * 1024.0 * 1024.0 * 1024.0),
                UnitData(name: "petabyte", symbol: "PB", toBaseMultiplier: 1024.0 * 1024.0 * 1024.0 * 1024.0 * 1024.0)
            ]
        case .time:
            return [
                UnitData(name: "nanosecond", symbol: "ns", toBaseMultiplier: 0.000000001),
                UnitData(name: "microsecond", symbol: "μs", toBaseMultiplier: 0.000001),
                UnitData(name: "millisecond", symbol: "ms", toBaseMultiplier: 0.001),
                UnitData(name: "second", symbol: "s", toBaseMultiplier: 1.0),
                UnitData(name: "minute", symbol: "min", toBaseMultiplier: 60.0),
                UnitData(name: "hour", symbol: "hr", toBaseMultiplier: 3600.0),
                UnitData(name: "day", symbol: "day", toBaseMultiplier: 86400.0),
                UnitData(name: "week", symbol: "week", toBaseMultiplier: 604800.0),
                UnitData(name: "month", symbol: "month", toBaseMultiplier: 2592000.0), // 30 days average
                UnitData(name: "year", symbol: "year", toBaseMultiplier: 31536000.0) // 365 days
            ]
        case .length:
            return [
                UnitData(name: "millimeter", symbol: "mm", toBaseMultiplier: 0.001),
                UnitData(name: "centimeter", symbol: "cm", toBaseMultiplier: 0.01),
                UnitData(name: "meter", symbol: "m", toBaseMultiplier: 1.0),
                UnitData(name: "kilometer", symbol: "km", toBaseMultiplier: 1000.0),
                UnitData(name: "inch", symbol: "in", toBaseMultiplier: 0.0254),
                UnitData(name: "foot", symbol: "ft", toBaseMultiplier: 0.3048),
                UnitData(name: "yard", symbol: "yd", toBaseMultiplier: 0.9144),
                UnitData(name: "mile", symbol: "mi", toBaseMultiplier: 1609.344)
            ]
        case .weight:
            return [
                UnitData(name: "milligram", symbol: "mg", toBaseMultiplier: 0.001),
                UnitData(name: "gram", symbol: "g", toBaseMultiplier: 1.0),
                UnitData(name: "kilogram", symbol: "kg", toBaseMultiplier: 1000.0),
                UnitData(name: "ounce", symbol: "oz", toBaseMultiplier: 28.3495),
                UnitData(name: "pound", symbol: "lb", toBaseMultiplier: 453.592),
                UnitData(name: "ton", symbol: "ton", toBaseMultiplier: 1000000.0)
            ]
        case .temperature:
            return [
                UnitData(name: "celsius", symbol: "°C", toBaseMultiplier: 1.0),
                UnitData(name: "fahrenheit", symbol: "°F", toBaseMultiplier: 1.0),
                UnitData(name: "kelvin", symbol: "K", toBaseMultiplier: 1.0)
            ]
        case .area:
            return [
                UnitData(name: "square_meter", symbol: "m²", toBaseMultiplier: 1.0),
                UnitData(name: "square_foot", symbol: "ft²", toBaseMultiplier: 0.092903),
                UnitData(name: "acre", symbol: "ac", toBaseMultiplier: 4046.86),
                UnitData(name: "hectare", symbol: "ha", toBaseMultiplier: 10000.0)
            ]
        case .volume:
            return [
                UnitData(name: "milliliter", symbol: "mL", toBaseMultiplier: 0.001),
                UnitData(name: "liter", symbol: "L", toBaseMultiplier: 1.0),
                UnitData(name: "gallon", symbol: "gal", toBaseMultiplier: 3.78541),
                UnitData(name: "quart", symbol: "qt", toBaseMultiplier: 0.946353),
                UnitData(name: "pint", symbol: "pt", toBaseMultiplier: 0.473176),
                UnitData(name: "cup", symbol: "cup", toBaseMultiplier: 0.236588)
            ]
        }
    }
}

struct UnitData {
    let name: String
    let symbol: String
    let toBaseMultiplier: Double
}

#Preview {
    UnitConverterView()
}