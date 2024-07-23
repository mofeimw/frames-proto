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
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(items) { item in
                            FrameItemView(item: item)
                        }
                    }
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
            .navigationTitle("Frames")
            //.navigationBarTitleDisplayMode(.inline)
            //.toolbar {
                //ToolbarItem(placement: .principal) {
                    //Text("Frames")
                        //.font(.largeTitle)
                        //.fontWeight(.bold)
                //}
            //}
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
}

struct FrameItemView: View {
    let item: Item
    
    var body: some View {
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
                    Text("Use this space for additional details.")
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

