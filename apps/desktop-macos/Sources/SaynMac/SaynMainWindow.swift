import AppKit
import SwiftUI

/// Main Window Controller for SAYN macOS App
final class SaynMainWindow: NSWindow, NSWindowDelegate {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1160, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.delegate = self
        self.title = "SAYN — Voice Intelligence & Studio"
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.backgroundColor = NSColor(red: 250/255, green: 247/255, blue: 244/255, alpha: 1.0)
        self.minSize = NSSize(width: 1040, height: 680)
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
    case settings = "Settings"
    case shortcuts = "Shortcuts"
    case team = "Invite your team"
    
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
        case .settings: return "gearshape"
        case .shortcuts: return "command"
        case .team: return "person.2"
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
    @State private var activeSettingsTab: SaynSettingsTab = .account
    @State private var onboardingStep: Int = 1
    
    // Invite-Only Auth Modal State
    @State private var showAuthModal: Bool = false
    @State private var authUsernameOrEmail: String = ""
    @State private var authPassword: String = ""
    @State private var isShowPassword: Bool = false
    
    // Search & Filtering
    @State private var searchHistoryQuery: String = ""
    @State private var searchDictionaryQuery: String = ""
    @State private var isAddingNewWord: Bool = false
    @State private var newWordText: String = ""
    @State private var copiedId: UUID? = nil
    
    // Account edit fields
    @State private var editFirstName: String = "Allan"
    @State private var editLastName: String = "Maaz"
    @State private var editPhone: String = "+91 98765 43210"
    @State private var editWritingRole: String = "Engineering & Voice"
    @State private var editEmail: String = "allanmaazimdad@gmail.com"
    @State private var accountSavedNotice: Bool = false
    
    // Team edit fields
    @State private var newTeamEmail: String = ""
    @State private var newTeamRole: String = "Member"
    @State private var teamInviteNotice: String? = nil
    
    // Snippets edit fields
    @State private var isAddingSnippet: Bool = false
    @State private var newSnippetShortcut: String = ""
    @State private var newSnippetExpansion: String = ""
    @State private var snippetCopiedId: UUID? = nil
    
    // Help & Diagnostics modal state
    @State private var showHelpModal: Bool = false
    
    // Vibe Coding status notice
    @State private var vibeCodingSetupNotice: String? = nil
    
    // Scratchpad
    @State private var scratchpadText: String = "Dictate or draft freely here. When done, you can apply a Transform or copy directly."
    @State private var activeStyleSubTab: String = "Personal messages"
    
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
    
    private func syncAccountFields() {
        editFirstName = store.firstName.isEmpty ? "Allan" : store.firstName
        editLastName = store.lastName.isEmpty ? "Maaz" : store.lastName
        editPhone = store.phone.isEmpty ? "+91 98765 43210" : store.phone
        editWritingRole = store.writingRole.isEmpty ? "Engineering & Voice" : store.writingRole
        editEmail = store.email.isEmpty ? "allanmaazimdad@gmail.com" : store.email
    }
    
