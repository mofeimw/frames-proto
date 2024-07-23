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
    
    var body: some View {
            NavigationView {
                ZStack {
                    List {
                        ForEach(items) { item in
                            VStack(alignment: .leading) {
                                if let timestamp = item.timestamp {
                                    Text(timestamp, formatter: itemFormatter)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(item.main ?? "")
                                    .font(.headline)
                                Text(item.details ?? "")
                                    .font(.body)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
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
                            .padding(.bottom, 20)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Frames")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .fullScreenCover(isPresented: $showNewFrame) {
                NewFrameView(isPresented: $showNewFrame)
            }
        }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextEditor(text: $newMain)
                    .placeholder(when: newMain.isEmpty) {
                        Text("Main").foregroundColor(.gray)
                    }
                    .font(.title)
                    .padding()
                    .frame(maxHeight: .infinity)
                
                Divider()
                
                TextEditor(text: $newDetails)
                    .placeholder(when: newDetails.isEmpty) {
                        Text("Details").foregroundColor(.gray)
                    }
                    .font(.body)
                    .padding()
                    .frame(maxHeight: .infinity)
            }
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
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.main = newMain
            newItem.details = newDetails
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// Add this extension to create a placeholder for TextEditor
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .topLeading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile")
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

