import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NativeAppView()
    }
}

private struct Garment: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let type: String
    let color: String
    let season: String
    let imageUrl: String
    let wearCount: Int
}

private let previewRootPath = "/Users/mark/Desktop/PiedraRojaGroup/mydailycloset/Mydailycloset_APP"

private struct SuggestedLook: Identifiable {
    let id: String
    let title: String
    let pieces: [String]
}

private struct GarmentResponse: Decodable {
    let id: String
    let name: String
    let category: String
    let type: String
    let color: String
    let season: String
    let imageUrl: String?
    let wearCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case type
        case season
        case imageUrl
        case wearCount
        case color
        case colors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        type = try container.decode(String.self, forKey: .type)
        season = try container.decodeIfPresent(String.self, forKey: .season) ?? ""
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        wearCount = try container.decodeIfPresent(Int.self, forKey: .wearCount)

        if let directColor = try container.decodeIfPresent(String.self, forKey: .color), !directColor.isEmpty {
            color = directColor
        } else if let colors = try container.decodeIfPresent([String].self, forKey: .colors), let first = colors.first {
            color = first
        } else {
            color = ""
        }
    }
}

private struct NativeClosetResponse: Decodable {
    let items: [GarmentResponse]
}

private struct PreviewStoreFile: Decodable {
    let closetItems: [GarmentResponse]
}

private struct PreviewStoreWritable: Codable {
    var closetItems: [PreviewStoredItem]
    var profile: PreviewProfileRecord?
}

private struct PreviewProfileRecord: Codable {
    var gender: String?
    var occupation: String?
    var city: String?
    var preferredStyle: String?
    var commonOccasions: String?
}

private struct PreviewStoredItem: Codable {
    let name: String
    let type: String
    let category: String
    let colors: [String]
    let style: String
    let tone: String
    let imageHint: String
    let note: String
    let season: String
    let formality: String
    let occasions: String
    let material: String
    let imageUrl: String
    let id: String
    let createdAt: String
    let wearCount: Int?
}

private enum NativeTab: Hashable {
    case closet
    case add
    case stylist
    case sell
}

private struct NativeAppView: View {
    @State private var selectedTab: NativeTab = .closet
    @State private var selectedFilter: String = "All"
    @State private var garments: [Garment] = []
    @State private var isLoading = true
    @State private var loadError = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isSaving = false
    @State private var addStatusMessage = ""
    @State private var pendingImageData: Data?
    @State private var draftCategory = "Top"
    @State private var draftType = "Shirt"
    @State private var draftColor = "Neutral"
    @State private var draftSeason = "All season"
    @State private var selectedOccasion = "Office"
    @State private var lookRotation = 0
    @State private var stylistStatusMessage = ""
    @State private var expandedDraftID: String?
    @State private var copiedDraftID: String?
    @State private var selectedGarment: Garment?
    @State private var closetStatusMessage = ""

    private let filters = ["All", "Top", "Bottom", "Outerwear", "Shoes", "Spring", "Summer", "Autumn"]
    private let horizontalPadding: CGFloat = 20
    private let addCategories = ["Top", "Bottom", "Outerwear", "Shoes"]
    private let addColors = ["Neutral", "Black", "White", "Brown", "Blue"]
    private let addSeasons = ["All season", "Spring", "Summer", "Autumn", "Winter"]
    private let occasions = ["Office", "Weekend", "Dinner", "Travel"]

    private var filteredGarments: [Garment] {
        guard selectedFilter != "All" else { return garments }
        return garments.filter { $0.category == selectedFilter || $0.season == selectedFilter }
    }

