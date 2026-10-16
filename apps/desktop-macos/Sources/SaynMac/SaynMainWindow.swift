import AppKit
import SwiftUI

/// Main Window Controller for SAYN macOS App
final class SaynMainWindow: NSWindow, NSWindowDelegate {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.delegate = self
        self.title = "SAYN — Voice Intelligence & Studio"
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.backgroundColor = NSColor(red: 250/255, green: 249/255, blue: 245/255, alpha: 1.0)
        self.minSize = NSSize(width: 960, height: 640)
        self.contentView = contentView
        self.center()
        self.setFrameAutosaveName("SaynMainWindowAutosave")
    }
    
    // When user clicks the red close button, hide the window instead of quitting
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.orderOut(nil)
        return false
    }
}

// MARK: - Navigation Tabs
enum SaynStudioTab: String, CaseIterable, Identifiable {
    case dictation = "Dictation"
    case notetaker = "Notetaker"
    case insights = "Insights"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    case style = "Style"
    case transforms = "Transforms"
    case scratchpad = "Scratchpad"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .dictation: return "mic.fill"
        case .notetaker: return "record.circle"
        case .insights: return "chart.bar.xaxis"
        case .dictionary: return "character.book.closed.fill"
        case .snippets: return "scissors"
        case .style: return "textformat"
        case .transforms: return "wand.and.stars"
        case .scratchpad: return "note.text"
        }
    }
}

// MARK: - Settings Modal Tabs
enum SaynSettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case system = "System"
    case notetaker = "Notetaker"
    case vibeCoding = "Vibe coding"
    case connectors = "Connectors"
    case mcp = "MCP"
    case account = "Account"
    case team = "Team"
    case billing = "Plans and Billing"
    case privacy = "Data and Privacy"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .system: return "display"
        case .notetaker: return "record.circle"
        case .vibeCoding: return "number"
        case .connectors: return "cable.connector"
        case .mcp: return "puzzlepiece.extension"
        case .account: return "person.crop.circle"
        case .team: return "person.2"
        case .billing: return "creditcard"
        case .privacy: return "shield.lefthalf.filled"
        }
    }
}

// MARK: - Main SwiftUI Studio View with 100% Real Persistent Data
struct SaynStudioView: View {
    @ObservedObject var waveformEngine: AudioWaveformEngine
    @ObservedObject var store = SaynStore.shared
    
    var onToggleDictation: () -> Void
    var onRefineText: (String, @escaping (String) -> Void) -> Void
    
    @State private var selectedTab: SaynStudioTab = .dictation
    @State private var isSidebarCollapsed: Bool = false
    @State private var showProfilePopover: Bool = false
    @State private var showSettingsModal: Bool = false
    @State private var activeSettingsTab: SaynSettingsTab = .general
    
    // Search & Filtering
    @State private var searchHistoryQuery: String = ""
    @State private var searchDictionaryQuery: String = ""
    @State private var isAddingNewWord: Bool = false
    @State private var newWordText: String = ""
    @State private var copiedId: UUID? = nil
    
    // Account edit fields
    @State private var editFirstName: String = ""
    @State private var editLastName: String = ""
    @State private var editPhone: String = ""
    @State private var editWritingRole: String = ""
    @State private var editEmail: String = ""
    @State private var accountSavedNotice: Bool = false
    
    // Scratchpad
    @State private var scratchpadText: String = "Dictate or draft freely here. When done, you can apply a Transform or copy directly."
    @State private var activeStyleSubTab: String = "Auto cleanup"
    
    // Color Palette Tokens (Official SAYN Deep Maroon #6F1025 & Warm Cream #F5EBDD)
    private let bgCanvas = Color(red: 250/255, green: 249/255, blue: 245/255)
    private let cardWhite = Color.white
    private let surfaceBeige = Color(red: 247/255, green: 245/255, blue: 238/255)
    private let textDark = Color(red: 26/255, green: 26/255, blue: 26/255)
    private let textMuted = Color(red: 112/255, green: 110/255, blue: 107/255)
    private let accentTeal = Color(red: 111/255, green: 16/255, blue: 37/255)    // #6F1025 Deep Maroon Primary
    private let accentCyan = Color(red: 168/255, green: 50/255, blue: 73/255)    // #A83249 Soft Rose-Maroon
    private let accentAmber = Color(red: 143/255, green: 24/255, blue: 53/255)   // #8F1835 Mid Maroon Accent
    private let borderDivider = Color(red: 235/255, green: 232/255, blue: 223/255)
    
