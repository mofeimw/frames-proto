//
//  ContentView.swift
//  Frames
//
//  Created by mofei wang on 7/23/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            FramesView()
                .tabItem {
                    Label("Frames", systemImage: "photo.on.rectangle")
                }
            
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }.accentColor(Color(hex: "#335B41"))
    }
}

func formatDate(_ date: Date) -> (monthYear: String, dayWeekDate: String) {
    let monthYearFormatter = DateFormatter()
    monthYearFormatter.dateFormat = "MMMM yyyy"
    
    let dayWeekFormatter = DateFormatter()
    dayWeekFormatter.dateFormat = "EEEE, d"
    
    return (monthYearFormatter.string(from: date), dayWeekFormatter.string(from: date))
}

struct FramesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    private var groupedItems: [(String, [Item])] {
        let grouped = Dictionary(grouping: filteredItems) { item in
            formatDate(item.timestamp ?? Date()).monthYear
        }
        return grouped.sorted { pair1, pair2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let date1 = formatter.date(from: pair1.key) ?? Date.distantPast
            let date2 = formatter.date(from: pair2.key) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    @State private var showNewFrame = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var randomQuote: String = ""
    
    init() {
        _randomQuote = State(initialValue: getRandomQuote())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isSearching {
                    SearchBar(text: $searchText, isSearching: $isSearching)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.2), value: isSearching)
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        Text("\"\(randomQuote)\"")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#1e3024"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#9DCBBA"))
                            .cornerRadius(8)
                            .padding()
                        
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedItems, id: \.0) { monthYear, items in
                                Section(header: monthYearHeader(monthYear)) {
                                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                        VStack(spacing: 0) {
                                            FrameItemView(item: item)
                                            if index < items.count - 1 {
                                                Rectangle()
                                                    .fill(Color(hex: "#C2CCC9"))
                                                    .frame(height: 1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Color(hex: "#F6F9F8"))
            .overlay(
                Button(action: {
                    showNewFrame = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .padding()
                        .background(Circle().fill(Color(hex: "#335B41")))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20),
                alignment: .bottomTrailing
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Frames")
                            .font(.custom("Georgia", size: 33))
                            .foregroundColor(Color(hex: "#335B41"))
                            .fontWeight(.regular)
                        Spacer()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            isSearching.toggle()
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: "#335B41"))
                    }
                }
            }
        }
        .accentColor(Color(hex: "#335B41"))
        .fullScreenCover(isPresented: $showNewFrame) {
            NewFrameView(isPresented: $showNewFrame)
        }
        .padding(.horizontal, 20)
        .background(Color(hex: "#F6F9F8"))
        .scrollIndicators(.hidden)
        //.onAppear(perform: deleteAllItems) // FOR DEBUGGING
    }
    
    private func deleteAllItems() {
        print("DEBUG clearing all frames")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Item")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print("Failed to delete all items: \(error)")
        }
    }
    
    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return Array(items)
        } else {
            return items.filter { item in
                let mainText = item.main?.localizedCaseInsensitiveContains(searchText) ?? false
                let detailsText = item.details?.localizedCaseInsensitiveContains(searchText) ?? false
                return mainText || detailsText
            }
        }
    }
    
    private func getRandomQuote() -> String {
        let quotes = [
            "The only limit to our realization of tomorrow is our doubts of today.",
            "The future belongs to those who believe in the beauty of their dreams.",
            "Do not watch the clock. Do what it does. Keep going.",
            "Keep your face always toward the sunshine—and shadows will fall behind you.",
            "The best way to predict your future is to create it."
        ]
        
        return quotes.randomElement() ?? ""
    }
    
    private func monthYearHeader(_ monthYear: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(monthYear)
                    .font(.headline)
                    .padding(.vertical, 5)
                Spacer()
            }
            .background(Color(hex: "#F6F9F8"))
            Rectangle()
                .fill(Color(hex: "#A8C0B3"))
                .frame(height: 4)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct FrameDetailView: View {
    let item: Item
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isBookmarked: Bool
    
    init(item: Item) {
        self.item = item
        _isBookmarked = State(initialValue: item.isBookmarked)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let timestamp = item.timestamp {
                    Text(timestamp, formatter: itemFormatter)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(item.main ?? "")
                    .font(.title)
                    .fontWeight(.bold)

                Text(item.details ?? "")
                    .font(.body)

                if let pictureData = item.picture, let uiImage = UIImage(data: pictureData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        //.navigationBarTitle("Frame Details", displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: {
                toggleBookmark()
            }) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
            }
        )
    }
    
    private func toggleBookmark() {
        isBookmarked.toggle()
        item.isBookmarked = isBookmarked
        do {
            try viewContext.save()
        } catch {
            print("Failed to save bookmark state: \(error)")
        }
    }
}