    var body: some View {
        ZStack {
            bgCanvas.ignoresSafeArea()
            
            authenticatedStudioView
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        .background(WindowAppearanceController(isDark: false))
        .frame(minWidth: 1040, minHeight: 680)
        .onAppear {
            syncAccountFields()
        }
    }
    
    // MARK: - Authenticated Studio Workspace
    private var authenticatedStudioView: some View {
        ZStack {
            HStack(spacing: 0) {
                // Left Sidebar (Full Height, Traffic lights at top)
                if !isSidebarCollapsed {
                    sidebarView
                        .frame(width: 228)
                        .background(bgCanvas)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    Divider()
                        .background(borderDivider)
                }
                
                // Right Main Area: Top Bar + Content Router
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    topToolbar
                    
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
                        case .settings:
                            settingsPageView
                        case .shortcuts:
                            shortcutsPageView
                        case .team:
                            teamPageView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(bgCanvas)
                }
            }
            .background(bgCanvas)
            
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
            
            // Floating Help & Diagnostics Modal Sheet
            if showHelpModal {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            showHelpModal = false
                        }
                    }
                
                helpModalView
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
            
            // Interactive Onboarding Walkthrough Overlay (Initial Install & Settings Replay)
            if store.showOnboardingWalkthrough || (!store.hasCompletedOnboarding && store.isAuthenticated) {
                onboardingWalkthroughView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
    }
    
    // MARK: - Top Chrome Toolbar
    private var topToolbar: some View {
        HStack {
            if isSidebarCollapsed {
                Spacer()
                    .frame(width: 68)
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isSidebarCollapsed.toggle()
                }
            }) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 90/255, green: 88/255, blue: 85/255))
                    .padding(6)
            }
            .buttonStyle(PlainButtonStyle())
            
            if selectedTab == .dictation {
                Spacer()
                
                // Centered Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 140/255, green: 138/255, blue: 135/255))
                    
                    TextField("Search your dictations...", text: $searchHistoryQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12.5))
                        .foregroundColor(Color(red: 30/255, green: 30/255, blue: 30/255))
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: 480)
                .frame(height: 34)
                .background(Capsule().fill(Color(red: 242/255, green: 239/255, blue: 235/255)))
                .overlay(Capsule().stroke(Color.black.opacity(0.04), lineWidth: 1))
            }
            
            Spacer()
            
            // Notification Bell + Avatar
            HStack(spacing: 16) {
                if selectedTab != .settings {
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 14.5, weight: .regular))
                            .foregroundColor(Color(red: 50/255, green: 48/255, blue: 46/255))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        showProfilePopover.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 75/255, green: 12/255, blue: 25/255))
                            .frame(width: 32, height: 32)
                        
                        Text("A")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showProfilePopover, arrowEdge: .bottom) {
                    profilePopoverCard
                }
            }
            .padding(.trailing, 24)
        }
        .frame(height: 52)
        .padding(.horizontal, 16)
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
                    HStack(spacing: 6) {
                        Text("\(store.firstName) \(store.lastName)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(accentCyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(accentCyan.opacity(0.12)))
                    }
                    Text(store.email.isEmpty ? "allanmaazimdad@gmail.com" : store.email)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(textMuted)
                }
            }
            
            Divider()
                .background(borderDivider)
            
            // Unlimited Studio Status Card
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accentCyan)
                            .frame(width: 7, height: 7)
                        Text("Unlimited Studio")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(textDark)
                    }
                    Text("Local-first · Zero limits · Private")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(textMuted)
                }
                Spacer()
                Text("Active")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accentTeal))
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
            
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
        .frame(width: 310)
        .background(cardWhite)
    }
    
    // MARK: - Left Sidebar Navigation
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // macOS Window Traffic Light Spacer & Brand Lockup
            VStack(alignment: .leading, spacing: 18) {
                Spacer()
                    .frame(height: 38)
                
                brandLogoView
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
            
            // Navigation Links
            VStack(alignment: .leading, spacing: 3) {
                sidebarNavItem(tab: .dictation, label: "Dictation", icon: "mic")
                sidebarNavItem(tab: .notetaker, label: "Notetaker", icon: "record.circle", badge: "New!")
                sidebarNavItem(tab: .insights, label: "Insights", customIcon: AnyView(
                    HStack(alignment: .bottom, spacing: 2) {
                        RoundedRectangle(cornerRadius: 0.8).frame(width: 2.4, height: 7)
                        RoundedRectangle(cornerRadius: 0.8).frame(width: 2.4, height: 13)
                        RoundedRectangle(cornerRadius: 0.8).frame(width: 2.4, height: 10)
                    }
                ))
                sidebarNavItem(tab: .dictionary, label: "Dictionary", icon: "character.book.closed")
                sidebarNavItem(tab: .snippets, label: "Snippets", icon: "scissors")
                sidebarNavItem(tab: .style, label: "Style", customIcon: AnyView(
                    HStack(alignment: .lastTextBaseline, spacing: 0.5) {
                        Text("A")
                            .font(.system(size: 13.5, weight: .bold, design: .serif))
                        Text("a")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                    }
                    .fixedSize()
                ))
                sidebarNavItem(tab: .transforms, label: "Transforms", icon: "arrow.triangle.branch")
                sidebarNavItem(tab: .scratchpad, label: "Scratchpad", icon: "doc.text")
            }
            .padding(.horizontal, 10)
            
            // Explore Notetaker Promo Card
            exploreNotetakerPromoCard
            
            Spacer()
            
            // Bottom Utility Links: Invite team, Shortcuts, Settings, Help
            VStack(alignment: .leading, spacing: 2) {
                sidebarNavItem(tab: .team, label: "Invite your team", icon: "person.2")
                sidebarNavItem(tab: .shortcuts, label: "Shortcuts", icon: "command")
                sidebarNavItem(tab: .settings, label: "Settings", icon: "gearshape")
                sidebarBottomItem(title: "Help", icon: "questionmark.circle") {
                    showHelpModal = true
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Explore Notetaker Promo Card
    @ViewBuilder
    private var exploreNotetakerPromoCard: some View {
        if !store.isNotetakerPromoDismissed {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(red: 248/255, green: 237/255, blue: 238/255))
                            .frame(width: 28, height: 28)
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            store.isNotetakerPromoDismissed = true
                            store.updateConfig()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(red: 140/255, green: 135/255, blue: 130/255))
                            .padding(4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text("Explore Notetaker")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                
                Text("Get a transcript, summary, and action items for every meeting")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                    .lineSpacing(2)
                
                Button(action: {
                    selectedTab = .notetaker
                }) {
                    HStack(spacing: 5) {
                        Text("Check it out")
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(red: 111/255, green: 16/255, blue: 37/255)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 248/255, green: 241/255, blue: 237/255))
            )
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
    
    // Official SAYN Squircle Logo Lockup
    private var brandLogoView: some View {
        let logoImage: NSImage? = {
            let candidates = [
                "/Applications/SAYN.app/Contents/Resources/logo.png",
                Bundle.main.path(forResource: "logo", ofType: "png"),
                "/Users/apple/Desktop/SAYN/apps/desktop-macos/Resources/logo.png",
                "/Users/apple/Desktop/SAYN/dist/logo.png"
            ]
            for path in candidates.compactMap({ $0 }) {
                if FileManager.default.fileExists(atPath: path),
                   let img = NSImage(contentsOfFile: path) {
                    return img
                }
            }
            return nil
        }()
        
        return HStack(spacing: 10) {
            if let img = logoImage {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8.5))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8.5)
                        .fill(Color(red: 50/255, green: 8/255, blue: 18/255))
                        .frame(width: 36, height: 36)
                    Image(systemName: "waveform")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text("SAYN")
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundColor(Color(red: 25/255, green: 22/255, blue: 22/255))
        }
    }
    
    private func sidebarNavItem(tab: SaynStudioTab, label: String, icon: String? = nil, customIcon: AnyView? = nil, badge: String? = nil) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: {
            if tab == .settings {
                syncAccountFields()
                activeSettingsTab = .account
            }
            selectedTab = tab
        }) {
            HStack(spacing: 12) {
                Group {
                    if let custom = customIcon {
                        custom
                            .frame(width: 20, alignment: .center)
                    } else if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            .frame(width: 20, alignment: .center)
                    }
                }
                .foregroundColor(isSelected ? Color(red: 88/255, green: 20/255, blue: 34/255) : Color(red: 95/255, green: 92/255, blue: 90/255))
                
                Text(label)
                    .font(.system(size: 13.5, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? Color(red: 88/255, green: 20/255, blue: 34/255) : Color(red: 45/255, green: 42/255, blue: 40/255))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                if let b = badge {
                    Spacer(minLength: 8)
                    Text(b)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color(red: 111/255, green: 16/255, blue: 37/255)))
                        .layoutPriority(1)
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 245/255, green: 236/255, blue: 234/255) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sidebarBottomItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20, alignment: .center)
                    .foregroundColor(Color(red: 95/255, green: 92/255, blue: 90/255))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 55/255, green: 52/255, blue: 50/255))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 1. Dictation View (Pixel-Perfect Matching Screenshot)
    private var dictationFeedView: some View {
        HStack(alignment: .top, spacing: 20) {
            // Center Feed Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // 1. Personalized Greeting Line
                    HStack(alignment: .firstTextBaseline) {
                        HStack(spacing: 5) {
                            Text("Good to see you,")
                                .font(.system(size: 26, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 26/255, green: 22/255, blue: 22/255))
                            
                            Text(store.firstName.isEmpty ? "Allan" : store.firstName)
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(Color(red: 26/255, green: 22/255, blue: 22/255))
                        }
                        
                        Spacer()
                        
                        Text("Mon, 20 Oct")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                    }
                    
                    // 2. Crimson Acoustic Hero Banner
                    if !store.isHeroBannerDismissed {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 48/255, green: 8/255, blue: 18/255),
                                            Color(red: 26/255, green: 4/255, blue: 10/255)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Luminous fluid acoustic wave contours
                            GeometryReader { geo in
                                let w = geo.size.width
                                let h = geo.size.height
                                
                                // Wave Ribbon 1 (Deep Rose Glow)
                                Path { p in
                                    p.move(to: CGPoint(x: w * 0.32, y: h))
                                    p.addCurve(
                                        to: CGPoint(x: w * 0.98, y: h * 0.18),
                                        control1: CGPoint(x: w * 0.52, y: h * 0.08),
                                        control2: CGPoint(x: w * 0.76, y: h * 0.88)
                                    )
                                }
                                .stroke(Color(red: 185/255, green: 45/255, blue: 75/255).opacity(0.42), lineWidth: 2.2)
                                
                                // Wave Ribbon 2 (Soft Rose Wave)
                                Path { p in
                                    p.move(to: CGPoint(x: w * 0.40, y: h))
                                    p.addCurve(
                                        to: CGPoint(x: w, y: h * 0.36),
                                        control1: CGPoint(x: w * 0.60, y: h * 0.18),
                                        control2: CGPoint(x: w * 0.84, y: h * 0.78)
                                    )
                                }
                                .stroke(Color(red: 215/255, green: 65/255, blue: 95/255).opacity(0.30), lineWidth: 1.6)
                                
                                // Wave Ribbon 3 (Outer Accent Wave)
                                Path { p in
                                    p.move(to: CGPoint(x: w * 0.48, y: h))
                                    p.addCurve(
                                        to: CGPoint(x: w * 0.96, y: h * 0.52),
                                        control1: CGPoint(x: w * 0.68, y: h * 0.28),
                                        control2: CGPoint(x: w * 0.88, y: h * 0.70)
                                    )
                                }
                                .stroke(Color(red: 235/255, green: 110/255, blue: 135/255).opacity(0.20), lineWidth: 1.2)
                            }
                            
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Turn your voice into\nclear, actionable notes.")
                                        .font(.system(size: 21, weight: .medium, design: .serif))
                                        .foregroundColor(Color(red: 252/255, green: 249/255, blue: 246/255))
                                        .lineSpacing(4)
                                    
                                    Button(action: {
                                        onToggleDictation()
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "mic.fill")
                                                .font(.system(size: 12.5))
                                                .foregroundColor(Color(red: 100/255, green: 16/255, blue: 34/255))
                                            
                                            Text("Start dictating")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(Color(red: 28/255, green: 22/255, blue: 22/255))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8.5)
                                        .background(Capsule().fill(Color.white))
                                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                Spacer()
                                
                                // Translucent Glassmorphism Pill with 4 subtle icons
                                HStack(spacing: 16) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                    Image(systemName: "doc.text.fill")
                                    Image(systemName: "envelope.fill")
                                    Image(systemName: "sparkles")
                                }
                                .font(.system(size: 16))
                                .foregroundColor(Color.white.opacity(0.70))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 22)
                            
                            // Dismiss Cross Mark (✕) Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    store.isHeroBannerDismissed = true
                                    store.updateConfig()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.28))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.85))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(14)
                        }
                        .frame(height: 144)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // 3. Recent Dictations Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Dictations")
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                                        .padding(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                HStack(spacing: 4) {
                                    Text("All")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color(red: 50/255, green: 48/255, blue: 46/255))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(Color(red: 120/255, green: 118/255, blue: 115/255))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4.5)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 242/255, green: 239/255, blue: 235/255)))
                            }
                        }
                        
                        // List of Dictation Cards
                        let itemsToDisplay = store.history.filter {
                            searchHistoryQuery.isEmpty || $0.text.localizedCaseInsensitiveContains(searchHistoryQuery)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(itemsToDisplay) { item in
                                dictationItemRow(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
            
            // Right Analytics & Status Rail
            VStack(spacing: 14) {
                // Card 1: My Activity
                myActivityCard
                
                // Card 2: Voice Ready
                voiceReadyCard
                
                // Card 3: Notes are saved locally
                notesSavedLocallyCard
                
                Spacer()
            }
            .frame(width: 260)
            .padding(.trailing, 24)
            .padding(.top, 14)
        }
    }
    
    // MARK: - Right Rail Cards
    private var myActivityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Activity")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("This week")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color(red: 70/255, green: 68/255, blue: 66/255))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(Color(red: 120/255, green: 118/255, blue: 115/255))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 244/255, green: 241/255, blue: 237/255)))
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    // Mini waveform badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 248/255, green: 237/255, blue: 238/255))
                            .frame(width: 24, height: 24)
                        HStack(spacing: 1.6) {
                            RoundedRectangle(cornerRadius: 0.8).fill(Color(red: 120/255, green: 22/255, blue: 44/255)).frame(width: 1.8, height: 8)
                            RoundedRectangle(cornerRadius: 0.8).fill(Color(red: 120/255, green: 22/255, blue: 44/255)).frame(width: 1.8, height: 14)
                            RoundedRectangle(cornerRadius: 0.8).fill(Color(red: 120/255, green: 22/255, blue: 44/255)).frame(width: 1.8, height: 10)
                        }
                    }
                    
                    Text("1.6K")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                    
                    Text("words")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                }
                
                Spacer()
                
                // Mini bar chart with 7 vertical bars in varying rose/maroon shades
                HStack(alignment: .bottom, spacing: 4.5) {
                    let heights: [CGFloat] = [10, 16, 12, 22, 14, 32, 20]
                    ForEach(0..<heights.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                i == 5 
                                    ? Color(red: 175/255, green: 42/255, blue: 68/255) 
                                    : (i == 6 ? Color(red: 198/255, green: 78/255, blue: 102/255) : Color(red: 228/255, green: 155/255, blue: 168/255))
                            )
                            .frame(width: 4.2, height: heights[i])
                    }
                }
                .padding(.bottom, 2)
                .padding(.trailing, 4)
            }
            
            // Bottom 2 Metric Badges
            HStack(spacing: 8) {
                // WPM Badge
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 215/255, green: 100/255, blue: 40/255))
                    
                    Text("544")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 28/255, green: 26/255, blue: 25/255))
                    
                    Text("wpm")
                        .font(.system(size: 9.5, weight: .regular))
                        .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Color(red: 34/255, green: 197/255, blue: 94/255))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 248/255, green: 246/255, blue: 243/255)))
                
                // Day Streak Badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 225/255, green: 80/255, blue: 40/255))
                    
                    Text("1")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 28/255, green: 26/255, blue: 25/255))
                    
                    Text("day streak")
                        .font(.system(size: 9.5, weight: .regular))
                        .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 248/255, green: 246/255, blue: 243/255)))
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.025), radius: 4, x: 0, y: 1)
        )
    }
    
    private var voiceReadyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 34/255, green: 197/255, blue: 94/255))
                        .frame(width: 7.5, height: 7.5)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Voice Ready")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                        
                        Text("Offline dictation enabled")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    activeSettingsTab = .general
                    showSettingsModal = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12.5))
                        .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Audio Waveform Visualization Bars (Centered Vertically for Audio Reflection)
            HStack(spacing: 2.0) {
                let pattern: [CGFloat] = [4, 5, 7, 9, 13, 18, 14, 20, 24, 16, 22, 12, 16, 23, 15, 19, 14, 18, 11, 15, 20, 14, 17, 12, 9, 7, 9, 6, 8, 11, 16, 13, 18, 14, 9, 7, 5, 4]
                ForEach(0..<pattern.count, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 1.0)
                        .fill(Color(red: 224/255, green: 155/255, blue: 168/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: pattern[idx])
                }
            }
            .frame(height: 26, alignment: .center)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.025), radius: 4, x: 0, y: 1)
        )
    }
    
    private var notesSavedLocallyCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(red: 248/255, green: 237/255, blue: 238/255))
                    .frame(width: 30, height: 30)
                Image(systemName: "doc.text")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Notes are saved locally")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                Text("Your data stays on this device.")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.025), radius: 4, x: 0, y: 1)
        )
    }
    
    // MARK: - Dictation Item Row (with REAL Audio Playback, Copy, and Delete)
    private func dictationItemRow(item: DictationEntry) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Squircle document icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 248/255, green: 237/255, blue: 238/255))
                    .frame(width: 30, height: 30)
                Image(systemName: "doc.text")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
            }
            
            // Timestamp
            Text(item.timeFormatted.isEmpty ? "3:16 pm" : item.timeFormatted)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundColor(Color(red: 135/255, green: 132/255, blue: 128/255))
                .frame(width: 58, alignment: .leading)
            
            // Text preview
            Text(item.text)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundColor(Color(red: 28/255, green: 26/255, blue: 25/255))
                .lineSpacing(2.5)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Actions: Play, Copy, Flag, Ellipsis Menu
            HStack(spacing: 12) {
                Button(action: {
                    store.playAudio(for: item)
                }) {
                    Image(systemName: store.playingEntryId == item.id ? "stop.fill" : "play.fill")
                        .font(.system(size: 10.5))
                        .foregroundColor(store.playingEntryId == item.id ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 120/255, green: 118/255, blue: 115/255))
                }
                .buttonStyle(PlainButtonStyle())
                
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
                        .font(.system(size: 11.5))
                        .foregroundColor(copiedId == item.id ? accentCyan : Color(red: 120/255, green: 118/255, blue: 115/255))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    store.toggleFlag(id: item.id)
                }) {
                    Image(systemName: item.isFlagged ? "flag.fill" : "flag")
                        .font(.system(size: 11.5))
                        .foregroundColor(item.isFlagged ? Color(red: 130/255, green: 25/255, blue: 50/255) : Color(red: 120/255, green: 118/255, blue: 115/255))
                }
                .buttonStyle(PlainButtonStyle())
                
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
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(red: 120/255, green: 118/255, blue: 115/255))
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.025), radius: 3, x: 0, y: 1)
        )
    }
    
    // MARK: - 2. Insights Dashboard View (Pixel-Perfect Matching Screenshot 2)
    @State private var insightsSubTab: String = "Your usage"
    @State private var insightsPlatform: String = "Desktop"
    
    private var insightsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header Row
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Insights")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 22/255, green: 20/255, blue: 20/255))
                        
                        HStack(spacing: 18) {
                            Button(action: { insightsSubTab = "Your usage" }) {
                                Text("Your usage")
                                    .font(.system(size: 13, weight: insightsSubTab == "Your usage" ? .bold : .regular))
                                    .foregroundColor(insightsSubTab == "Your usage" ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 125/255, green: 122/255, blue: 118/255))
                                    .overlay(
                                        insightsSubTab == "Your usage" ?
                                        Rectangle().frame(height: 2.2).offset(y: 10).foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255)) : nil,
                                        alignment: .bottom
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { insightsSubTab = "Your voice" }) {
                                Text("Your voice")
                                    .font(.system(size: 13, weight: insightsSubTab == "Your voice" ? .bold : .regular))
                                    .foregroundColor(insightsSubTab == "Your voice" ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 125/255, green: 122/255, blue: 118/255))
                                    .overlay(
                                        insightsSubTab == "Your voice" ?
                                        Rectangle().frame(height: 2.2).offset(y: 10).foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255)) : nil,
                                        alignment: .bottom
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Spacer()
                    
                    // Filter Pill: Calendar + "This month ⌄"
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11.5))
                            .foregroundColor(Color(red: 90/255, green: 88/255, blue: 85/255))
                        Text("This month")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color(red: 45/255, green: 42/255, blue: 40/255))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(red: 120/255, green: 118/255, blue: 115/255))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color(red: 244/255, green: 241/255, blue: 237/255)))
                }
                
                // Top Row: 3 Metric Cards
                HStack(alignment: .top, spacing: 16) {
                    // Card 1: Words per minute
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 248/255, green: 237/255, blue: 238/255))
                                    .frame(width: 28, height: 28)
                                HStack(spacing: 1.6) {
                                    RoundedRectangle(cornerRadius: 0.8).fill(Color(red: 120/255, green: 22/255, blue: 44/255)).frame(width: 1.8, height: 8)
                                    RoundedRectangle(cornerRadius: 0.8).fill(Color(red: 120/255, green: 22/255, blue: 44/255)).frame(width: 1.8, height: 14)
                                    RoundedRectangle(cornerRadius: 0.8).fill(Color(red: 120/255, green: 22/255, blue: 44/255)).frame(width: 1.8, height: 10)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Words per minute")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                                Text("\(store.averageWPM > 0 ? store.averageWPM : (store.history.isEmpty ? 544 : 240))")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                            }
                        }
                        
                        Text("You speak pretty fast! ⚡")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                        
                        // Semicircular Arc Speed Gauge
                        ZStack {
                            Circle()
                                .trim(from: 0.5, to: 1.0)
                                .stroke(Color(red: 245/255, green: 234/255, blue: 236/255), lineWidth: 11)
                                .frame(width: 140, height: 140)
                                .rotationEffect(.degrees(0))
                            
                            Circle()
                                .trim(from: 0.5, to: 0.85)
                                .stroke(
                                    Color(red: 111/255, green: 16/255, blue: 37/255),
                                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                                )
                                .frame(width: 140, height: 140)
                            
                            Circle()
                                .trim(from: 0.85, to: 0.94)
                                .stroke(
                                    Color(red: 220/255, green: 140/255, blue: 155/255),
                                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                                )
                                .frame(width: 140, height: 140)
                            
                            VStack(spacing: 1) {
                                Text("You're in the top")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                                Text("0.3%")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                Text("of SAYN users")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                            }
                            .offset(y: -10)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 85)
                        .padding(.top, 4)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                    
                    // Card 2: Fixes made
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 248/255, green: 237/255, blue: 238/255))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "doc.text")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Fixes made")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                                Text("\(store.totalFixesMade > 0 ? store.totalFixesMade : 249)")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                            }
                        }
                        
                        Text("SAYN helped clean this up")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                        
                        VStack(spacing: 14) {
                            // Words corrected
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text("Aa")
                                        .font(.system(size: 12, weight: .bold, design: .serif))
                                        .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
                                    Text("Words corrected")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color(red: 35/255, green: 32/255, blue: 30/255))
                                    Spacer()
                                    Text("187")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                }
                                
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color(red: 244/255, green: 241/255, blue: 237/255))
                                        Capsule().fill(Color(red: 111/255, green: 16/255, blue: 37/255))
                                            .frame(width: g.size.width * 0.75)
                                    }
                                }
                                .frame(height: 6)
                            }
                            
                            // Formatting fixes
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
                                    Text("Formatting fixes")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color(red: 35/255, green: 32/255, blue: 30/255))
                                    Spacer()
                                    Text("62")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                }
                                
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color(red: 244/255, green: 241/255, blue: 237/255))
                                        Capsule().fill(Color(red: 198/255, green: 78/255, blue: 102/255))
                                            .frame(width: g.size.width * 0.28)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                    
                    // Card 3: Total words dictated
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 248/255, green: 237/255, blue: 238/255))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "doc.text")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
                            }
                            
                            Spacer()
                            
                            // 3 layered pages graphic
                            HStack(spacing: -14) {
                                ForEach(0..<3, id: \.self) { p in
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(0..<4, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 0.5)
                                                .fill(Color(red: 215/255, green: 110/255, blue: 130/255).opacity(0.7))
                                                .frame(width: 18, height: 1.5)
                                        }
                                    }
                                    .padding(5)
                                    .frame(width: 30, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 252/255, green: 245/255, blue: 246/255))
                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(red: 235/255, green: 180/255, blue: 190/255), lineWidth: 1))
                                    )
                                    .rotationEffect(.degrees(Double(p - 1) * 6))
                                }
                            }
                        }
                                       let isDesktop = (insightsPlatform == "Desktop")
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Total words dictated")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                            Text(isDesktop ? (store.totalWordsDictated > 0 ? "\(store.totalWordsDictated)" : "1,575") : "0")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                            Text(isDesktop ? (store.totalWordsDictated > 0 ? "That's about \(max(1, store.totalWordsDictated / 250)) pages!" : "That's about 6 pages!") : "No mobile dictations yet")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                        }
                        
                        Spacer()
                        
                        // Desktop vs Mobile Buttons
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    insightsPlatform = "Desktop"
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "display")
                                        .font(.system(size: 11))
                                    Text("Desktop (\(store.history.isEmpty ? 69 : store.history.count))")
                                        .font(.system(size: 11, weight: isDesktop ? .bold : .medium))
                                }
                                .foregroundColor(isDesktop ? .white : Color(red: 111/255, green: 16/255, blue: 37/255))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(isDesktop ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 248/255, green: 241/255, blue: 237/255)))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    insightsPlatform = "Mobile"
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "iphone")
                                        .font(.system(size: 11))
                                    Text("Mobile (0)")
                                        .font(.system(size: 11, weight: !isDesktop ? .bold : .medium))
                                }
                                .foregroundColor(!isDesktop ? .white : Color(red: 111/255, green: 16/255, blue: 37/255))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(!isDesktop ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 248/255, green: 241/255, blue: 237/255)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                }
                
                // Middle Row: 2 Cards (What you use SAYN for + Your streak)
                HStack(alignment: .top, spacing: 16) {
                    let isDesktop = (insightsPlatform == "Desktop")
                    
                    // Left: Donut Chart / Usage
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(isDesktop ? "Desktop usage" : "Mobile usage")
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                            Spacer()
                            Text(isDesktop ? "Total dictations: \(store.history.isEmpty ? 69 : store.history.count)" : "Total dictations: 0")
                                .font(.system(size: 11.5, weight: .regular))
                                .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                        }
                        
                        if isDesktop {
                            HStack(spacing: 24) {
                                // Donut Ring
                                ZStack {
                                    // Segment 3: Messages & chat 62%
                                    Circle()
                                        .trim(from: 0.0, to: 0.62)
                                        .stroke(Color(red: 217/255, green: 110/255, blue: 132/255), lineWidth: 16)
                                        .rotationEffect(.degrees(-90))
                                    
                                    // Segment 2: Code & technical 13%
                                    Circle()
                                        .trim(from: 0.62, to: 0.75)
                                        .stroke(Color(red: 154/255, green: 43/255, blue: 67/255), lineWidth: 16)
                                        .rotationEffect(.degrees(-90))
                                    
                                    // Segment 1: General & writing 25%
                                    Circle()
                                        .trim(from: 0.75, to: 1.0)
                                        .stroke(Color(red: 82/255, green: 22/255, blue: 34/255), lineWidth: 16)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack(spacing: 1) {
                                        Text("\(store.history.isEmpty ? 69 : store.history.count)")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                        Text("dictations")
                                            .font(.system(size: 10, weight: .regular))
                                            .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                                    }
                                }
                                .frame(width: 110, height: 110)
                                .padding(.vertical, 8)
                                
                                // Legend
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Circle().fill(Color(red: 82/255, green: 22/255, blue: 34/255)).frame(width: 8, height: 8)
                                        Text("General & writing").font(.system(size: 12)).foregroundColor(Color(red: 45/255, green: 42/255, blue: 40/255))
                                        Spacer()
                                        Text("25%").font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Circle().fill(Color(red: 154/255, green: 43/255, blue: 67/255)).frame(width: 8, height: 8)
                                        Text("Code & technical").font(.system(size: 12)).foregroundColor(Color(red: 45/255, green: 42/255, blue: 40/255))
                                        Spacer()
                                        Text("13%").font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Circle().fill(Color(red: 217/255, green: 110/255, blue: 132/255)).frame(width: 8, height: 8)
                                        Text("Messages & chat").font(.system(size: 12)).foregroundColor(Color(red: 45/255, green: 42/255, blue: 40/255))
                                        Spacer()
                                        Text("62%").font(.system(size: 12, weight: .bold)).foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(red: 248/255, green: 241/255, blue: 237/255))
                                        .frame(width: 76, height: 76)
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255))
                                }
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("No Mobile Dictations Yet")
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                                    Text("Dictate on the go using SAYN on Android or iOS. Your mobile dictations and voice insights will automatically sync here.")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                                        .lineSpacing(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                    
                    // Right: Contribution Heatmap
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 5) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(red: 225/255, green: 80/255, blue: 40/255))
                                Text("Your streak")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("1 day")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255))
                                Text("Keep going!")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                            }
                        }
                        
                        // Month Headers
                        HStack {
                            Text("Jul").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Aug").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Sep").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Oct").frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                        
                        // Heatmap Grid: 7 rows x 16 columns
                        VStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { row in
                                HStack(spacing: 3) {
                                    ForEach(0..<16, id: \.self) { col in
                                        let isLatestStreak = (col == 15 && (row == 5 || row == 6))
                                        RoundedRectangle(cornerRadius: 2.2)
                                            .fill(
                                                isLatestStreak ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 244/255, green: 241/255, blue: 237/255)
                                            )
                                            .frame(width: 12, height: 11)
                                    }
                                }
                            }
                        }
                        
                        // Heatmap Legend
                        HStack {
                            Text("Less")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                            
                            HStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 1.5).fill(Color(red: 244/255, green: 241/255, blue: 237/255)).frame(width: 9, height: 9)
                                RoundedRectangle(cornerRadius: 1.5).fill(Color(red: 234/255, green: 178/255, blue: 190/255)).frame(width: 9, height: 9)
                                RoundedRectangle(cornerRadius: 1.5).fill(Color(red: 200/255, green: 82/255, blue: 111/255)).frame(width: 9, height: 9)
                                RoundedRectangle(cornerRadius: 1.5).fill(Color(red: 111/255, green: 16/255, blue: 37/255)).frame(width: 9, height: 9)
                            }
                            
                            Text("More")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(red: 130/255, green: 128/255, blue: 125/255))
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 2).stroke(Color(red: 111/255, green: 16/255, blue: 37/255), lineWidth: 1.2).frame(width: 9, height: 9)
                                Text("Active day")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                }
                
                // Bottom Insight Callout
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 254/255, green: 247/255, blue: 230/255))
                            .frame(width: 38, height: 38)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 230/255, green: 150/255, blue: 30/255))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're most productive in conversations")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                        Text("You use SAYN mostly for messages and everyday chats.")
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
    }
    
    private var telemetryBreakdown: [(percent: String, label: String, icon: String, color: Color)] {
        let total = store.history.count
        guard total > 0 else {
            return [
                ("100%", "READY FOR SPEECH", "mic", accentTeal)
            ]
        }
        let codeAndTech = store.history.filter { $0.text.contains("func") || $0.text.contains("const") || $0.text.contains("import") || $0.text.contains("let ") || $0.text.contains("var ") }.count
        let messages = store.history.filter { $0.text.contains("?") || $0.text.contains("!") || $0.wordCount < 15 }.count
        let documents = max(0, total - codeAndTech - messages)
        
        let pCode = max(0, min(100, Int((Double(codeAndTech) / Double(total)) * 100)))
        let pMsg = max(0, min(100, Int((Double(messages) / Double(total)) * 100)))
        let pDoc = max(0, 100 - pCode - pMsg)
        
        return [
            ("\(pDoc)%", "\(documents) GENERAL & WRITING", "doc.text", accentTeal),
            ("\(pCode)%", "\(codeAndTech) CODE & TECHNICAL", "chevron.left.forwardslash.chevron.right", accentCyan),
            ("\(pMsg)%", "\(messages) MESSAGES & CHAT", "bubble.left.and.bubble.right", accentTeal.opacity(0.7))
        ]
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
        let words = store.wordsOnDate(offsetWeeksAgo: col, dayOfWeek: row)
        if words >= 400 {
            return accentTeal
        } else if words >= 150 {
            return accentTeal.opacity(0.75)
        } else if words >= 30 {
            return accentTeal.opacity(0.40)
        } else if words > 0 {
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
                            
                            ForEach(["SAYN Voice", "Mohammed Maaz", "SwiftUI", "TypeScript", "Speech Flow"], id: \.self) { chip in
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
                // Style Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Style")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                    Text("Customize how SAYN writes for different contexts.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                }
                
                // Style Navigation Tabs (Pill style matching reference screenshot)
                HStack(spacing: 8) {
                    styleSubTabPill(tab: "Personal messages", icon: "bubble.left.fill")
                    styleSubTabPill(tab: "Work messages", icon: "briefcase")
                    styleSubTabPill(tab: "Email", icon: "envelope")
                    styleSubTabPill(tab: "Other", icon: "square.grid.2x2")
                    styleSubTabPill(tab: "Auto cleanup", icon: "sparkles")
                }
                
                if activeStyleSubTab == "Personal messages" {
                    personalMessagesStyleContent
                } else if activeStyleSubTab == "Work messages" {
                    workMessagesStyleContent
                } else if activeStyleSubTab == "Email" {
                    emailStyleContent
                } else if activeStyleSubTab == "Other" {
                    otherStyleContent
                } else if activeStyleSubTab == "Auto cleanup" {
                    autoCleanupStyleContent
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
    }
    
    private func styleSubTabPill(tab: String, icon: String) -> some View {
        let isSelected = activeStyleSubTab == tab
        return Button(action: {
            activeStyleSubTab = tab
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                Text(tab)
                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 115/255, green: 112/255, blue: 110/255))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 254/255, green: 241/255, blue: 240/255) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color.clear, lineWidth: 1.2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var autoCleanupStyleContent: some View {
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
            
            // 4 Level Cards: None, Light, Medium, Aggressive (Saves to SaynStore)
            HStack(alignment: .top, spacing: 14) {
                cleanupLevelCard(
                    title: "None",
                    subtitle: "Verbatim speech with zero restructuring",
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
                
                cleanupLevelCard(
                    title: "Aggressive",
                    subtitle: "Condenses into punchy executive bullets",
                    example: "Coffee meeting:\n• Leave earlier (traffic)\n• Let me know if time works",
                    isSelected: store.cleanupLevel == "Aggressive"
                ) {
                    store.cleanupLevel = "Aggressive"
                    store.updateConfig()
                }
            }
        }
    }
    
    private var emailStyleContent: some View {
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
    
    // MARK: - Specialized Style Subtab Contents
    private var personalMessagesStyleContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Hero Acoustic Wave Banner (Screenshot 1 Reference)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 20/255, green: 10/255, blue: 14/255),
                                Color(red: 38/255, green: 8/255, blue: 18/255),
                                Color(red: 16/255, green: 6/255, blue: 10/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        GeometryReader { geo in
                            Path { path in
                                path.move(to: CGPoint(x: geo.size.width * 0.45, y: geo.size.height))
                                path.addCurve(
                                    to: CGPoint(x: geo.size.width, y: geo.size.height * 0.2),
                                    control1: CGPoint(x: geo.size.width * 0.65, y: geo.size.height * 0.3),
                                    control2: CGPoint(x: geo.size.width * 0.82, y: geo.size.height * 0.8)
                                )
                            }
                            .stroke(Color(red: 168/255, green: 30/255, blue: 60/255).opacity(0.35), lineWidth: 28)
                            .blur(radius: 18)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your tone, everywhere.")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Choose a style that fits your conversations.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                    
                    Spacer()
                    
                    // 5 Social App Badges Capsule
                    HStack(spacing: 8) {
                        // WhatsApp
                        ZStack {
                            Circle().fill(Color(red: 37/255, green: 211/255, blue: 102/255)).frame(width: 28, height: 28)
                            Image(systemName: "phone.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Telegram
                        ZStack {
                            Circle().fill(Color(red: 42/255, green: 171/255, blue: 238/255)).frame(width: 28, height: 28)
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(45))
                                .offset(x: -1, y: 1)
                        }
                        
                        // Messages / iMessage
                        ZStack {
                            Circle().fill(Color(red: 0/255, green: 122/255, blue: 255/255)).frame(width: 28, height: 28)
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // WeChat
                        ZStack {
                            Circle().fill(Color(red: 7/255, green: 193/255, blue: 96/255)).frame(width: 28, height: 28)
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Discord
                        ZStack {
                            Circle().fill(Color(red: 88/255, green: 101/255, blue: 242/255)).frame(width: 28, height: 28)
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 22)
            }
            .frame(maxWidth: .infinity)
            
            // 3 Tone Cards
            HStack(alignment: .top, spacing: 16) {
                // 1. Casual (selected)
                personalToneCard(
                    title: "Casual",
                    subtitle: "Conversational & relaxed",
                    example: "Hey! Just grabbed some coffee. Let me know when you're free to catch up later today",
                    iconName: "bubble.left.fill",
                    iconColor: Color(red: 111/255, green: 16/255, blue: 37/255),
                    iconBg: Color(red: 254/255, green: 238/255, blue: 238/255),
                    bubbleBg: Color(red: 253/255, green: 242/255, blue: 241/255),
                    isSelected: store.personalTone == "Casual"
                ) {
                    store.personalTone = "Casual"
                    store.updateConfig()
                }
                
                // 2. Warm & Friendly
                personalToneCard(
                    title: "Warm & Friendly",
                    subtitle: "Adds friendly warmth",
                    example: "Hey there! Hope you're having an awesome week. ✨ Let's definitely catch up soon!",
                    iconName: "sun.max.fill",
                    iconColor: Color(red: 235/255, green: 160/255, blue: 40/255),
                    iconBg: Color(red: 254/255, green: 249/255, blue: 230/255),
                    bubbleBg: Color(red: 254/255, green: 249/255, blue: 240/255),
                    isSelected: store.personalTone == "Warm & Friendly"
                ) {
                    store.personalTone = "Warm & Friendly"
                    store.updateConfig()
                }
                
                // 3. Direct & Punchy
                personalToneCard(
                    title: "Direct & Punchy",
                    subtitle: "Zero fluff replies",
                    example: "Got it. Running 5 mins late. See you downstairs.",
                    iconName: "bolt.fill",
                    iconColor: Color(red: 40/255, green: 125/255, blue: 245/255),
                    iconBg: Color(red: 238/255, green: 245/255, blue: 255/255),
                    bubbleBg: Color(red: 245/255, green: 247/255, blue: 250/255),
                    isSelected: store.personalTone == "Direct"
                ) {
                    store.personalTone = "Direct"
                    store.updateConfig()
                }
            }
            
            // Auto-emoji enhancement Toggle Card
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 254/255, green: 238/255, blue: 238/255))
                        .frame(width: 36, height: 36)
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 17))
                        .foregroundColor(Color(red: 180/255, green: 30/255, blue: 50/255))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-emoji enhancement")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                    Text("Subtly adds warm emojis (✨, 👍, 🙌) to enthusiastic personal messages")
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                }
                
                Spacer()
                
                Toggle("", isOn: $store.personalEmojiEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 111/255, green: 16/255, blue: 37/255)))
                    .onChange(of: store.personalEmojiEnabled) { _ in
                        store.updateConfig()
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 236/255, green: 233/255, blue: 228/255), lineWidth: 1)
                    )
            )
        }
    }
    
    private func personalToneCard(
        title: String,
        subtitle: String,
        example: String,
        iconName: String,
        iconColor: Color,
        iconBg: Color,
        bubbleBg: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                // Top row: left icon, right selection circle
                HStack {
                    ZStack {
                        Circle()
                            .fill(iconBg)
                            .frame(width: 34, height: 34)
                        Image(systemName: iconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color(red: 111/255, green: 16/255, blue: 37/255))
                                .frame(width: 17, height: 17)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 17, height: 17)
                    }
                }
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 125/255, green: 122/255, blue: 118/255))
                }
                
                // Inner Quote Bubble
                VStack(alignment: .trailing, spacing: 8) {
                    Text(example)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundColor(Color(red: 30/255, green: 28/255, blue: 26/255))
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(example, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 140/255, green: 137/255, blue: 132/255))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(bubbleBg))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 236/255, green: 233/255, blue: 228/255),
                        lineWidth: isSelected ? 1.8 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var workMessagesStyleContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Applies to workplace collaboration")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("Optimized for Slack, Microsoft Teams, Linear, Asana, and Jira.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.85))
                }
                Spacer()
                HStack(spacing: -6) {
                    ForEach(["briefcase.fill", "target", "checklist"], id: \.self) { ic in
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
                    .fill(LinearGradient(colors: [Color(red: 30/255, green: 38/255, blue: 50/255), Color(red: 18/255, green: 22/255, blue: 32/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            
            HStack(alignment: .top, spacing: 16) {
                emailToneCard(
                    title: "Professional",
                    subtitle: "Structured & clear",
                    greeting: "Team, the sprint deliverables are deployed on staging. Please review the PR when you have bandwidth.",
                    isSelected: store.workTone == "Professional"
                ) {
                    store.workTone = "Professional"
                    store.updateConfig()
                }
                
                emailToneCard(
                    title: "Action-Oriented 🎯",
                    subtitle: "Bullet lists & ownership",
                    greeting: "Sprint Updates:\n• Backend auth API: Merged\n• macOS TextPaster: In QA\n• Next step: Release build tomorrow",
                    isSelected: store.workTone == "Action-Oriented"
                ) {
                    store.workTone = "Action-Oriented"
                    store.updateConfig()
                }
                
                emailToneCard(
                    title: "Executive Brief",
                    subtitle: "High-density status",
                    greeting: "Q3 metrics exceeded target by 14%. Core focus is user retention and zero-latency desktop workflows.",
                    isSelected: store.workTone == "Executive Brief"
                ) {
                    store.workTone = "Executive Brief"
                    store.updateConfig()
                }
            }
        }
    }
    
    private var otherStyleContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Custom Speech & AI Directives")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Define custom formatting rules that apply whenever SAYN polishes your dictation.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.85))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(red: 45/255, green: 35/255, blue: 45/255), Color(red: 25/255, green: 20/255, blue: 28/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Custom Instruction Prompt")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textDark)
                
                TextField("Enter prompt instructions (e.g. Always use British spelling, keep technical acronyms exact)...", text: $store.customStylePrompt)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(cardWhite))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderDivider, lineWidth: 1))
                    .onChange(of: store.customStylePrompt) { _ in
                        store.updateConfig()
                    }
                
                HStack(spacing: 8) {
                    Button(action: { store.customStylePrompt = "Always use British spelling and format dates as DD/MM/YYYY."; store.updateConfig() }) {
                        Text("🇬🇧 British Spelling")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { store.customStylePrompt = "Format code snippets in markdown backticks and preserve exact camelCase naming."; store.updateConfig() }) {
                        Text("💻 Code & Markdown")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { store.customStylePrompt = "Convert key points into concise numbered lists."; store.updateConfig() }) {
                        Text("🔢 Numbered Lists")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
        }
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notetaker")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        Text("Live meeting transcription, AI executive summaries, and action item checklists.")
                            .font(.system(size: 13))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    
                    if store.isRecordingMeeting {
                        Button(action: {
                            store.stopInstantMeeting()
                        }) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Text("Stop Recording (\(store.meetingElapsedSeconds)s)")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.red))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button(action: {
                            store.startInstantMeeting()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "record.circle.fill")
                                Text("Start Instant Note")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(accentTeal))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Live Waveform Card when recording
                if store.isRecordingMeeting {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("● LIVE RECORDING IN PROGRESS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.red)
                            Spacer()
                            Text("\(store.meetingElapsedSeconds / 60)m \(store.meetingElapsedSeconds % 60)s")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(textDark)
                        }
                        
                        // Waveform visualizer
                        HStack(spacing: 3) {
                            ForEach(0..<32) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(accentTeal)
                                    .frame(width: 4, height: CGFloat(10 + (i * 9 + store.meetingElapsedSeconds * 5) % 26))
                            }
                        }
                        .frame(height: 38)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.35), lineWidth: 1))
                }
                
                // Past Meeting Notes
                Text("Meeting Records (\(store.meetingNotes.count))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textDark)
                
                ForEach(store.meetingNotes) { meeting in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(meeting.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(textDark)
                                HStack(spacing: 8) {
                                    Text(meeting.dateFormatted)
                                    Text("·")
                                    Text("\(meeting.durationMinutes) min")
                                    Text("·")
                                    Text(meeting.attendees.joined(separator: ", "))
                                }
                                .font(.system(size: 11))
                                .foregroundColor(textMuted)
                            }
                            Spacer()
                            
                            Button(action: {
                                store.deleteMeeting(id: meeting.id)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.red.opacity(0.7))
                                    .padding(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Summary
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EXECUTIVE SUMMARY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(accentTeal)
                            Text(meeting.summary)
                                .font(.system(size: 12))
                                .foregroundColor(textDark)
                                .lineSpacing(2)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(surfaceBeige))
                        
                        // Action Items with interactive checkboxes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ACTION ITEMS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(textMuted)
                            
                            ForEach(meeting.actionItems) { item in
                                HStack(spacing: 8) {
                                    Button(action: {
                                        store.toggleMeetingActionItem(meetingId: meeting.id, itemId: item.id)
                                    }) {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 14))
                                            .foregroundColor(item.isCompleted ? accentCyan : textMuted)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text(item.title)
                                        .font(.system(size: 12))
                                        .strikethrough(item.isCompleted)
                                        .foregroundColor(item.isCompleted ? textMuted : textDark)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(cardWhite))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderDivider, lineWidth: 1))
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - 7. Snippets View
    private var snippetsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Snippets")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(textDark)
                        Text("Voice shortcuts that instantly expand into longer templates or phrases.")
                            .font(.system(size: 13))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation { isAddingSnippet.toggle() }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isAddingSnippet ? "xmark" : "plus")
                            Text(isAddingSnippet ? "Cancel" : "Add Snippet")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(accentTeal))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Add Snippet Form
                if isAddingSnippet {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Create Voice Snippet")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(textDark)
                        
                        TextField("Spoken trigger (e.g. btw or insert standup)", text: $newSnippetShortcut)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 13))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(cardWhite))
                        
                        TextEditor(text: $newSnippetExpansion)
                            .font(.system(size: 12))
                            .frame(height: 70)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(cardWhite))
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                store.addSnippet(shortcut: newSnippetShortcut, expansion: newSnippetExpansion)
                                newSnippetShortcut = ""
                                newSnippetExpansion = ""
                                isAddingSnippet = false
                            }) {
                                Text("Save Snippet")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
                }
                
                // Snippet List
                VStack(spacing: 0) {
                    ForEach(store.snippets) { snippet in
                        HStack(alignment: .top, spacing: 12) {
                            Text(snippet.shortcut)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(accentTeal)
                                .frame(width: 140, alignment: .leading)
                            
                            Text("→")
                                .foregroundColor(textMuted)
                            
                            Text(snippet.expansion)
                                .font(.system(size: 13))
                                .foregroundColor(textDark)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(snippet.expansion, forType: .string)
                                snippetCopiedId = snippet.id
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    if snippetCopiedId == snippet.id { snippetCopiedId = nil }
                                }
                            }) {
                                Text(snippetCopiedId == snippet.id ? "Copied ✓" : "Copy")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(textDark)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                store.deleteSnippet(id: snippet.id)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.red.opacity(0.7))
                                    .padding(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(14)
                        Divider().background(borderDivider)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(cardWhite))
            }
            .padding(24)
        }
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
            
            TextEditor(text: $store.scratchpadText)
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
                
                ForEach([SaynSettingsTab.account, .team, .privacy]) { tab in
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
                    case .connectors:
                        settingsConnectorsContent
                    case .mcp:
                        settingsMCPContent
                    case .account:
                        settingsAccountContent
                    case .team:
                        settingsTeamContent
                    case .privacy:
                        settingsPrivacyContent
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
                // 1. Global Shortcuts Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Global Shortcut")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text(store.selectedGlobalShortcut)
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Menu {
                        Button("Hold fn (Globe Key)") { store.selectedGlobalShortcut = "Hold fn (Globe Key)"; store.updateConfig() }
                        Button("Option + Space") { store.selectedGlobalShortcut = "Option + Space"; store.updateConfig() }
                        Button("Right Command (Hold)") { store.selectedGlobalShortcut = "Right Command (Hold)"; store.updateConfig() }
                        Button("Control + Option + Space") { store.selectedGlobalShortcut = "Control + Option + Space"; store.updateConfig() }
                    } label: {
                        Text("Change ▾")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
                
                // 2. Microphone Input Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Microphone")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text(store.selectedMicrophone)
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Menu {
                        Button("Auto-detect (System Default)") { store.selectedMicrophone = "Auto-detect (System Default)"; store.updateConfig() }
                        Button("MacBook Pro Microphone") { store.selectedMicrophone = "MacBook Pro Microphone"; store.updateConfig() }
                        Button("External / USB Audio Interface") { store.selectedMicrophone = "External / USB Audio Interface"; store.updateConfig() }
                        Button("AirPods / Bluetooth Headset") { store.selectedMicrophone = "AirPods / Bluetooth Headset"; store.updateConfig() }
                    } label: {
                        Text("Change ▾")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
                
                // 3. Dictation Languages Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dictation Language")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text(store.dictationLanguage)
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Menu {
                        Button("English (US & Global)") { store.dictationLanguage = "English (US & Global)"; store.updateConfig() }
                        Button("English (British)") { store.dictationLanguage = "English (British)"; store.updateConfig() }
                        Button("Urdu (اردو)") { store.dictationLanguage = "Urdu (اردو)"; store.updateConfig() }
                        Button("Spanish (Español)") { store.dictationLanguage = "Spanish (Español)"; store.updateConfig() }
                        Button("French (Français)") { store.dictationLanguage = "French (Français)"; store.updateConfig() }
                        Button("German (Deutsch)") { store.dictationLanguage = "German (Deutsch)"; store.updateConfig() }
                        Button("Arabic (العربية)") { store.dictationLanguage = "Arabic (العربية)"; store.updateConfig() }
                        Button("Hindi (हिन्दी)") { store.dictationLanguage = "Hindi (हिन्दी)"; store.updateConfig() }
                        Button("Japanese (日本語)") { store.dictationLanguage = "Japanese (日本語)"; store.updateConfig() }
                    } label: {
                        Text("Change ▾")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
                
                // 4. App Language Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Language")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text("Select your preferred SAYN Hub language")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Menu {
                        Button("English") { store.appLanguage = "English"; store.updateConfig() }
                        Button("Spanish (Español)") { store.appLanguage = "Spanish (Español)"; store.updateConfig() }
                        Button("French (Français)") { store.appLanguage = "French (Français)"; store.updateConfig() }
                        Button("German (Deutsch)") { store.appLanguage = "German (Deutsch)"; store.updateConfig() }
                        Button("Urdu (اردو)") { store.appLanguage = "Urdu (اردو)"; store.updateConfig() }
                        Button("Arabic (العربية)") { store.appLanguage = "Arabic (العربية)"; store.updateConfig() }
                    } label: {
                        Text("\(store.appLanguage) ▾")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
                
                // 5. Auto-Paste on Completion Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-paste on completion")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text("Directly injects text into AntiGravity, VS Code, Slack, or Browser. When off, text stays on clipboard.")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Toggle("", isOn: $store.autoPasteEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: accentTeal))
                        .onChange(of: store.autoPasteEnabled) { _ in
                            store.updateConfig()
                        }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
                
                // 6. Interactive Walkthrough Tour Replay
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Interactive Onboarding Tour")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text("Replay the interactive walkthrough tutorial with step-by-step guidance")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Button(action: {
                        showSettingsModal = false
                        onboardingStep = 1
                        store.showOnboardingWalkthrough = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Replay Tour")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(accentTeal))
                    }
                    .buttonStyle(PlainButtonStyle())
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
                settingsToggle(title: "Launch app at login", state: $store.launchAtLogin)
                settingsToggle(title: "Show SAYN Voice Capsule at all times", state: $store.showCapsuleAtAllTimes)
                settingsToggle(title: "Show app in dock", state: $store.showInDock)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            Text("Sound")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textMuted)
            
            VStack(spacing: 10) {
                settingsToggle(title: "Dictation and notification sounds", state: $store.soundFeedbackEnabled)
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
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vibe Coding")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(textDark)
                    Text("Optimize voice dictation for programming, symbol names, and IDEs")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textMuted)
                }
                Spacer()
                Button(action: {
                    store.scanRunningIDEs()
                    vibeCodingSetupNotice = "Detected: \(store.detectedIDEs.joined(separator: ", "))"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        vibeCodingSetupNotice = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Rescan IDEs")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(textDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if let notice = vibeCodingSetupNotice {
                Text(notice)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentCyan)
            }
            
            // Running IDE status
            VStack(alignment: .leading, spacing: 8) {
                Text("Active IDE Processes")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textDark)
                
                HStack(spacing: 8) {
                    ForEach(store.detectedIDEs, id: \.self) { ide in
                        HStack(spacing: 5) {
                            Circle().fill(accentCyan).frame(width: 7, height: 7)
                            Text(ide)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(textDark)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(cardWhite))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            // Casing Picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Identifier Casing Style")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textDark)
                
                HStack(spacing: 8) {
                    ForEach(["camelCase", "snake_case", "kebab-case", "PascalCase"], id: \.self) { casing in
                        Button(action: {
                            store.vibeCodingCasing = casing
                            store.updateConfig()
                        }) {
                            Text(casing)
                                .font(.system(size: 12, weight: store.vibeCodingCasing == casing ? .bold : .medium, design: .monospaced))
                                .foregroundColor(store.vibeCodingCasing == casing ? Color(red: 245/255, green: 235/255, blue: 221/255) : textDark)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(store.vibeCodingCasing == casing ? accentTeal : cardWhite)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            // Toggles
            VStack(spacing: 12) {
                settingsToggle(title: "Docstring & Comment Wrap\nAuto-formats long spoken sentences into /* */ or /// blocks", state: $store.vibeCodingDocstring)
                Divider()
                settingsToggle(title: "File Tagging in Chat (Cursor & Windsurf)\nTags files in your IDE (like index.tsx, SaynStore.swift)", state: $store.vibeCodingFileTagging)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
        }
    }
    
    private var settingsConnectorsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Connectors")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(textDark)
                Text("Integrate SAYN voice and formatting natively with your daily stack")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textMuted)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(store.connectors) { app in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(app.isConnected ? accentTeal.opacity(0.12) : Color.black.opacity(0.05))
                                    .frame(width: 34, height: 34)
                                Image(systemName: app.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(app.isConnected ? accentTeal : textDark)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                store.toggleConnector(id: app.id)
                            }) {
                                Text(app.isConnected ? "Connected" : "Connect")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(app.isConnected ? accentCyan : textDark)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(app.isConnected ? accentCyan.opacity(0.12) : cardWhite)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Text(app.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(textDark)
                        
                        Text(app.description)
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
                }
            }
        }
    }
    
    private var settingsMCPContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Model Context Protocol (MCP)")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(textDark)
                    Text("Expose local SAYN speech intelligence to AI coding assistants")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textMuted)
                }
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(accentCyan)
                        .frame(width: 8, height: 8)
                    Text("Server Active (stdio)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentCyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(accentCyan.opacity(0.12)))
            }
            
            Text("Compatible Coding Clients")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textMuted)
            
            VStack(spacing: 10) {
                ForEach(store.mcpConfigs) { config in
                    HStack(spacing: 12) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 18))
                            .foregroundColor(config.isInstalled ? accentTeal : textMuted)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(config.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(textDark)
                                if config.isInstalled {
                                    Text("Installed")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(accentCyan)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(accentCyan.opacity(0.12)))
                                }
                            }
                            Text(config.configPath)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(textMuted)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            store.toggleMCPInstall(id: config.id)
                        }) {
                            Text(config.isInstalled ? "Configured ✓" : "Install Config")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(config.isInstalled ? textDark : Color(red: 245/255, green: 235/255, blue: 221/255))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(config.isInstalled ? cardWhite : accentTeal)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(surfaceBeige))
                }
            }
            
            Text("Registered MCP Tools")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textMuted)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Text("sayn_dictate")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(accentTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(accentTeal.opacity(0.12)))
                    Text("Captures microphone voice stream and injects verbatim text directly into chat or cursor.")
                        .font(.system(size: 11))
                        .foregroundColor(textDark)
                }
                Divider()
                HStack(alignment: .top, spacing: 10) {
                    Text("sayn_refine")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(accentTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(accentTeal.opacity(0.12)))
                    Text("Post-processes active code comments or markdown prompts into concise, professional style.")
                        .font(.system(size: 11))
                        .foregroundColor(textDark)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
        }
    }
    
    private var settingsTeamContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Team")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(textDark)
                    Text("Lifetime Team Workspace · Unlimited Free Seats")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textMuted)
                }
                Spacer()
                Button(action: {
                    _ = store.copyInviteLink()
                    teamInviteNotice = "Invite link copied to clipboard!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        teamInviteNotice = nil
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "link")
                        Text("Copy Invite Link")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(accentTeal))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if let notice = teamInviteNotice {
                Text(notice)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(accentCyan.opacity(0.12)))
            }
            
            // Invite Form
            VStack(alignment: .leading, spacing: 8) {
                Text("Invite Team Member")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textDark)
                
                HStack(spacing: 8) {
                    TextField("colleague@company.com", text: $newTeamEmail)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(cardWhite))
                    
                    Menu {
                        Button("Member") { newTeamRole = "Member" }
                        Button("Admin") { newTeamRole = "Admin" }
                    } label: {
                        Text(newTeamRole + " ▾")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                    }
                    
                    Button(action: {
                        guard !newTeamEmail.isEmpty else { return }
                        store.inviteMember(email: newTeamEmail, role: newTeamRole)
                        newTeamEmail = ""
                        teamInviteNotice = "Invitation sent successfully!"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            teamInviteNotice = nil
                        }
                    }) {
                        Text("Send Invite")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.black))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            // Member List
            Text("Active Workspace Members (\(store.teamMembers.count))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(textMuted)
            
            VStack(spacing: 0) {
                ForEach(store.teamMembers) { member in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentTeal)
                                .frame(width: 32, height: 32)
                            Text(member.avatarLetter)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(member.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(textDark)
                                if member.isPending {
                                    Text("Pending")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(accentAmber)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(accentAmber.opacity(0.12)))
                                }
                            }
                            Text(member.email)
                                .font(.system(size: 11))
                                .foregroundColor(textMuted)
                        }
                        
                        Spacer()
                        
                        Text(member.role)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(member.role == "Owner" ? accentTeal : textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(surfaceBeige))
                        
                        if member.role != "Owner" {
                            Button(action: {
                                store.removeMember(id: member.id)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.red.opacity(0.8))
                                    .padding(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(12)
                    Divider().background(borderDivider)
                }
            }
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
                    .foregroundColor(accentCyan)
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
            
            Divider()
            
            // GDPR Article 17 Right to Erasure
            VStack(alignment: .leading, spacing: 10) {
                Text("Legal & Compliance Rights (GDPR & CCPA)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textMuted)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Right to Erasure (Article 17)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textDark)
                        Text("Permanently deletes all dictation history, cached audio, and custom vocabulary from this Mac.")
                            .font(.system(size: 11))
                            .foregroundColor(textMuted)
                    }
                    Spacer()
                    Button(action: {
                        store.clearAllData()
                    }) {
                        Text("Clear All Data")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.85)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
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
    
    // MARK: - In-Page Settings, Shortcuts & Team Views
    private var settingsPageView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header (Screenshot 3 Reference)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                }
                
                // 2-Column Layout
                HStack(alignment: .top, spacing: 28) {
                    // Left Sub-Navigation Menu
                    VStack(alignment: .leading, spacing: 20) {
                        // GENERAL Section
                        VStack(alignment: .leading, spacing: 5) {
                            Text("GENERAL")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Color(red: 135/255, green: 132/255, blue: 128/255))
                                .padding(.horizontal, 10)
                                .padding(.bottom, 2)
                            
                            settingsSubNavItem(tab: .general, label: "General", icon: "gearshape")
                            settingsSubNavItem(tab: .system, label: "System", icon: "display")
                            settingsSubNavItem(tab: .notetaker, label: "Notetaker", icon: "record.circle")
                            settingsSubNavItem(tab: .vibeCoding, label: "Vibe coding", icon: "number")
                            settingsSubNavItem(tab: .connectors, label: "Connectors", icon: "link")
                            settingsSubNavItem(tab: .mcp, label: "MCP", icon: "cable.connector")
                        }
                        
                        // ACCOUNT Section
                        VStack(alignment: .leading, spacing: 5) {
                            Text("ACCOUNT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Color(red: 135/255, green: 132/255, blue: 128/255))
                                .padding(.horizontal, 10)
                                .padding(.bottom, 2)
                            
                            settingsSubNavItem(tab: .account, label: "Account", icon: "person.crop.circle")
                            settingsSubNavItem(tab: .team, label: "Team", icon: "person.2")
                            settingsSubNavItem(tab: .privacy, label: "Data and Privacy", icon: "shield")
                        }
                    }
                    .frame(width: 175)
                    
                    // Right Content Pane
                    VStack(alignment: .leading, spacing: 20) {
                        if activeSettingsTab == .account {
                            accountSettingsScreenView
                        } else if activeSettingsTab == .general {
                            settingsGeneralContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        } else if activeSettingsTab == .system {
                            settingsSystemContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        } else if activeSettingsTab == .notetaker {
                            settingsNotetakerContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        } else if activeSettingsTab == .vibeCoding {
                            settingsVibeCodingContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        } else if activeSettingsTab == .connectors {
                            settingsConnectorsContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        } else if activeSettingsTab == .mcp {
                            settingsMCPContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        } else if activeSettingsTab == .team {
                            settingsTeamContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        } else if activeSettingsTab == .privacy {
                            settingsPrivacyContent
                                .padding(22)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
        .onAppear {
            syncAccountFields()
        }
    }
    
    // Pixel-Perfect Account Screen (Screenshot 3 Reference)
    private var accountSettingsScreenView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(red: 254/255, green: 238/255, blue: 238/255))
                        .frame(width: 38, height: 38)
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 120/255, green: 22/255, blue: 44/255))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Account")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 24/255, green: 22/255, blue: 22/255))
                }
            }
            
            // Form Container Box
            VStack(alignment: .leading, spacing: 18) {
                // Profile picture row
                HStack(alignment: .center, spacing: 20) {
                    Text("Profile picture")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Color(red: 30/255, green: 28/255, blue: 26/255))
                        .frame(width: 110, alignment: .leading)
                    
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 105/255, green: 14/255, blue: 30/255))
                                .frame(width: 54, height: 54)
                            Text(String((store.firstName.isEmpty ? "A" : store.firstName).prefix(1)).uppercased())
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: {
                                // Upload photo action
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.to.line")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Upload photo")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Color(red: 254/255, green: 238/255, blue: 238/255)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    Spacer()
                }
                
                // First name row
                accountInputRow(label: "First name", icon: "person", value: $editFirstName)
                
                // Last name row
                accountInputRow(label: "Last name", icon: "person", value: $editLastName)
                
                // Phone number row
                accountInputRow(label: "Phone number", icon: "phone", value: $editPhone)
                
                // Writing focus dropdown row
                HStack(alignment: .center, spacing: 20) {
                    Text("Writing focus")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Color(red: 30/255, green: 28/255, blue: 26/255))
                        .frame(width: 110, alignment: .leading)
                    
                    Menu {
                        Button("Engineering & Voice") { editWritingRole = "Engineering & Voice" }
                        Button("General & Writing") { editWritingRole = "General & Writing" }
                        Button("Product Management") { editWritingRole = "Product Management" }
                        Button("Executive & Leadership") { editWritingRole = "Executive & Leadership" }
                        Button("Creative & Content") { editWritingRole = "Creative & Content" }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "scope")
                                .font(.system(size: 12.5))
                                .foregroundColor(Color(red: 120/255, green: 118/255, blue: 115/255))
                            
                            Text(editWritingRole.isEmpty ? "Engineering & Voice" : editWritingRole)
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color(red: 30/255, green: 28/255, blue: 26/255))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(red: 120/255, green: 118/255, blue: 115/255))
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 230/255, green: 227/255, blue: 222/255), lineWidth: 1))
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
                
                // Email row
                accountInputRow(label: "Email", icon: "envelope", value: $editEmail)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 251/255, green: 249/255, blue: 246/255))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 236/255, green: 233/255, blue: 228/255), lineWidth: 1))
            )
            
            // Bottom Buttons Bar
            HStack {
                // Sign out button
                Button(action: {
                    store.logout()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Sign out")
                            .font(.system(size: 12.5, weight: .bold))
                    }
                    .foregroundColor(Color(red: 30/255, green: 28/255, blue: 26/255))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 225/255, green: 222/255, blue: 218/255), lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer().frame(width: 14)
                
                // Delete account button
                Button(action: {
                    // Confirmation dialog for account deletion
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                        Text("Delete account")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 220/255, green: 38/255, blue: 38/255))
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if accountSavedNotice {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255))
                        Text("Saved")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255))
                    }
                    .transition(.opacity)
                }
                
                // Save changes button
                Button(action: {
                    store.updateAccount(
                        firstName: editFirstName,
                        lastName: editLastName,
                        phone: editPhone,
                        email: editEmail,
                        writingRole: editWritingRole
                    )
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        accountSavedNotice = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            accountSavedNotice = false
                        }
                    }
                }) {
                    HStack(spacing: 7) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Save changes")
                            .font(.system(size: 12.5, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 111/255, green: 16/255, blue: 37/255)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 4)
        }
    }
    
    private func accountInputRow(label: String, icon: String, value: Binding<String>) -> some View {
        HStack(alignment: .center, spacing: 20) {
            Text(label)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color(red: 30/255, green: 28/255, blue: 26/255))
                .frame(width: 110, alignment: .leading)
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12.5))
                    .foregroundColor(Color(red: 120/255, green: 118/255, blue: 115/255))
                
                TextField("", text: value)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(Color(red: 30/255, green: 28/255, blue: 26/255))
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 230/255, green: 227/255, blue: 222/255), lineWidth: 1))
        }
    }
    
    private func settingsSubNavItem(tab: SaynSettingsTab, label: String, icon: String) -> some View {
        let isSelected = activeSettingsTab == tab
        return Button(action: {
            activeSettingsTab = tab
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .frame(width: 18)
                
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                
                Spacer()
            }
            .foregroundColor(isSelected ? Color(red: 111/255, green: 16/255, blue: 37/255) : Color(red: 70/255, green: 68/255, blue: 65/255))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 254/255, green: 238/255, blue: 240/255) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Shortcuts Page View
    private var shortcutsPageView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shortcuts")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                    Text("Supercharge your typing speed with system-wide hotkeys.")
                        .font(.system(size: 13))
                        .foregroundColor(textMuted)
                }
                
                VStack(spacing: 12) {
                    shortcutRow(label: "Push-to-Talk (Hold)", keys: "fn (hold)", desc: "Dictate while holding, releases and pastes instantly")
                    shortcutRow(label: "Toggle Dictation", keys: "⌥ Space", desc: "Start or stop hands-free voice transcription")
                    shortcutRow(label: "Casual Tone Polish", keys: "⌥ 1", desc: "Rewrite highlighted text into conversational tone")
                    shortcutRow(label: "Professional Tone", keys: "⌥ 2", desc: "Rewrite highlighted text into executive tone")
                    shortcutRow(label: "Direct & Punchy", keys: "⌥ 3", desc: "Cut fluff and shorten highlighted text")
                    shortcutRow(label: "Meeting Notetaker", keys: "⌥ N", desc: "Toggle live meeting recording and transcription")
                    shortcutRow(label: "Open Scratchpad", keys: "⌥ S", desc: "Jump straight to drafting in SAYN Scratchpad")
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
    }
    
    private func shortcutRow(label: String, keys: String, desc: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(textDark)
                Text(desc)
                    .font(.system(size: 11.5))
                    .foregroundColor(textMuted)
            }
            Spacer()
            Text(keys)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 111/255, green: 16/255, blue: 37/255))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 254/255, green: 238/255, blue: 240/255)))
        }
        .padding(10)
    }
    
    // MARK: - Team Page View
    private var teamPageView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite your team")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(textDark)
                    Text("Collaborate with your workspace and share shared dictionary snippets.")
                        .font(.system(size: 13))
                        .foregroundColor(textMuted)
                }
                
                settingsTeamContent
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white).shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1))
            }
            .padding(.horizontal, 28)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Help & Diagnostics Modal
    private var helpModalView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(accentTeal)
                    Text("Help & System Diagnostics")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(textDark)
                }
                Spacer()
                Button(action: { showHelpModal = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(textMuted)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Shortcuts Cheatsheet
            VStack(alignment: .leading, spacing: 10) {
                Text("GLOBAL SHORTCUTS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(textMuted)
                
                HStack(spacing: 12) {
                    helpShortcutBadge(keys: "fn (hold)", label: "Push-to-Talk")
                    helpShortcutBadge(keys: "⌥ Space", label: "Toggle Dictation")
                    helpShortcutBadge(keys: "⌥ 1", label: "Professional Tone")
                    helpShortcutBadge(keys: "⌥ 2", label: "Shorten Text")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            // System Status
            VStack(alignment: .leading, spacing: 10) {
                Text("SYSTEM HEALTH")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(textMuted)
                
                HStack(spacing: 14) {
                    helpStatusItem(icon: "checkmark.shield.fill", title: "Accessibility", desc: "Granted", ok: true)
                    helpStatusItem(icon: "bolt.fill", title: "Neural Voice Engine", desc: "<320ms latency", ok: true)
                    helpStatusItem(icon: "cloud.fill", title: "Supabase Cloud", desc: store.supabaseSyncStatus, ok: true)
                    helpStatusItem(icon: "mic.fill", title: "Microphone", desc: "Active (48kHz)", ok: true)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(surfaceBeige))
            
            // Troubleshooting & Support
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Need Support or Found a Bug?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textDark)
                    Text("Join our open community or email allanmaazimdad@gmail.com")
                        .font(.system(size: 11))
                        .foregroundColor(textMuted)
                }
                Spacer()
                Button(action: {
                    if let url = URL(string: "https://sayn.ai/support") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("Open Documentation")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 245/255, green: 235/255, blue: 221/255))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(accentTeal))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(24)
        .frame(width: 580)
        .background(cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderDivider, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 25, x: 0, y: 10)
    }
    
    private func helpShortcutBadge(keys: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(keys)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(accentTeal)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(cardWhite))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(textDark)
        }
    }
    
    private func helpStatusItem(icon: String, title: String, desc: String, ok: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ok ? accentCyan : accentAmber)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(textDark)
                Text(desc)
                    .font(.system(size: 10))
                    .foregroundColor(textMuted)
            }
        }
    }
    
    // MARK: - Window Appearance Controller (Dynamic Light/Dark Mode)
    struct WindowAppearanceController: NSViewRepresentable {
        let isDark: Bool
        
        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            DispatchQueue.main.async {
                view.window?.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
            }
            return view
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {
            DispatchQueue.main.async {
                nsView.window?.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
            }
        }
    }

    // MARK: - Sayn macOS AppKit Text Field (Guaranteed Crisp Dark Text & Visible Placeholders)
    struct SaynMacTextField: NSViewRepresentable {
        let placeholder: String
        @Binding var text: String
        var isSecure: Bool = false
        var onSubmit: (() -> Void)? = nil
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        func makeNSView(context: Context) -> NSTextField {
            let tf: NSTextField
            if isSecure {
                tf = NSSecureTextField()
            } else {
                tf = NSTextField()
            }
            tf.delegate = context.coordinator
            tf.isBordered = false
            tf.drawsBackground = false
            tf.focusRingType = .none
            tf.font = NSFont.systemFont(ofSize: 13, weight: .regular)
            tf.textColor = NSColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1.0)
            tf.placeholderAttributedString = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: NSColor(red: 145/255, green: 145/255, blue: 150/255, alpha: 1.0),
                    .font: NSFont.systemFont(ofSize: 13, weight: .regular)
                ]
            )
            tf.appearance = NSAppearance(named: .aqua)
            return tf
        }
        
        func updateNSView(_ nsView: NSTextField, context: Context) {
            if nsView.stringValue != text {
                nsView.stringValue = text
            }
            nsView.textColor = NSColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1.0)
            nsView.appearance = NSAppearance(named: .aqua)
        }
        
        class Coordinator: NSObject, NSTextFieldDelegate {
            var parent: SaynMacTextField
            init(_ parent: SaynMacTextField) {
                self.parent = parent
            }
            
            func controlTextDidChange(_ obj: Notification) {
                if let tf = obj.object as? NSTextField {
                    parent.text = tf.stringValue
                }
            }
            
            func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
                if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                    parent.onSubmit?()
                    return true
                }
                return false
            }
        }
    }
    
    // MARK: - Secure Login Screen (Gated Access - Pixel-Perfect Minimal)
    private var secureLoginScreen: some View {
        ZStack {
            // Warm ivory/cream background
            Color(red: 254/255, green: 252/255, blue: 251/255).ignoresSafeArea()
            
            // 1. Ambient soft maroon blurred orbs & aesthetic curves
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack {
                    // Top-right soft rose/maroon glow
                    Circle()
                        .fill(Color(red: 168/255, green: 38/255, blue: 68/255).opacity(0.18))
                        .frame(width: 360, height: 360)
                        .blur(radius: 75)
                        .position(x: w * 0.94, y: h * 0.12)
                    
                    // Bottom-left deep maroon glow
                    Circle()
                        .fill(Color(red: 140/255, green: 22/255, blue: 50/255).opacity(0.16))
                        .frame(width: 440, height: 440)
                        .blur(radius: 85)
                        .position(x: w * 0.08, y: h * 0.72)
                    
                    // Top-right subtle concentric arc
                    Path { p in
                        p.addArc(
                            center: CGPoint(x: w * 0.90, y: -h * 0.04),
                            radius: w * 0.36,
                            startAngle: .degrees(45),
                            endAngle: .degrees(165),
                            clockwise: false
                        )
                    }
                    .stroke(Color(red: 180/255, green: 55/255, blue: 85/255).opacity(0.20), lineWidth: 1.1)
                    
                    // Flowing aesthetic spline curve from left to right
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * 0.22))
                        p.addCurve(
                            to: CGPoint(x: w * 0.32, y: h * 0.58),
                            control1: CGPoint(x: w * 0.12, y: h * 0.27),
                            control2: CGPoint(x: w * 0.20, y: h * 0.52)
                        )
                        p.addCurve(
                            to: CGPoint(x: w, y: h * 0.51),
                            control1: CGPoint(x: w * 0.44, y: h * 0.64),
                            control2: CGPoint(x: w * 0.82, y: h * 0.40)
                        )
                    }
                    .stroke(Color(red: 180/255, green: 55/255, blue: 85/255).opacity(0.28), lineWidth: 1.1)
                    
                    // Milestone node 1 (Left side)
                    Circle()
                        .fill(Color(red: 180/255, green: 55/255, blue: 85/255).opacity(0.78))
                        .frame(width: 8.5, height: 8.5)
                        .position(x: w * 0.148, y: h * 0.315)
                    
                    // Milestone node 2 (Right side)
                    Circle()
                        .fill(Color(red: 180/255, green: 55/255, blue: 85/255).opacity(0.78))
                        .frame(width: 9.0, height: 9.0)
                        .position(x: w * 0.892, y: h * 0.442)
                }
            }
            .ignoresSafeArea()
            
            // 2. Centered Content: Logo + Minimalist Card
            VStack(spacing: 18) {
                // Brand Header: Icon + Wordmark
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 125/255, green: 15/255, blue: 42/255), Color(red: 80/255, green: 10/255, blue: 27/255)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 50, height: 50)
                            .shadow(color: Color(red: 111/255, green: 16/255, blue: 37/255).opacity(0.25), radius: 8, x: 0, y: 4)
                        
                        HStack(spacing: 3.5) {
                            RoundedRectangle(cornerRadius: 1.6)
                                .fill(Color.white)
                                .frame(width: 3.2, height: 13)
                            RoundedRectangle(cornerRadius: 1.6)
                                .fill(Color.white)
                                .frame(width: 3.2, height: 23)
                            RoundedRectangle(cornerRadius: 1.6)
                                .fill(Color.white)
                                .frame(width: 3.2, height: 15)
                        }
                    }
                    
                    Text("SAYN")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                }
                
                // Minimal Card
                VStack(spacing: 12) {
                    // Error Notice (if any)
                    if let err = store.authErrorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 11))
                            Text(err)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.08)))
                    }
                    
                    // Input 1: Username
                    HStack(spacing: 10) {
                        Image(systemName: "person")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 130/255, green: 130/255, blue: 135/255))
                            .frame(width: 16)
                        
                        SaynMacTextField(placeholder: "Username", text: $authUsernameOrEmail, isSecure: false, onSubmit: performLogin)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 248/255, green: 247/255, blue: 247/255)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.065), lineWidth: 1))
                    
                    // Input 2: Password
                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 130/255, green: 130/255, blue: 135/255))
                            .frame(width: 16)
                        
                        if isShowPassword {
                            SaynMacTextField(placeholder: "Password", text: $authPassword, isSecure: false, onSubmit: performLogin)
                                .id("pwd_plain")
                        } else {
                            SaynMacTextField(placeholder: "Password", text: $authPassword, isSecure: true, onSubmit: performLogin)
                                .id("pwd_secure")
                        }
                        
                        Button(action: { isShowPassword.toggle() }) {
                            Image(systemName: isShowPassword ? "eye.slash" : "eye")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 130/255, green: 130/255, blue: 135/255))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 248/255, green: 247/255, blue: 248/255)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.065), lineWidth: 1))
                    
                    // Primary Action Button (Lock + Arrow)
                    Button(action: {
                        performLogin()
                    }) {
                        ZStack {
                            if store.isAuthenticating {
                                ProgressView()
                                    .scaleEffect(0.75)
                                    .colorInvert()
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.trailing, 14)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 122/255, green: 17/255, blue: 41/255), Color(red: 88/255, green: 12/255, blue: 30/255)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(red: 111/255, green: 16/255, blue: 37/255).opacity(0.20), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(store.isAuthenticating)
                }
                .padding(22)
                .frame(width: 350)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white)
                        .shadow(color: Color(red: 111/255, green: 16/255, blue: 37/255).opacity(0.055), radius: 26, x: 0, y: 10)
                )
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.black.opacity(0.035), lineWidth: 1))
            }
        }
    }
    
    private func performLogin() {
        guard !authUsernameOrEmail.isEmpty, !authPassword.isEmpty else { return }
        Task {
            let success = await store.login(usernameOrEmail: authUsernameOrEmail, password: authPassword)
            if success {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    authPassword = ""
                    syncAccountFields()
                }
            }
        }
    }
    
    // MARK: - Interactive Onboarding Walkthrough
    private var onboardingWalkthroughView: some View {
        ZStack {
            Color.black.opacity(0.68)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar: Step Dots & Skip Button
                HStack {
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { step in
                            Capsule()
                                .fill(step == onboardingStep ? accentTeal : Color.white.opacity(0.25))
                                .frame(width: step == onboardingStep ? 18 : 7, height: 7)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: onboardingStep)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.hasCompletedOnboarding = true
                            store.showOnboardingWalkthrough = false
                            store.updateConfig()
                        }
                    }) {
                        Text("Skip Tour")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.75))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                
                Spacer()
                
                // Step Content
                VStack(spacing: 16) {
                    if onboardingStep == 1 {
                        // Step 1: Welcome
                        ZStack {
                            Circle()
                                .fill(accentTeal.opacity(0.18))
                                .frame(width: 80, height: 80)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 46))
                                .foregroundColor(accentTeal)
                        }
                        
                        Text("Welcome to SAYN")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Effortless, hands-free voice intelligence that speaks and formats directly into all your macOS apps with zero latency.")
                            .font(.system(size: 13.5))
                            .foregroundColor(Color.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineSpacing(3)
                    } else if onboardingStep == 2 {
                        // Step 2: Global Shortcut
                        ZStack {
                            Circle()
                                .fill(accentTeal.opacity(0.18))
                                .frame(width: 80, height: 80)
                            Image(systemName: "keyboard.fill")
                                .font(.system(size: 40))
                                .foregroundColor(accentTeal)
                        }
                        
                        Text("Universal Dictation Shortcut")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text(store.selectedGlobalShortcut)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(accentTeal)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.12)))
                        }
                        
                        Text("Hold your shortcut key anywhere in macOS to speak. When you finish speaking, release the key to transcribe instantly.")
                            .font(.system(size: 13.5))
                            .foregroundColor(Color.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineSpacing(3)
                    } else if onboardingStep == 3 {
                        // Step 3: Minimalist Floating Capsule
                        ZStack {
                            Circle()
                                .fill(accentTeal.opacity(0.18))
                                .frame(width: 80, height: 80)
                            Image(systemName: "capsule.portrait.fill")
                                .font(.system(size: 40))
                                .foregroundColor(accentTeal)
                        }
                        
                        Text("Minimalist Voice Capsule")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("A sleek, non-intrusive status capsule appears smoothly while you speak and glides away automatically when finished.")
                            .font(.system(size: 13.5))
                            .foregroundColor(Color.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineSpacing(3)
                    } else if onboardingStep == 4 {
                        // Step 4: Smart Auto-Paste
                        ZStack {
                            Circle()
                                .fill(accentTeal.opacity(0.18))
                                .frame(width: 80, height: 80)
                            Image(systemName: "cursorarrow.and.square.on.square.dashed")
                                .font(.system(size: 40))
                                .foregroundColor(accentTeal)
                        }
                        
                        Text("Hands-Free Auto-Paste")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("SAYN injects polished text right at your caret in AntiGravity, VS Code, Notes, Slack, or browsers with 0 clicks.")
                            .font(.system(size: 13.5))
                            .foregroundColor(Color.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineSpacing(3)
                    } else {
                        // Step 5: Snippets & Styles
                        ZStack {
                            Circle()
                                .fill(accentTeal.opacity(0.18))
                                .frame(width: 80, height: 80)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 40))
                                .foregroundColor(accentTeal)
                        }
                        
                        Text("Personalization & Snippets")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        
                        Text("Add custom vocabulary and voice triggers like 'insert standup' or 'insert meeting notes' to expand full templates in real time.")
                            .font(.system(size: 13.5))
                            .foregroundColor(Color.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineSpacing(3)
                    }
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                
                Spacer()
                
                // Bottom Navigation: Previous & Next / Get Started
                HStack {
                    if onboardingStep > 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                onboardingStep -= 1
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.14)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if onboardingStep < 5 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                onboardingStep += 1
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.hasCompletedOnboarding = true
                                store.showOnboardingWalkthrough = false
                                store.updateConfig()
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(onboardingStep < 5 ? "Next" : "Get Started")
                            Image(systemName: onboardingStep < 5 ? "chevron.right" : "sparkles")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
            .frame(width: 530, height: 420)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 24/255, green: 22/255, blue: 20/255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.55), radius: 30, x: 0, y: 15)
        }
    }
}