    var body: some View {
        ZStack {
            bgCanvas.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar / Chrome Toolbar
                topToolbar
                
                Divider()
                    .background(borderDivider)
                
                // Main Workspace: Sidebar + Content Canvas
                HStack(spacing: 0) {
                    if !isSidebarCollapsed {
                        sidebarView
                            .frame(width: 240)
                            .background(bgCanvas)
                        
                        Divider()
                            .background(borderDivider)
                    }
                    
                    // Center Content Router
                    ZStack {
                        switch selectedTab {
                        case .dictation:
                            dictationFeedView
                        case .notetaker:
                            notetakerView
                        case .insights:
                            insightsView
                        case .dictionary:
                            dictionaryView
                        case .snippets:
                            snippetsView
                        case .style:
                            styleView
                        case .transforms:
                            transformsView
                        case .scratchpad:
                            scratchpadView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(bgCanvas)
                }
            }
            
            // Floating Settings Modal Sheet
            if showSettingsModal {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            showSettingsModal = false
                        }
                    }
                
                settingsModalView
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .onAppear {
            editFirstName = store.firstName
            editLastName = store.lastName
            editEmail = store.email
        }
    }
    
    // MARK: - Top Chrome Toolbar
    private var topToolbar: some View {
        HStack(spacing: 12) {
            // Sidebar Toggle
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    isSidebarCollapsed.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textDark)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.04)))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Brand Logo & Wordmark (Official SAYN Deep Maroon Lockup)
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(accentTeal)
                        .frame(width: 26, height: 26)
                    HStack(spacing: 1.5) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 245/255, green: 235/255, blue: 221/255))
                            .frame(width: 2.2, height: 9)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 245/255, green: 235/255, blue: 221/255))
                            .frame(width: 2.2, height: 14)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 245/255, green: 235/255, blue: 221/255))
                            .frame(width: 2.2, height: 10)
                    }
                }
                
                Text("SAYN")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(textDark)
            }
            
            Spacer()
            
            // Notification Bell
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textDark.opacity(0.8))
                    .padding(6)
            }
            .buttonStyle(PlainButtonStyle())
            
            // User Avatar Popover Button (Real Monogram from store.firstName)
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    showProfilePopover.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(accentTeal)
                        .frame(width: 28, height: 28)
                    
                    Text(String(store.firstName.prefix(1)).uppercased())
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showProfilePopover, arrowEdge: .bottom) {
                profilePopoverCard
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(bgCanvas)
    }
    
    // MARK: - Profile Popover Card
    private var profilePopoverCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Profile Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accentTeal)
                        .frame(width: 38, height: 38)
                    Text(String(store.firstName.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(store.firstName) \(store.lastName)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                    Text(store.email)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(textMuted)
                }
            }
            
            Divider()
                .background(borderDivider)
            
            // Free Tier / Quota Card
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("You are on SAYN Free")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textDark)
                    Text("0 words left this week")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(textMuted)
                }
                Spacer()
                Button(action: {}) {
                    Text("Get SAYN Pro")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(accentTeal))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(borderDivider)
            
            // Referral Card
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get a free month of SAYN Pro")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textDark)
                    Text("Refer friends, earn rewards")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(textMuted)
                }
                Spacer()
                Button(action: {}) {
                    Text("Refer a friend")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 8).fill(surfaceBeige))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(borderDivider)
            
            // Manage Account Link
            Button(action: {
                showProfilePopover = false
                editFirstName = store.firstName
                editLastName = store.lastName
                editPhone = store.phone
                editWritingRole = store.writingRole
                editEmail = store.email
                activeSettingsTab = .account
                showSettingsModal = true
            }) {
                Text("Manage account")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textDark)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .frame(width: 300)
        .background(cardWhite)
    }
    
    // MARK: - Left Sidebar Navigation
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(SaynStudioTab.allCases) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 15.5, weight: selectedTab == tab ? .bold : .medium))
                                    .frame(width: 22)
                                    .foregroundColor(selectedTab == tab ? accentTeal : textDark.opacity(0.75))
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 14.5, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                                    .foregroundColor(selectedTab == tab ? accentTeal : textDark)
                                
                                Spacer()
                                
                                if tab == .notetaker {
                                    Text("New!")
                                        .font(.system(size: 10.5, weight: .bold))
                                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2.5)
                                        .background(Capsule().fill(accentTeal))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedTab == tab ? accentTeal.opacity(0.09) : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 10)
                
                Spacer(minLength: 20)
                
                // Explore Notetaker Promo Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "person.crop.rectangle.stack")
                            .font(.system(size: 26))
                            .foregroundColor(accentTeal)
                        Spacer()
                    }
                    Text("Explore Notetaker")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                    Text("Get a transcript, summary, and action items for every meeting")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(textMuted)
                        .lineSpacing(2)
                    
                    Button(action: { selectedTab = .notetaker }) {
                        Text("Check it out")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(accentTeal))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(accentTeal.opacity(0.08)))
                .padding(.horizontal, 10)
            }
            
            Divider()
                .background(borderDivider)
                .padding(.vertical, 6)
            
            // Bottom Utility Strip
            VStack(alignment: .leading, spacing: 3) {
                sidebarUtilityButton(title: "Invite your team", icon: "person.2") {
                    activeSettingsTab = .team
                    showSettingsModal = true
                }
                sidebarUtilityButton(title: "Get a free month", icon: "gift") {
                    showProfilePopover = true
                }
                sidebarUtilityButton(title: "Settings", icon: "gearshape") {
                    activeSettingsTab = .general
                    showSettingsModal = true
                }
                sidebarUtilityButton(title: "Help", icon: "questionmark.circle") {}
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 10)
    }
    
    private func sidebarUtilityButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundColor(textMuted)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textDark.opacity(0.85))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.clear))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 1. Dictation View (Connected to Real SaynStore)
    private var dictationFeedView: some View {
        HStack(alignment: .top, spacing: 20) {
            // Main Feed Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Personalized Welcome Header
                    Text("Welcome back, \(store.firstName)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                    
                    // Transform Hero Banner
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 42/255, green: 14/255, blue: 21/255), Color(red: 16/255, green: 7/255, blue: 9/255)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Transform works anywhere you write")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                                
                                Text("Apply a Transform to rewrite, clean up, or restructure text after you dictate.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 214/255, green: 199/255, blue: 178/255))
                                    .lineLimit(2)
                                
                                HStack(spacing: 12) {
                                    Button(action: { selectedTab = .transforms }) {
                                        Text("Try it out")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 16/255, green: 7/255, blue: 9/255))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(Color(red: 245/255, green: 235/255, blue: 221/255)))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: { selectedTab = .transforms }) {
                                        Text("How it works")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255).opacity(0.85))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.top, 4)
                            }
                            
                            Spacer()
                            
                            // Floating App Badges
                            HStack(spacing: -8) {
                                ForEach(["bubble.left.and.bubble.right.fill", "envelope.fill", "doc.text.fill", "message.fill"], id: \.self) { sym in
                                    ZStack {
                                        Circle()
                                            .fill(surfaceBeige)
                                            .frame(width: 32, height: 32)
                                        Image(systemName: sym)
                                            .font(.system(size: 14))
                                            .foregroundColor(accentTeal)
                                    }
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                }
                            }
                        }
                        .padding(20)
                    }
                    .frame(height: 140)
                    
                    // TODAY Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("TODAY")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(textMuted)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 12))
                                    .foregroundColor(textMuted)
                                
                                TextField("Search dictations...", text: $searchHistoryQuery)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 12))
                                    .frame(width: 140)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                        }
                        
                        // Real Dictation Cards from SaynStore
                        let filteredHistory = store.history.filter {
                            searchHistoryQuery.isEmpty || $0.text.localizedCaseInsensitiveContains(searchHistoryQuery)
                        }
                        
                        if filteredHistory.isEmpty {
                            Text("No dictations found. Press Fn or Option+Space to speak!")
                                .font(.system(size: 13))
                                .foregroundColor(textMuted)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(filteredHistory) { item in
                                dictationItemRow(item: item)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity)
            
            // Right Stats Rail (Real Dynamic Statistics)
            VStack(alignment: .leading, spacing: 16) {
                // Main Stats Card
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Double(store.totalWordsDictated) / 1000.0, specifier: "%.1f")K")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        Text("total words")
                            .font(.system(size: 12))
                            .foregroundColor(textMuted)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.averageWPM)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        Text("wpm")
                            .font(.system(size: 12))
                            .foregroundColor(textMuted)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(store.currentDayStreak)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        Text("day streak")
                            .font(.system(size: 12))
                            .foregroundColor(textMuted)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(surfaceBeige))
                
                // Quota Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("0 words left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentTeal)
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Text("You've hit your weekly dictation limit. Resets Sunday, 12 a.m. PT.")
                        .font(.system(size: 11))
                        .foregroundColor(textMuted)
                    
                    Button(action: {}) {
                        Text("Upgrade to Pro")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(accentTeal))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(surfaceBeige))
                
                // Voice Profile Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Voice Profile Unlocked!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(textDark)
                        Spacer()
                    }
                    Text("Discover your unique insights")
                        .font(.system(size: 11))
                        .foregroundColor(textMuted)
                    
                    Button(action: { selectedTab = .insights }) {
                        Text("Create report")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(accentTeal))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(surfaceBeige))
            }
            .frame(width: 240)
            .padding(.trailing, 24)
            .padding(.top, 24)
        }
    }
    
    // MARK: - Dictation Item Row (with REAL Audio Playback, Copy, and Delete)
    private func dictationItemRow(item: DictationEntry) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(item.timeFormatted)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(textMuted)
                .frame(width: 55, alignment: .leading)
            
            Text(item.text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(textDark)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // REAL Audio Playback Action
                Button(action: {
                    store.playAudio(for: item)
                }) {
                    Image(systemName: store.playingEntryId == item.id ? "stop.fill" : "play.fill")
                        .font(.system(size: 11))
                        .foregroundColor(store.playingEntryId == item.id ? accentTeal : textMuted)
                }
                .buttonStyle(PlainButtonStyle())
                
                // REAL Copy Action
                Button(action: {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(item.text, forType: .string)
                    withAnimation { copiedId = item.id }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if copiedId == item.id { copiedId = nil }
                    }
                }) {
                    Image(systemName: copiedId == item.id ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(copiedId == item.id ? Color.green : textMuted)
                }
                .buttonStyle(PlainButtonStyle())
                
                // REAL Toggle Flag Action
                Button(action: {
                    store.toggleFlag(id: item.id)
                }) {
                    Image(systemName: item.isFlagged ? "flag.fill" : "flag")
                        .font(.system(size: 11))
                        .foregroundColor(item.isFlagged ? accentAmber : textMuted)
                }
                .buttonStyle(PlainButtonStyle())
                
                // REAL Delete & Actions Menu
                Menu {
                    Button("Copy Text") {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(item.text, forType: .string)
                    }
                    Button("Play Audio Recording") {
                        store.playAudio(for: item)
                    }
                    Button("Add to Custom Dictionary") {
                        store.addDictionaryWord(item.text)
                    }
                    Divider()
                    Button("Delete Entry") {
                        store.deleteEntry(id: item.id)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundColor(textMuted)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 20)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 10).fill(cardWhite))
    }
    
    // MARK: - 2. Insights Dashboard View
    private var insightsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Top Header with Share Badge
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Insights")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        
                        HStack(spacing: 18) {
                            Text("Your usage")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(textDark)
                                .overlay(Rectangle().frame(height: 2).offset(y: 12).foregroundColor(textDark), alignment: .bottom)
                            
                            Text("Your voice")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(textMuted)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // Share Circular Badge
                    ZStack {
                        Circle()
                            .stroke(borderDivider, lineWidth: 1)
                            .frame(width: 48, height: 48)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textDark)
                    }
                }
                
                // Top Row Cards: Speedometer, Fixes, Total Words
                HStack(alignment: .top, spacing: 16) {
                    // Card 1: Speedometer WPM Gauge
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(store.averageWPM)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        
                        Text("WORDS PER MINUTE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textMuted)
                        
                        // Semicircular Arc Gauge
                        ZStack {
                            Circle()
                                .trim(from: 0.0, to: 0.5)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(180))
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(min(0.5, Double(store.averageWPM) / 300.0)))
                                .stroke(accentTeal, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(180))
                            
                            VStack(spacing: 2) {
                                Text("Top")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(textMuted)
                                Text("0.3%")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(textDark)
                            }
                            .offset(y: -14)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
                    
                    // Card 2: Fixes Counter
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1,688")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        Text("FIXES MADE BY SAYN")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textMuted)
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("1,095")
                                    .font(.system(size: 14, weight: .bold))
                                Text("words corrected")
                                    .font(.system(size: 12))
                                    .foregroundColor(textMuted)
                            }
                            HStack {
                                Text("593")
                                    .font(.system(size: 14, weight: .bold))
                                Text("dictionary fixes")
                                    .font(.system(size: 12))
                                    .foregroundColor(textMuted)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
                    
                    // Card 3: Total Words Dictated
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(store.totalWordsDictated)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(textDark)
                            Spacer()
                            Text("↗ 290% this month")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green.opacity(0.12)))
                        }
                        Text("TOTAL WORDS DICTATED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(textMuted)
                        
                        Text("You've written 2 college essays!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textDark)
                        
                        Spacer()
                        
                        // Desktop vs Mobile Multi-Color Bar
                        HStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "desktopcomputer")
                                    .font(.system(size: 10))
                                Text("Desktop")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accentTeal))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "iphone")
                                    .font(.system(size: 10))
                                Text("Mobile")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(accentTeal)
                            .frame(width: 80)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(accentCyan.opacity(0.3)))
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
                }
                
                // Bottom Row Cards: Desktop Usage Breakdown + Activity Streak Heatmap
                HStack(alignment: .top, spacing: 16) {
                    // Desktop Usage
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Desktop usage")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(textDark)
                            Spacer()
                            Text("TOTAL APPS USED | 28")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(textMuted)
                        }
                        
                        telemetryBar(percent: "80%", label: "315 OTHER TASKS", icon: "infinity", color: accentTeal)
                        telemetryBar(percent: "10%", label: "54 AI PROMPTS", icon: "cpu", color: accentCyan)
                        telemetryBar(percent: "10%", label: "131 PERSONAL MESSAGES", icon: "bubble.left", color: accentCyan)
                        telemetryBar(percent: "0%", label: "2 WORK MESSAGES", icon: "bubble.right", color: textMuted.opacity(0.3))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
                    
                    // GitHub-style Streak Heatmap
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(store.currentDayStreak) day streak")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(textDark)
                            Spacer()
                            Text("LONGEST STREAK | 32 DAYS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(textMuted)
                        }
                        
                        // Heatmap Matrix
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                ForEach(["Jul", "Aug", "Sep", "Oct"], id: \.self) { mo in
                                    Text(mo)
                                        .font(.system(size: 10))
                                        .foregroundColor(textMuted)
                                    Spacer()
                                }
                            }
                            
                            // 7 Weekday Rows x 14 Weeks
                            ForEach(0..<7, id: \.self) { row in
                                HStack(spacing: 4) {
                                    ForEach(0..<14, id: \.self) { col in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(heatmapColor(row: row, col: col))
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                (col >= 11 && row <= 4) ?
                                                RoundedRectangle(cornerRadius: 2).stroke(accentTeal, lineWidth: 1) : nil
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                        
                        HStack {
                            Text("Less")
                                .font(.system(size: 10))
                                .foregroundColor(textMuted)
                            ForEach(0..<4, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(accentTeal.opacity(Double(i + 1) * 0.25))
                                    .frame(width: 10, height: 10)
                            }
                            Text("More")
                                .font(.system(size: 10))
                                .foregroundColor(textMuted)
                            
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(accentTeal, lineWidth: 1)
                                .frame(width: 10, height: 10)
                            Text("Current streak")
                                .font(.system(size: 10))
                                .foregroundColor(textMuted)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
                }
            }
            .padding(24)
        }
    }
    
    private func telemetryBar(percent: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(textMuted)
                .frame(width: 16)
            
            Text(percent)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color == textMuted.opacity(0.3) ? textMuted : .white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(color))
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textDark)
            
            Spacer()
        }
    }
    
    private func heatmapColor(row: Int, col: Int) -> Color {
        if col >= 11 {
            return accentTeal.opacity(0.75)
        } else if (row + col) % 3 == 0 {
            return accentTeal.opacity(0.35)
        } else if (row + col) % 2 == 0 {
            return accentTeal.opacity(0.18)
        } else {
            return Color(red: 235/255, green: 232/255, blue: 223/255)
        }
    }
    
    // MARK: - 3. Dictionary View (Connected to Real SaynStore)
    private var dictionaryView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Dictionary")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation { isAddingNewWord.toggle() }
                    }) {
                        Text(isAddingNewWord ? "Close" : "Add new")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Add New Word Input Bar
                if isAddingNewWord {
                    HStack {
                        TextField("Enter personal term, name, or jargon...", text: $newWordText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(surfaceBeige))
                        
                        Button(action: {
                            if !newWordText.isEmpty {
                                store.addDictionaryWord(newWordText)
                                newWordText = ""
                                isAddingNewWord = false
                            }
                        }) {
                            Text("Save Term")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(accentTeal))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(cardWhite))
                }
                
                // Tabs: All, Personal, Shared
                HStack(spacing: 20) {
                    Text("All")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(textDark)
                        .overlay(Rectangle().frame(height: 2).offset(y: 12).foregroundColor(textDark), alignment: .bottom)
                    Text("Personal")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textMuted)
                    Text("Shared with team")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textMuted)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                        TextField("Search...", text: $searchDictionaryQuery)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 12))
                            .frame(width: 100)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                }
                .padding(.top, 4)
                
                // Hero Banner
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 80/255, green: 50/255, blue: 40/255), Color(red: 45/255, green: 30/255, blue: 25/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SAYN spells the way you do.")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Correct a spelling once or add it here manually, so your personal terms, company jargon, or uncommon names are spelled right in both dictations and meeting notes.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.85))
                        
                        HStack(spacing: 8) {
                            Button(action: { isAddingNewWord = true }) {
                                Text("+ Add new word")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            ForEach(["SAYN Voice", "Mohammed Maaz", "SwiftUI", "TypeScript", "Groq LPU"], id: \.self) { chip in
                                Button(action: { store.addDictionaryWord(chip) }) {
                                    Text(chip)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.white.opacity(0.18)))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
                
                // Real Dictionary Entries Table from SaynStore
                let filteredWords = store.dictionaryWords.filter {
                    searchDictionaryQuery.isEmpty || $0.localizedCaseInsensitiveContains(searchDictionaryQuery)
                }
                
                VStack(spacing: 0) {
                    ForEach(filteredWords, id: \.self) { word in
                        HStack {
                            Text(word)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(textDark)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    // Set as text snippet or copy
                                    let pb = NSPasteboard.general
                                    pb.clearContents()
                                    pb.setString(word, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundColor(textMuted)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    store.deleteDictionaryWord(word)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(textMuted)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Image(systemName: "star")
                                    .font(.system(size: 11))
                                    .foregroundColor(textMuted.opacity(0.6))
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        
                        Divider()
                            .background(borderDivider)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
            }
            .padding(24)
        }
    }
    
    // MARK: - 4. Style Engine View (Connected to SaynStore)
    private var styleView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Style")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(textDark)
                
                // Style Navigation Tabs
                HStack(spacing: 24) {
                    ForEach(["Personal messages", "Work messages", "Email", "Other", "Auto cleanup"], id: \.self) { t in
                        Button(action: { activeStyleSubTab = t }) {
                            Text(t)
                                .font(.system(size: 14, weight: activeStyleSubTab == t ? .bold : .medium))
                                .foregroundColor(activeStyleSubTab == t ? accentTeal : textMuted)
                                .overlay(
                                    activeStyleSubTab == t ?
                                    Rectangle().frame(height: 2.5).offset(y: 12).foregroundColor(accentTeal) : nil,
                                    alignment: .bottom
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if activeStyleSubTab == "Auto cleanup" {
                    // Auto Cleanup Screen
                    VStack(alignment: .leading, spacing: 16) {
                        // Hero Banner
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Auto Cleanup applies to all your dictations")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            Text("Choose the level of cleanup that's automatically applied every time, across all apps.")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.85))
                            Text("Note your original dictation is never lost. Just click the three dots next to a recent dictation in the Home tab and choose 'Undo AI edit.'")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color(red: 40/255, green: 50/255, blue: 50/255), Color(red: 20/255, green: 25/255, blue: 25/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        
                        // 3 Level Cards: None, Light, Medium (Saves to SaynStore)
                        HStack(alignment: .top, spacing: 16) {
                            cleanupLevelCard(
                                title: "None",
                                subtitle: "Transcribes exactly what you said, including mistakes",
                                example: "hey joey, we still on for coffee or? I think we maybe should leave earlier to make it there in time there might um be traffic. What are you thinking?",
                                isSelected: store.cleanupLevel == "None"
                            ) {
                                store.cleanupLevel = "None"
                                store.updateConfig()
                            }
                            
                            cleanupLevelCard(
                                title: "Light",
                                subtitle: "Cleans up filler words and grammar",
                                example: "Hey Joey, are we still on for coffee? I think we should leave earlier to make it there in time. There might be traffic. What are you thinking?",
                                isSelected: store.cleanupLevel == "Light"
                            ) {
                                store.cleanupLevel = "Light"
                                store.updateConfig()
                            }
                            
                            cleanupLevelCard(
                                title: "Medium",
                                subtitle: "Edits for clarity and conciseness",
                                example: "Hey Joey, are we still on for coffee? We should leave earlier; there might be traffic. What do you think?",
                                isSelected: store.cleanupLevel == "Medium"
                            ) {
                                store.cleanupLevel = "Medium"
                                store.updateConfig()
                            }
                        }
                    }
                } else if activeStyleSubTab == "Email" {
                    // Email Tones Screen (Saves to SaynStore)
                    VStack(alignment: .leading, spacing: 16) {
                        // Hero Banner with Email Icons
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("This style applies in all major email apps")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                Text("Style formatting only applies in English. More languages coming soon.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.85))
                            }
                            Spacer()
                            HStack(spacing: -6) {
                                ForEach(["envelope.fill", "paperplane.fill", "tray.fill"], id: \.self) { ic in
                                    ZStack {
                                        Circle()
                                            .fill(surfaceBeige)
                                            .frame(width: 32, height: 32)
                                        Image(systemName: ic)
                                            .font(.system(size: 13))
                                            .foregroundColor(accentTeal)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color(red: 45/255, green: 40/255, blue: 30/255), Color(red: 25/255, green: 20/255, blue: 18/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        
                        // 3 Email Cards: Formal, Casual, Excited!
                        HStack(alignment: .top, spacing: 16) {
                            emailToneCard(
                                title: "Formal.",
                                subtitle: "Caps + Punctuation",
                                greeting: "Hi Alex,\n\nIt was great talking with you today. Looking forward to our next chat.\n\nBest,\n\(store.firstName)",
                                isSelected: store.emailTone == "Formal"
                            ) {
                                store.emailTone = "Formal"
                                store.updateConfig()
                            }
                            
                            emailToneCard(
                                title: "Casual",
                                subtitle: "Caps + Less punctuation",
                                greeting: "Hi Alex, it was great talking with you today. Looking forward to our next chat.\n\nBest,\n\(store.firstName)",
                                isSelected: store.emailTone == "Casual"
                            ) {
                                store.emailTone = "Casual"
                                store.updateConfig()
                            }
                            
                            emailToneCard(
                                title: "Excited!",
                                subtitle: "More exclamations",
                                greeting: "Hi Alex,\n\nIt was great talking with you today. Looking forward to our next chat!\n\nBest,\n\(store.firstName)",
                                isSelected: store.emailTone == "Excited!"
                            ) {
                                store.emailTone = "Excited!"
                                store.updateConfig()
                            }
                        }
                    }
                } else {
                    Text("Select a category above to configure specialized tone rules.")
                        .font(.system(size: 13))
                        .foregroundColor(textMuted)
                        .padding(.top, 20)
                }
            }
            .padding(24)
        }
    }
    
    private func cleanupLevelCard(title: String, subtitle: String, example: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(textDark)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textMuted)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .topLeading)
                
                Text(example)
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundColor(textDark)
                    .lineSpacing(3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 250/255, green: 244/255, blue: 235/255)))
            }
            .padding(20)
            .frame(minHeight: 230, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? accentTeal : borderDivider, lineWidth: isSelected ? 2.5 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func emailToneCard(title: String, subtitle: String, greeting: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textDark)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textMuted)
                
                Divider()
                    .background(borderDivider)
                
                Text("To: Alex Doe")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textMuted)
                
                Text(greeting)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(textDark)
                    .lineSpacing(3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 250/255, green: 244/255, blue: 235/255)))
            }
            .padding(20)
            .frame(minHeight: 230, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? accentTeal : borderDivider, lineWidth: isSelected ? 2.5 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 5. Transforms View (Connected to SaynStore)
    private var transformsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Transforms")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        Text("Beta")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.black))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Toggle("Opt in", isOn: $store.transformsOptIn)
                            .toggleStyle(SwitchToggleStyle())
                            .onChange(of: store.transformsOptIn) { _ in store.updateConfig() }
                        
                        Text("⌥ O to view changes")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                }
                
                // Hero Banner
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 42/255, green: 14/255, blue: 21/255), Color(red: 16/255, green: 7/255, blue: 9/255)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transform works anywhere you write")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                            Text("Apply a Transform to rewrite, clean up, or restructure text after you dictate.")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 214/255, green: 199/255, blue: 178/255))
                        }
                        Spacer()
                    }
                    .padding(20)
                }
                .frame(height: 120)
                
                // Auto Apply Strip
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Apply After Dictation")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(textDark)
                        Text("Run a transform on everything you dictate, automatically.")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $store.selectedAutoTransform) {
                        Text("Polish").tag("Polish")
                        Text("Prompt Engineer").tag("Prompt Engineer")
                        Text("Casual").tag("Casual")
                    }
                    .frame(width: 130)
                    .onChange(of: store.selectedAutoTransform) { _ in store.updateConfig() }
                    
                    Toggle("", isOn: $store.autoApplyTransform)
                        .toggleStyle(SwitchToggleStyle())
                        .onChange(of: store.autoApplyTransform) { _ in store.updateConfig() }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
                
                // My Transforms Grid
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("My Transforms")
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundColor(textDark)
                        Spacer()
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Reset to defaults")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {}) {
                            Text("Create New")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack(spacing: 16) {
                        transformCard(shortcut: "⌥ 1", title: "Polish", desc: "Improve clarity and conciseness")
                        transformCard(shortcut: "⌥ 2", title: "Prompt Engineer", desc: "Constructs optimal prompts")
                        
                        // Create Your Own
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(surfaceBeige)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "plus")
                                    .font(.system(size: 13))
                                    .foregroundColor(textDark)
                            }
                            Text("Create your own")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(textDark)
                            Text("Upload your own prompt")
                                .font(.system(size: 11))
                                .foregroundColor(textMuted)
                            Spacer()
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 120)
                        .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
                    }
                }
            }
            .padding(24)
        }
    }
    
    private func transformCard(shortcut: String, title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(shortcut)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(surfaceBeige))
            
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(textDark)
            
            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(textMuted)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
    }
    
    // MARK: - 6. Notetaker View
    private var notetakerView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Notetaker")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(textDark)
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle")
                        Text("Start tutorial")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(surfaceBeige))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Meeting Detection & Transcription")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textDark)
                
                Text("SAYN automatically listens when you enter Zoom, Google Meet, or Teams, generating real-time transcription, summaries, and action items.")
                    .font(.system(size: 13))
                    .foregroundColor(textMuted)
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text("Connect Calendar")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        Text("Import from Otter or Granola")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(surfaceBeige))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
            
            Spacer()
        }
        .padding(24)
    }
    
    // MARK: - 7. Snippets View
    private var snippetsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Snippets")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(textDark)
            
            Text("Voice shortcuts that instantly expand into longer templates or phrases.")
                .font(.system(size: 13))
                .foregroundColor(textMuted)
            
            VStack(spacing: 0) {
                snippetRow(shortcut: "btw", expansion: "by the way")
                Divider().background(borderDivider)
                snippetRow(shortcut: "myemail", expansion: store.email)
                Divider().background(borderDivider)
                snippetRow(shortcut: "intro", expansion: "Hi, hope you are having a wonderful day. I wanted to reach out regarding...")
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
            
            Spacer()
        }
        .padding(24)
    }
    
    private func snippetRow(shortcut: String, expansion: String) -> some View {
        HStack {
            Text(shortcut)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(textDark)
                .frame(width: 100, alignment: .leading)
            
            Text("→")
                .foregroundColor(textMuted)
            
            Text(expansion)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textMuted)
            
            Spacer()
        }
        .padding(14)
    }
    
    // MARK: - 8. Scratchpad View
    private var scratchpadView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scratchpad")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(textDark)
                Spacer()
                
                Button(action: onToggleDictation) {
                    HStack(spacing: 6) {
                        Image(systemName: waveformEngine.isRecording ? "stop.fill" : "mic.fill")
                        Text(waveformEngine.isRecording ? "Stop Dictating" : "Dictate (Fn)")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(waveformEngine.isRecording ? Color.red : Color.black))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            TextEditor(text: $scratchpadText)
                .font(.system(size: 14, design: .rounded))
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
                .frame(maxHeight: .infinity)
        }
        .padding(24)
    }
    
    // MARK: - Settings Hub Modal Sheet
    private var settingsModalView: some View {
        HStack(spacing: 0) {
            // Left Settings Navigation
            VStack(alignment: .leading, spacing: 4) {
                Text("SETTINGS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(textMuted)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                
                ForEach([SaynSettingsTab.general, .system, .notetaker, .vibeCoding, .connectors, .mcp]) { tab in
                    settingsTabButton(tab: tab)
                }
                
                Text("ACCOUNT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(textMuted)
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                
                ForEach([SaynSettingsTab.account, .team, .billing, .privacy]) { tab in
                    settingsTabButton(tab: tab)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("SAYN Studio v2.4.0")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textMuted)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundColor(textMuted)
                }
                .padding(14)
            }
            .frame(width: 190)
            .background(surfaceBeige)
            
            Divider()
                .background(borderDivider)
            
            // Right Settings Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    switch activeSettingsTab {
                    case .general:
                        settingsGeneralContent
                    case .system:
                        settingsSystemContent
                    case .notetaker:
                        settingsNotetakerContent
                    case .vibeCoding:
                        settingsVibeCodingContent
                    case .account:
                        settingsAccountContent
                    case .privacy:
                        settingsPrivacyContent
                    default:
                        Text(activeSettingsTab.rawValue)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(textDark)
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cardWhite)
        }
        .frame(width: 720, height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderDivider, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 25, x: 0, y: 10)
    }
    
    private func settingsTabButton(tab: SaynSettingsTab) -> some View {
        Button(action: { activeSettingsTab = tab }) {
            HStack(spacing: 8) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 13))
                    .frame(width: 18)
                    .foregroundColor(activeSettingsTab == tab ? accentTeal : textMuted)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: activeSettingsTab == tab ? .bold : .regular))
                    .foregroundColor(activeSettingsTab == tab ? accentTeal : textDark.opacity(0.85))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(activeSettingsTab == tab ? cardWhite : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Settings Tab Contents
    private var settingsGeneralContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(textDark)
            
            VStack(spacing: 12) {
                settingsRow(title: "Shortcuts", desc: "Hold fn or press Option+Space to speak. Learn more →", buttonLabel: "Change") {}
                settingsRow(title: "Microphone", desc: "Auto-detect (MacBook Pro)", buttonLabel: "Change") {}
                settingsRow(title: "Dictation Languages", desc: "English · British · Urdu (اردو)", buttonLabel: "Change") {}
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Language")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textDark)
                        Text("Select your preferred SAYN Hub language")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Text("English ▾")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
            }
        }
    }
    
    private var settingsSystemContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(textDark)
            
            Text("App settings")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textMuted)
            
            VStack(spacing: 10) {
                settingsToggle(title: "Launch app at login", state: .constant(true))
                settingsToggle(title: "Show SAYN Voice Capsule at all times", state: .constant(true))
                settingsToggle(title: "Show app in dock", state: .constant(true))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            Text("Sound")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textMuted)
            
            VStack(spacing: 10) {
                settingsToggle(title: "Dictation and notification sounds", state: .constant(true))
                settingsToggle(title: "Mute all audio while dictating", state: .constant(false))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
        }
    }
    
    private var settingsNotetakerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Notetaker")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(textDark)
                Spacer()
                Text("Start tutorial")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
            }
            
            Text("Meeting detection")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textMuted)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notify before scheduled meetings start")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textDark)
                        Text("Choose when to get a heads-up before a meeting starts")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Text("15 sec ▾")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textDark)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(surfaceBeige))
                }
                Divider()
                settingsToggle(title: "Show your next meeting in the menu bar", state: .constant(true))
                Divider()
                settingsToggle(title: "Automatically detect any call", state: .constant(true))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
        }
    }
    
    private var settingsVibeCodingContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vibe coding")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(textDark)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Variable recognition (VS Code, Cursor, Windsurf)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text("Better understands variables in code. Learn more →")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Text("Set up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(textDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                }
                
                Divider()
                
                settingsToggle(title: "File Tagging in Chat (Cursor & Windsurf)\nTags files in your IDE (like index.tsx)", state: .constant(true))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
        }
    }
    
    // Real Persistent Account Settings
    private var settingsAccountContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(textDark)
            
            VStack(spacing: 12) {
                profileField(label: "First name", value: $editFirstName)
                profileField(label: "Last name", value: $editLastName)
                profileField(label: "Phone number", value: $editPhone)
                profileField(label: "Writing focus", value: $editWritingRole)
                profileField(label: "Email", value: $editEmail)
                
                HStack {
                    Text("Profile picture")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textDark)
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(accentTeal)
                            .frame(width: 32, height: 32)
                        Text(String(store.firstName.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            if accountSavedNotice {
                Text("✓ Changes saved to ~/.sayn/account.json")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.green)
            }
            
            HStack {
                Button(action: {}) {
                    Text("Sign out")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textDark)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Text("Delete account")
                        .font(.system(size: 12))
                        .foregroundColor(Color.red)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    store.updateAccount(
                        firstName: editFirstName,
                        lastName: editLastName,
                        phone: editPhone,
                        email: editEmail,
                        writingRole: editWritingRole
                    )
                    accountSavedNotice = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        accountSavedNotice = false
                        showSettingsModal = false
                    }
                }) {
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                        .padding(.horizontal, 18).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(accentTeal))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var settingsPrivacyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data and Privacy")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(textDark)
            
            VStack(spacing: 12) {
                settingsToggle(title: "Improve the model for everyone\nAllow data to evaluate and improve AI models", state: .constant(false))
                Divider()
                settingsToggle(title: "Dictation cloud storage\nStores your dictation data on servers", state: .constant(false))
                Divider()
                settingsToggle(title: "Context awareness\nUse limited text to spell names correctly", state: .constant(true))
                Divider()
                settingsToggle(title: "Show your public information\nLet contacts see public info like job title", state: .constant(true))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            HStack {
                Text("Local data storage")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textDark)
                Spacer()
                Text("Store data locally ▾")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textDark)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
            }
        }
    }
    
    private func settingsRow(title: String, desc: String, buttonLabel: String, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textDark)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(textMuted)
            }
            Spacer()
            Button(action: action) {
                Text(buttonLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(cardWhite))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
    }
    
    private func settingsToggle(title: String, state: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textDark)
            Spacer()
            Toggle("", isOn: state)
                .toggleStyle(SwitchToggleStyle())
        }
    }
    
    private func profileField(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textMuted)
                .frame(width: 90, alignment: .leading)
            TextField("", text: value)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textDark)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(cardWhite))
        }
    }
}