    private var suggestedLooks: [SuggestedLook] {
        let tops = garments.filter { $0.category == "Top" }
        let bottoms = garments.filter { $0.category == "Bottom" }
        let outerwear = garments.filter { $0.category == "Outerwear" }
        let shoes = garments.filter { $0.category == "Shoes" }

        var looks: [SuggestedLook] = []

        let topChoices = rotated(tops)
        let bottomChoices = rotated(bottoms)
        let outerwearChoices = rotated(outerwear)
        let shoeChoices = rotated(shoes)

        if let top = topChoices.first, let bottom = bottomChoices.first {
            looks.append(
                SuggestedLook(
                    id: "office",
                    title: selectedOccasion,
                    pieces: [top.name, bottom.name] + outerwearChoices.prefix(selectedOccasion == "Office" || selectedOccasion == "Travel" ? 1 : 0).map(\.name)
                )
            )
        }

        if let top = topChoices.dropFirst().first ?? topChoices.first, let bottom = bottomChoices.dropFirst().first ?? bottomChoices.first {
            looks.append(
                SuggestedLook(
                    id: "weekend",
                    title: selectedOccasion == "Weekend" ? "Easy swap" : "Alternate",
                    pieces: [top.name, bottom.name] + shoeChoices.prefix(1).map(\.name)
                )
            )
        }

        if let top = topChoices.last ?? topChoices.first, let bottom = bottomChoices.last ?? bottomChoices.first, let shoe = shoeChoices.first {
            looks.append(
                SuggestedLook(
                    id: "travel",
                    title: selectedOccasion == "Dinner" ? "Evening option" : "Third look",
                    pieces: [top.name, bottom.name, shoe.name]
                )
            )
        }

        return Array(looks.prefix(3))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "EFE8DF"), Color(hex: "E7DED4")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .closet:
                    closetView
                case .add:
                    addView
                case .stylist:
                    stylistView
                case .sell:
                    sellView
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 14)
            .padding(.bottom, 112)
            .task {
                await loadGarments()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                guard let newValue else { return }
                Task {
                    await preparePhoto(newValue)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraCaptureView { data in
                    Task { @MainActor in
                        prepareSelectedImageData(data)
                    }
                }
                .ignoresSafeArea()
            }

            nativeTabBar
        }
    }

    private var closetView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header(eyebrow: "Wardrobe", title: "Closet", subtitle: "Your essentials, organized simply.")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Text(filter)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(selectedFilter == filter ? .white : Color(hex: "6E655D"))
                                    .padding(.horizontal, 16)
                                    .frame(height: 38)
                                    .background(
                                        Capsule()
                                            .fill(selectedFilter == filter ? Color(hex: "B4A494") : Color.white.opacity(0.55))
                                    )
                            }
                        }
                    }
                    .padding(7)
                    .background(.white.opacity(0.26), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                if isLoading {
                    loadingPanel("Loading your closet")
                } else if loadError {
                    emptyPanel(
                        title: "Unable to load closet",
                        subtitle: "Check the local preview service and try again."
                    )
                } else if filteredGarments.isEmpty {
                    emptyPanel(
                        title: "No pieces yet",
                        subtitle: "Add your first piece to start building the closet."
                    )
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(filteredGarments) { item in
                            Button {
                                selectedGarment = item
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    garmentImage(item)
                                        .frame(height: 176)

                                    Text(item.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color(hex: "4B433C"))
                                        .lineLimit(1)

                                    HStack(alignment: .center) {
                                        Text("\(item.type) · \(item.color)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Color(hex: "857A71"))
                                        Spacer()
                                        if item.wearCount > 0 {
                                            Text("\(item.wearCount)x")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(Color(hex: "8A7F74"))
                                        }
                                    }
                                }
                                .padding(14)
                                .background(.white.opacity(0.32), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !closetStatusMessage.isEmpty {
                    emptyPanel(title: "Closet updated", subtitle: closetStatusMessage)
                }
            }
        }
        .sheet(item: $selectedGarment) { garment in
            GarmentEditorSheet(
                garment: garment,
                onClose: {
                    selectedGarment = nil
                },
                onSave: { name, category, type, color, season in
                    Task {
                        await updateGarment(
                            id: garment.id,
                            name: name,
                            category: category,
                            type: type,
                            color: color,
                            season: season
                        )
                    }
                },
                onDelete: {
                    Task {
                        await deleteGarment(id: garment.id)
                    }
                }
            )
        }
    }

    private var addView: some View {
        VStack(alignment: .leading, spacing: 20) {
            header(eyebrow: "Capture", title: "Add", subtitle: "One piece at a time.")

            Spacer(minLength: 6)

            VStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(.white.opacity(0.3))
                    .overlay(
                        Group {
                            if let image = pendingPreviewImage {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .padding(16)
                            } else {
                                VStack(spacing: 14) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 48, weight: .medium))
                                        .foregroundStyle(Color(hex: "6A615A"))
                                    Text(isSaving ? "Saving piece" : "Tap to add a piece")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color(hex: "7D736A"))
                                }
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.82, contentMode: .fit)

                HStack(spacing: 12) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showingCamera = true
                        } else {
                            addStatusMessage = "Camera is unavailable here. Use Library."
                        }
                    } label: {
                        softButton("Camera", filled: true)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        softButton("Library", filled: false)
                    }
                    .disabled(isSaving)
                }

                if pendingImageData != nil {
                    addEditorPanel
                }

                if isSaving {
                    loadingPanel("Saving to your closet")
                } else if !addStatusMessage.isEmpty {
                    emptyPanel(
                        title: "Saved",
                        subtitle: addStatusMessage
                    )
                }
            }

            Spacer()
        }
    }

    private var stylistView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header(eyebrow: "Today", title: "Stylist", subtitle: "Mild 18-24°C")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(occasions, id: \.self) { option in
                            Button {
                                selectedOccasion = option
                            } label: {
                                Text(option)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(option == selectedOccasion ? .white : Color(hex: "6E655D"))
                                    .padding(.horizontal, 16)
                                    .frame(height: 38)
                                    .background(
                                        Capsule()
                                            .fill(option == selectedOccasion ? Color(hex: "B4A494") : Color.white.opacity(0.55))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        lookRotation += 1
                    } label: {
                        softButton("Another set", filled: false)
                    }
                    .buttonStyle(.plain)

                    if !stylistStatusMessage.isEmpty {
                        Text(stylistStatusMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "7A6F66"))
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(.white.opacity(0.36), in: Capsule())
                    }
                }

                if suggestedLooks.isEmpty {
                    emptyPanel(
                        title: "Not enough data yet",
                        subtitle: "Add a top, a bottom, and shoes to see styling suggestions."
                    )
                } else {
                    ForEach(suggestedLooks) { look in
                        VStack(alignment: .leading, spacing: 15) {
                            Text(look.title)
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(Color(hex: "4B433C"))

                            ForEach(look.pieces, id: \.self) { piece in
                                Text(piece)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "574F48"))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 13)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }

                            Button {
                                Task {
                                    await wear(look: look)
                                }
                            } label: {
                                softButton("Wear this look", filled: true)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(18)
                        .background(.white.opacity(0.33), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.34), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var sellView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header(eyebrow: "Resale", title: "Sell", subtitle: "Move low-rotation pieces faster.")

                HStack(spacing: 12) {
                    statCard(title: "Candidates", value: "\(sellCandidates.count)")
                    statCard(title: "Est. value", value: "$\(sellCandidates.count * 42)")
                }

                if sellCandidates.isEmpty {
                    emptyPanel(
                        title: "Nothing to sell yet",
                        subtitle: "Pieces with low rotation will appear here."
                    )
                } else {
                    ForEach(sellCandidates) { item in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(Color(hex: "4B433C"))
                                    Text("\(item.type) · \(item.color)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color(hex: "857A71"))
                                }
                                Spacer()
                                Text("$42")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color(hex: "B4A494")))
                            }

                            Text("Create a ready-to-list resale draft in one tap.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "857A71"))

                            if expandedDraftID == item.id {
                                Text(resaleDraft(for: item))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color(hex: "5E564F"))
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }

                            HStack(spacing: 12) {
                                Button {
                                    expandedDraftID = expandedDraftID == item.id ? nil : item.id
                                    copiedDraftID = nil
                                } label: {
                                    softButton(expandedDraftID == item.id ? "Hide draft" : "Create draft", filled: true)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    UIPasteboard.general.string = resaleDraft(for: item)
                                    copiedDraftID = item.id
                                    expandedDraftID = item.id
                                } label: {
                                    softButton(copiedDraftID == item.id ? "Copied" : "Copy", filled: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                        .background(.white.opacity(0.33), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.34), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var nativeTabBar: some View {
        HStack(spacing: 10) {
            nativeTabButton("Closet", tab: .closet)
            nativeTabButton("Add", tab: .add)
            nativeTabButton("Stylist", tab: .stylist)
            nativeTabButton("Sell", tab: .sell)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 18)
    }

    private func nativeTabButton(_ title: String, tab: NativeTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selectedTab == tab ? .white : Color(hex: "5E564F"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(selectedTab == tab ? Color(hex: "B4A494") : Color.white.opacity(0.45))
                )
        }
    }

    private func header(eyebrow: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(3.2)
                .foregroundStyle(Color(hex: "8A7F74"))
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "4B433C"))
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "857A71"))
                }
                Spacer()
                Text("Me")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "5E564F"))
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.42), in: Circle())
            }
        }
    }

    private func softButton(_ title: String, filled: Bool, disabled: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(filled ? Color.white.opacity(disabled ? 0.7 : 1) : Color(hex: "5E564F").opacity(disabled ? 0.55 : 1))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(filled ? Color(hex: "B4A494").opacity(disabled ? 0.7 : 1) : Color.white.opacity(disabled ? 0.25 : 0.45))
            )
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color(hex: "8A7F74"))
            Text(value)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color(hex: "4B433C"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.33), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.34), lineWidth: 1)
        )
    }

    private var pendingPreviewImage: Image? {
        guard let pendingImageData, let uiImage = UIImage(data: pendingImageData) else {
            return nil
        }

        return Image(uiImage: uiImage)
    }

    private var addEditorPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            editorSection(title: "Category", options: addCategories, selection: $draftCategory)
            editorSection(title: "Type", options: typeOptions(for: draftCategory), selection: $draftType)
            editorSection(title: "Color", options: addColors, selection: $draftColor)
            editorSection(title: "Season", options: addSeasons, selection: $draftSeason)

            Button {
                Task {
                    await savePendingGarment()
                }
            } label: {
                softButton("Save to Closet", filled: true)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(18)
        .background(.white.opacity(0.32), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
    }

    private func editorSection(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color(hex: "8A7F74"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection.wrappedValue = option
                            if title == "Category" {
                                draftType = typeOptions(for: option).first ?? "Piece"
                            }
                        } label: {
                            Text(option)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selection.wrappedValue == option ? .white : Color(hex: "6E655D"))
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(
                                    Capsule()
                                        .fill(selection.wrappedValue == option ? Color(hex: "B4A494") : Color.white.opacity(0.55))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func typeOptions(for category: String) -> [String] {
        switch category {
        case "Top":
            return ["Shirt", "T-Shirt", "Knit", "Blouse"]
        case "Bottom":
            return ["Trousers", "Jeans", "Skirt", "Shorts"]
        case "Outerwear":
            return ["Coat", "Jacket", "Blazer", "Cardigan"]
        case "Shoes":
            return ["Sneakers", "Loafers", "Boots", "Heels"]
        default:
            return ["Piece"]
        }
    }

    private var sellCandidates: [Garment] {
        garments.filter { $0.wearCount < 3 }
    }

    private func rotated(_ items: [Garment]) -> [Garment] {
        guard !items.isEmpty else { return [] }
        let offset = lookRotation % items.count
        return Array(items[offset...] + items[..<offset])
    }

    @ViewBuilder
    private func garmentImage(_ item: Garment) -> some View {
        if let url = absoluteImageUrl(for: item.imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(16)
                        .background(Color.white.opacity(0.42))
                default:
                    placeholderImage(category: item.category)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        } else {
            placeholderImage(category: item.category)
        }
    }

    private func placeholderImage(category: String) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.42))
            .overlay(
                Text(category.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.4)
                    .foregroundStyle(Color(hex: "9F9183"))
            )
    }

    private func absoluteImageUrl(for imageUrl: String) -> URL? {
        guard !imageUrl.isEmpty else {
            return nil
        }

        if imageUrl.hasPrefix("/Users/") {
            return URL(fileURLWithPath: imageUrl)
        }

        if imageUrl.hasPrefix("file://") {
            return URL(string: imageUrl)
        }

        if imageUrl.hasPrefix("http://") || imageUrl.hasPrefix("https://") {
            return URL(string: imageUrl)
        }

        return URL(string: "http://127.0.0.1:3001\(imageUrl)")
    }

    private func emptyPanel(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "4B433C"))
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "857A71"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.32), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
    }

    private func loadingPanel(_ title: String) -> some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color(hex: "8A7F74"))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "5E564F"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.32), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
    }

    @MainActor
    private func loadGarments() async {
        isLoading = true
        loadError = false

        do {
            let url = URL(fileURLWithPath: "\(previewRootPath)/.preview-data/store.json")
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PreviewStoreFile.self, from: data)
            garments = decoded.closetItems.map {
                Garment(
                    id: $0.id,
                    name: $0.name,
                    category: $0.category,
                    type: $0.type,
                    color: $0.color,
                    season: $0.season,
                    imageUrl: $0.imageUrl ?? "",
                    wearCount: $0.wearCount ?? 0
                )
            }
            .filter { !$0.id.hasPrefix("seed-") && !$0.name.hasPrefix("Preview ") }
            isLoading = false
        } catch {
            garments = []
            loadError = true
            isLoading = false
        }
    }

    @MainActor
    private func preparePhoto(_ photo: PhotosPickerItem) async {
        addStatusMessage = ""

        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                addStatusMessage = "The selected image could not be read."
                return
            }

            prepareSelectedImageData(data)
        } catch {
            addStatusMessage = "The selected image could not be read."
        }
    }

    @MainActor
    private func prepareSelectedImageData(_ data: Data) {
        pendingImageData = data
        draftCategory = "Top"
        draftType = "Shirt"
        draftColor = "Neutral"
        draftSeason = "All season"
        addStatusMessage = ""
    }

    @MainActor
    private func savePendingGarment() async {
        guard let pendingImageData else {
            addStatusMessage = "Choose an image first."
            return
        }

        isSaving = true
        addStatusMessage = ""

        defer {
            isSaving = false
        }

        do {
            let root = URL(fileURLWithPath: previewRootPath)
            let previewDirectory = root.appendingPathComponent(".preview-data", isDirectory: true)
            let uploadsDirectory = previewDirectory.appendingPathComponent("uploads", isDirectory: true)
            let storeURL = previewDirectory.appendingPathComponent("store.json")

            try FileManager.default.createDirectory(at: uploadsDirectory, withIntermediateDirectories: true)

            let imageName = "\(UUID().uuidString).jpg"
            let imageURL = uploadsDirectory.appendingPathComponent(imageName)
            try pendingImageData.write(to: imageURL, options: .atomic)

            let storedData = try Data(contentsOf: storeURL)
            var store = try JSONDecoder().decode(PreviewStoreWritable.self, from: storedData)

            let displayName = "\(draftColor) \(draftType)"

            let newItem = PreviewStoredItem(
                name: displayName,
                type: draftType,
                category: draftCategory,
                colors: [draftColor],
                style: "Everyday",
                tone: draftColor,
                imageHint: draftType,
                note: "",
                season: draftSeason,
                formality: "Casual",
                occasions: "Daily",
                material: "",
                imageUrl: imageURL.path,
                id: "preview-\(UUID().uuidString.lowercased())",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                wearCount: 0
            )

            store.closetItems.insert(newItem, at: 0)

            let encoded = try JSONEncoder.prettyPrinted.encode(store)
            try encoded.write(to: storeURL, options: .atomic)

            await loadGarments()
            selectedTab = .closet
            selectedPhoto = nil
            self.pendingImageData = nil
            copiedDraftID = nil
            expandedDraftID = nil
            addStatusMessage = "New piece added to Closet."
        } catch {
            addStatusMessage = "Saving failed. Try again."
        }
    }

    @MainActor
    private func wear(look: SuggestedLook) async {
        do {
            let storeURL = URL(fileURLWithPath: "\(previewRootPath)/.preview-data/store.json")
            let storedData = try Data(contentsOf: storeURL)
            var store = try JSONDecoder().decode(PreviewStoreWritable.self, from: storedData)

            store.closetItems = store.closetItems.map { item in
                guard look.pieces.contains(item.name) else {
                    return item
                }

                return PreviewStoredItem(
                    name: item.name,
                    type: item.type,
                    category: item.category,
                    colors: item.colors,
                    style: item.style,
                    tone: item.tone,
                    imageHint: item.imageHint,
                    note: item.note,
                    season: item.season,
                    formality: item.formality,
                    occasions: item.occasions,
                    material: item.material,
                    imageUrl: item.imageUrl,
                    id: item.id,
                    createdAt: item.createdAt,
                    wearCount: (item.wearCount ?? 0) + 1
                )
            }

            let encoded = try JSONEncoder.prettyPrinted.encode(store)
            try encoded.write(to: storeURL, options: .atomic)
            await loadGarments()
            stylistStatusMessage = "Look saved"
        } catch {
            stylistStatusMessage = "Try again"
        }
    }

    private func resaleDraft(for item: Garment) -> String {
        """
        \(item.name)
        Category: \(item.type)
        Color: \(item.color)
        Season: \(item.season)
        Condition: Gently used
        Why sell: Low rotation in wardrobe
        Suggested price: $42
        """
    }

    @MainActor
    private func updateGarment(id: String, name: String, category: String, type: String, color: String, season: String) async {
        do {
            let storeURL = URL(fileURLWithPath: "\(previewRootPath)/.preview-data/store.json")
            let storedData = try Data(contentsOf: storeURL)
            var store = try JSONDecoder().decode(PreviewStoreWritable.self, from: storedData)

            store.closetItems = store.closetItems.map { item in
                guard item.id == id else { return item }
                return PreviewStoredItem(
                    name: name,
                    type: type,
                    category: category,
                    colors: [color],
                    style: item.style,
                    tone: color,
                    imageHint: type,
                    note: item.note,
                    season: season,
                    formality: item.formality,
                    occasions: item.occasions,
                    material: item.material,
                    imageUrl: item.imageUrl,
                    id: item.id,
                    createdAt: item.createdAt,
                    wearCount: item.wearCount
                )
            }

            let encoded = try JSONEncoder.prettyPrinted.encode(store)
            try encoded.write(to: storeURL, options: .atomic)
            await loadGarments()
            selectedGarment = garments.first(where: { $0.id == id })
            closetStatusMessage = "Saved \(name)"
        } catch {
            closetStatusMessage = "Could not save changes"
        }
    }

    @MainActor
    private func deleteGarment(id: String) async {
        do {
            let storeURL = URL(fileURLWithPath: "\(previewRootPath)/.preview-data/store.json")
            let storedData = try Data(contentsOf: storeURL)
            var store = try JSONDecoder().decode(PreviewStoreWritable.self, from: storedData)
            let deletedName = store.closetItems.first(where: { $0.id == id })?.name ?? "Piece"
            store.closetItems.removeAll { $0.id == id }
            let encoded = try JSONEncoder.prettyPrinted.encode(store)
            try encoded.write(to: storeURL, options: .atomic)
            selectedGarment = nil
            await loadGarments()
            closetStatusMessage = "Deleted \(deletedName)"
        } catch {
            closetStatusMessage = "Could not delete piece"
        }
    }
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onCapture: (Data) -> Void
        private let dismiss: DismissAction

        init(onCapture: @escaping (Data) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) {
                onCapture(data)
            }
            dismiss()
        }
    }
}

