import SwiftUI
import Foundation

struct SSIDMapping: Identifiable, Codable {
    let id = UUID()
    var location: String
    var ssid: String
}

struct LocationChangerSettings: Codable {
    var ssidMappings: [SSIDMapping]
    var enableNotifications: Bool
    var logLevel: String
    var fallbackLocation: String
}

class LocationChangerConfig: ObservableObject {
    @Published var settings = LocationChangerSettings(
        ssidMappings: [],
        enableNotifications: true,
        logLevel: "info",
        fallbackLocation: "Automatic"
    )
    
    private let configPath = "/usr/local/bin/locationchanger.conf"
    private let settingsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("LocationChanger/settings.json")
    
    init() {
        loadSettings()
        loadSSIDMappings()
    }
    
    func loadSettings() {
        guard let settingsPath = settingsPath,
              FileManager.default.fileExists(atPath: settingsPath.path) else { return }
        
        do {
            let data = try Data(contentsOf: settingsPath)
            let loadedSettings = try JSONDecoder().decode(LocationChangerSettings.self, from: data)
            self.settings = loadedSettings
        } catch {
            print("Error loading settings: \(error)")
        }
    }
    
    func saveSettings() {
        guard let settingsPath = settingsPath else { return }
        
        do {
            let data = try JSONEncoder().encode(settings)
            try FileManager.default.createDirectory(at: settingsPath.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: settingsPath)
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    func loadSSIDMappings() {
        guard FileManager.default.fileExists(atPath: configPath) else { return }
        
        do {
            let content = try String(contentsOfFile: configPath)
            let lines = content.components(separatedBy: .newlines)
            
            var mappings: [SSIDMapping] = []
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                
                let components = trimmed.components(separatedBy: .whitespaces)
                if components.count >= 2 {
                    let location = components[0]
                    let ssid = components.dropFirst().joined(separator: " ").trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    mappings.append(SSIDMapping(location: location, ssid: ssid))
                }
            }
            
            settings.ssidMappings = mappings
        } catch {
            print("Error loading SSID mappings: \(error)")
        }
    }
    
    func saveSSIDMappings() {
        var content = "# LocationChanger Configuration\n"
        content += "# Format: location_name \"WiFi SSID\"\n"
        content += "# Lines starting with # are comments\n\n"
        
        for mapping in settings.ssidMappings {
            let quotedSSID = mapping.ssid.contains(" ") ? "\"\(mapping.ssid)\"" : mapping.ssid
            content += "\(mapping.location) \(quotedSSID)\n"
        }
        
        do {
            try content.write(toFile: configPath, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving SSID mappings: \(error)")
        }
    }
    
    func getCurrentSSID() -> String {
        let task = Process()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPAirPortDataType"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let lines = output.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if line.contains("Current Network") && index + 1 < lines.count {
                    let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
                    return nextLine.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {
            print("Error getting current SSID: \(error)")
        }
        
        return "Unknown"
    }
    
    func getAvailableLocations() -> [String] {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listlocations"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        } catch {
            print("Error getting available locations: \(error)")
            return ["Automatic", "Home", "Work"]
        }
    }
}

struct ContentView: View {
    @StateObject private var config = LocationChangerConfig()
    @State private var showingAddMapping = false
    @State private var newLocation = ""
    @State private var newSSID = ""
    @State private var currentSSID = "Unknown"
    @State private var availableLocations: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "wifi.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Location Changer Config")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Configure Wi-Fi to Location mappings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Current Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Status")
                        .font(.headline)
                    
                    HStack {
                        Text("Current Wi-Fi:")
                        Spacer()
                        Text(currentSSID)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Mappings:")
                        Spacer()
                        Text("\(config.settings.ssidMappings.count)")
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                // SSID Mappings
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("SSID Mappings")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddMapping = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if config.settings.ssidMappings.isEmpty {
                        Text("No mappings configured")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(config.settings.ssidMappings) { mapping in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mapping.location)
                                        .fontWeight(.medium)
                                    Text(mapping.ssid)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    config.settings.ssidMappings.removeAll { $0.id == mapping.id }
                                    config.saveSSIDMappings()
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                // Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Settings")
                        .font(.headline)
                    
                    Toggle("Enable Notifications", isOn: $config.settings.enableNotifications)
                        .onChange(of: config.settings.enableNotifications) { _ in
                            config.saveSettings()
                        }
                    
                    HStack {
                        Text("Fallback Location:")
                        Spacer()
                        Picker("Fallback Location", selection: $config.settings.fallbackLocation) {
                            ForEach(availableLocations, id: \.self) { location in
                                Text(location).tag(location)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                        .onChange(of: config.settings.fallbackLocation) { _ in
                            config.saveSettings()
                        }
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button("Refresh SSID") {
                        currentSSID = config.getCurrentSSID()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save Configuration") {
                        config.saveSSIDMappings()
                        config.saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 500, height: 600)
            .onAppear {
                currentSSID = config.getCurrentSSID()
                availableLocations = config.getAvailableLocations()
            }
        }
        .sheet(isPresented: $showingAddMapping) {
            AddMappingView(
                newLocation: $newLocation,
                newSSID: $newSSID,
                availableLocations: availableLocations,
                currentSSID: currentSSID,
                onSave: {
                    let mapping = SSIDMapping(location: newLocation, ssid: newSSID)
                    config.settings.ssidMappings.append(mapping)
                    config.saveSSIDMappings()
                    newLocation = ""
                    newSSID = ""
                    showingAddMapping = false
                }
            )
        }
    }
}

struct AddMappingView: View {
    @Binding var newLocation: String
    @Binding var newSSID: String
    let availableLocations: [String]
    let currentSSID: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add SSID Mapping")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Location:")
                Picker("Location", selection: $newLocation) {
                    Text("Select Location").tag("")
                    ForEach(availableLocations, id: \.self) { location in
                        Text(location).tag(location)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Text("Wi-Fi SSID:")
                TextField("Enter SSID", text: $newSSID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !currentSSID.isEmpty && currentSSID != "Unknown" {
                    Button("Use Current SSID") {
                        newSSID = currentSSID
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newLocation.isEmpty || newSSID.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ContentView()
}