struct FrameItemView: View {
    let item: Item
    @State private var showDetail = false
    
    var body: some View {
        Button(action: {
            showDetail = true
        }) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    if let timestamp = item.timestamp {
                        Text(formatDate(timestamp).dayWeekDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(item.main ?? "")
                        .font(.headline)
                        .lineLimit(2)
                    Text(item.details ?? "")
                        .font(.body)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let pictureData = item.picture, let uiImage = UIImage(data: pictureData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#F6F9F8"))
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            NavigationView {
                FrameDetailView(item: item)
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct NewFrameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    @State private var newMain = ""
    @State private var newDetails = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("What are you thinking?")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                    TextEditor(text: $newMain)
                        .font(.title)
                        .padding(10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .frame(maxHeight: .infinity)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Use this space for additional details")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                    TextEditor(text: $newDetails)
                        .font(.body)
                        .padding(10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .frame(maxHeight: .infinity)
                }

                VStack(alignment: .center, spacing: 5) {
                    Text("Add a picture here")
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Button(action: {
                        showImagePicker.toggle()
                    }) {
                        HStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(10)
                            } else {
                                Text("Select Image")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $selectedImage, onImagePicked: { })
                    }
                }
            }
            .padding()
            .navigationTitle("New Frame")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addItem()
                        isPresented = false
                    }
                    .disabled(newMain.isEmpty && newDetails.isEmpty)
                }
            }
        }.navigationViewStyle(.stack)
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.main = newMain
            newItem.details = newDetails
            newItem.isBookmarked = false
            if let image = selectedImage {
                newItem.picture = image.jpegData(compressionQuality: 1.0)
            }
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.onImagePicked?()
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct ProfileView: View {
    @State private var showSettings = false
    @State private var showCollection = false
    @State private var showExplore = false
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 20) {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Rikki Tikki Tavi")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("KC | NYU '25")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("696")
                                .fontWeight(.bold)
                            Text("Followers")
                                .font(.caption)
                        }
                        
                        VStack {
                            Text("420")
                                .fontWeight(.bold)
                            Text("Following")
                                .font(.caption)
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
            
            VStack(spacing: 15) {
                ProfileButton(title: "Settings", icon: "gearshape.fill", isPresented: $showSettings)
                ProfileButton(title: "Collection", icon: "bookmark.fill", isPresented: $showCollection)
                ProfileButton(title: "Explore", icon: "books.vertical.fill", isPresented: $showExplore)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showCollection) {
            CollectionView()
        }
        .fullScreenCover(isPresented: $showExplore) {
            ExploreView()
        }
    }
}

struct ProfileButton: View {
    let title: String
    let icon: String
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.black)
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Settings")
                .navigationBarTitle("Settings", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

struct CollectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        predicate: NSPredicate(format: "isBookmarked == %@", NSNumber(value: true))
    ) private var bookmarkedItems: FetchedResults<Item>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                
                if bookmarkedItems.isEmpty {
                    Text("No frames saved")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(bookmarkedItems) { item in
                                NavigationLink(destination: FrameDetailView(item: item)) {
                                    FrameItemView(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("Collection", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ExploreView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Explore")
                .navigationBarTitle("Explore", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

struct HomeView: View {
    var body: some View {
        Text("Home")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