private struct GarmentEditorSheet: View {
    let garment: Garment
    let onClose: () -> Void
    let onSave: (String, String, String, String, String) -> Void
    let onDelete: () -> Void

    @State private var name: String
    @State private var category: String
    @State private var type: String
    @State private var color: String
    @State private var season: String

    init(
        garment: Garment,
        onClose: @escaping () -> Void,
        onSave: @escaping (String, String, String, String, String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.garment = garment
        self.onClose = onClose
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: garment.name)
        _category = State(initialValue: garment.category)
        _type = State(initialValue: garment.type)
        _color = State(initialValue: garment.color)
        _season = State(initialValue: garment.season)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let url = URL(string: garment.imageUrl), garment.imageUrl.hasPrefix("http") {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.5))
                        }
                        .frame(height: 220)
                    } else if garment.imageUrl.hasPrefix("/Users/") {
                        Image(uiImage: UIImage(contentsOfFile: garment.imageUrl) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                    }

                    editorField("Name", text: $name)
                    editorField("Category", text: $category)
                    editorField("Type", text: $type)
                    editorField("Color", text: $color)
                    editorField("Season", text: $season)

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Text("Delete piece")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "EFE8DF"), Color(hex: "E7DED4")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onClose() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, category, type, color, season)
                    }
                }
            }
        }
    }

    private func editorField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(Color(hex: "8A7F74"))
            TextField(title, text: text)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
