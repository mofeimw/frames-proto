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
        }
    }
}

struct FramesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var showNewFrame = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(filteredItems) { item in
                            FrameItemView(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Frames")
            .overlay(
                Button(action: {
                    showNewFrame = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .padding()
                        .background(Circle().fill(Color.blue))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20),
                alignment: .bottomTrailing
            )
        }
        .fullScreenCover(isPresented: $showNewFrame) {
            NewFrameView(isPresented: $showNewFrame)
        }
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
}

struct FrameItemView: View {
    let item: Item
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack(alignment: .leading, spacing: 10) {
                if let timestamp = item.timestamp {
                    Text(timestamp, formatter: itemFormatter)
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
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
            Text("Settings View")
                .navigationBarTitle("Settings", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

struct CollectionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Collection View")
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
            Text("Explore View")
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

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}



