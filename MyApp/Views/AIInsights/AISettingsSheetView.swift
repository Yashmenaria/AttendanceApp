import SwiftUI

struct AISettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var configManager = AIConfigManager.shared
    
    @State private var selectedProvider: AIProvider = .gemini
    @State private var geminiKey: String = ""
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var customKey: String = ""
    @State private var customURL: String = ""
    @State private var selectedModel: String = ""
    @State private var temperature: Double = 0.7
    @State private var isLiveAIEnabled: Bool = true
    
    @State private var isTestingConnection: Bool = false
    @State private var testResultMessage: String? = nil
    @State private var testResultSuccess: Bool = false
    @State private var showKey: Bool = false
    
    var onSaved: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Active Provider Selection
                Section {
                    Picker("AI Provider", selection: $selectedProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Label(provider.rawValue, systemImage: provider.icon)
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedProvider) { newProvider in
                        if !newProvider.supportedModels.contains(selectedModel) {
                            selectedModel = newProvider.defaultModel
                        }
                        testResultMessage = nil
                    }
                    
                    Toggle(isOn: $isLiveAIEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Live AI Cloud Inference")
                                .font(.system(size: 14, weight: .semibold))
                            Text("If disabled or offline, uses local on-device smart rule engine")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(AppTheme.primary)
                } header: {
                    Text("AI Engine Provider")
                } footer: {
                    Text("Switch between Google Gemini, OpenAI, Claude, or Local Heuristics at runtime.")
                }
                
                // Section 2: Model & Credentials
                if selectedProvider != .localHeuristic {
                    Section {
                        // Model Picker
                        Picker("Model", selection: $selectedModel) {
                            ForEach(selectedProvider.supportedModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        
                        // Custom Endpoint URL if applicable
                        if selectedProvider == .custom {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Endpoint Base URL")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                TextField("https://api.openai.com/v1", text: $customURL)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 13, design: .monospaced))
                            }
                        }
                        
                        // API Key Input
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(selectedProvider.rawValue) API Key")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { showKey.toggle() }) {
                                    Image(systemName: showKey ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                            
                            if showKey {
                                TextField(selectedProvider.keyPlaceholder, text: apiKeyBinding)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 13, design: .monospaced))
                            } else {
                                SecureField(selectedProvider.keyPlaceholder, text: apiKeyBinding)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 13, design: .monospaced))
                            }
                        }
                        
                        // Temperature slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Creativity (Temperature)")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text(String(format: "%.2f", temperature))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppTheme.primary)
                            }
                            Slider(value: $temperature, in: 0.0...1.0, step: 0.05)
                                .tint(AppTheme.primary)
                        }
                    } header: {
                        Text("\(selectedProvider.rawValue) Credentials & Settings")
                    } footer: {
                        Text("Keys are stored locally on your device in secure sandbox storage.")
                    }
                }
                
                // Section 3: Connection Testing & Diagnostics
                Section {
                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(AppTheme.aiAccent)
                            }
                            Text(isTestingConnection ? "Testing API Connection..." : "Test AI Connection")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                    }
                    .disabled(isTestingConnection)
                    
                    if let result = testResultMessage {
                        HStack(spacing: 8) {
                            Image(systemName: testResultSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(testResultSuccess ? AppTheme.success : AppTheme.danger)
                            Text(result)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Connection Verification")
                }
            }
            .navigationTitle("AI Engine Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                        onSaved?()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadCurrentConfiguration()
            }
        }
    }
    
    private var apiKeyBinding: Binding<String> {
        Binding<String>(
            get: {
                switch selectedProvider {
                case .gemini: return geminiKey
                case .openAI: return openAIKey
                case .anthropic: return anthropicKey
                case .custom: return customKey
                case .localHeuristic: return ""
                }
            },
            set: { newValue in
                switch selectedProvider {
                case .gemini: geminiKey = newValue
                case .openAI: openAIKey = newValue
                case .anthropic: anthropicKey = newValue
                case .custom: customKey = newValue
                case .localHeuristic: break
                }
            }
        )
    }
    
    private func loadCurrentConfiguration() {
        let current = configManager.config
        selectedProvider = current.activeProvider
        geminiKey = current.geminiAPIKey
        openAIKey = current.openAIAPIKey
        anthropicKey = current.anthropicAPIKey
        customKey = current.customAPIKey
        customURL = current.customBaseURL
        selectedModel = current.selectedModel
        temperature = current.temperature
        isLiveAIEnabled = current.isLiveAIEnabled
        
        if !selectedProvider.supportedModels.contains(selectedModel) {
            selectedModel = selectedProvider.defaultModel
        }
    }
    
    private func saveConfiguration() {
        var updated = configManager.config
        updated.activeProvider = selectedProvider
        updated.geminiAPIKey = geminiKey
        updated.openAIAPIKey = openAIKey
        updated.anthropicAPIKey = anthropicKey
        updated.customAPIKey = customKey
        updated.customBaseURL = customURL.isEmpty ? "https://api.openai.com/v1" : customURL
        updated.selectedModel = selectedModel
        updated.temperature = temperature
        updated.isLiveAIEnabled = isLiveAIEnabled
        
        configManager.config = updated
        HapticManager.shared.notification(type: .success)
    }
    
    private func testConnection() {
        saveConfiguration()
        isTestingConnection = true
        testResultMessage = nil
        
        Task {
            let (success, message) = await AIMultiProviderService.shared.testConnection(for: selectedProvider)
            await MainActor.run {
                self.isTestingConnection = false
                self.testResultSuccess = success
                self.testResultMessage = message
                if success {
                    HapticManager.shared.notification(type: .success)
                } else {
                    HapticManager.shared.notification(type: .warning)
                }
            }
        }
    }
}

#Preview {
    AISettingsSheetView()
}
