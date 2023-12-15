//
//  TorrentDetailsView.swift
//  qBitControl
//

import SwiftUI

struct ChangeCategoryView: View {
    
    @State var torrentHash: String
    
    @State private var categories: [String] = []
    
    @State var category: String

    
    var body: some View {
        VStack {
            Form {
                if categories.count > 1 {
                    Picker("Categories", selection: $category) {
                        Text("None").tag("")
                        ForEach(categories, id: \.self) {
                            category in
                            Text(category).tag(category)
                        }
                    }.pickerStyle(.inline)
                }
                
                /*Button {
                    // link to management view
                } label: {
                    Text("Manage Categories")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent)
                    .listRowBackground(Color.blue)*/
            }
            .navigationTitle("Categories")
        }.onAppear() {
            qBittorrent.getCategories(completionHandler: {
                categories in
                
                for (category, _) in categories {
                    self.categories.append(category)
                    self.categories.sort(by: <)
                }
            })
        }.onChange(of: category) {
            category in
            print(category)
            let request = qBitRequest.prepareURLRequest(path: "/api/v2/torrents/setCategory", queryItems: [
                URLQueryItem(name: "hashes", value: torrentHash),
                URLQueryItem(name: "category", value: category)
            ])
            
            qBitRequest.requestTorrentManagement(request: request, statusCode: {
                code in
                //print(code)
            })
        }
    }
}

struct ChangePathView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State var path: String
    let torrentHash: String
    
    func setPath() {
        let request = qBitRequest.prepareURLRequest(path: "/api/v2/torrents/setLocation", queryItems: [
            URLQueryItem(name: "hashes", value: torrentHash),
            URLQueryItem(name: "location", value: path)
        ])
        
        qBitRequest.requestTorrentManagement(request: request, statusCode: {
            code in
            print("Code: \(code ?? -1)")
        })
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Save Path", text: $path, axis: .vertical)
                    .lineLimit(1...5)
            }
            
            Section {
                Button {
                    setPath()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Update")
                }
            }
        }.navigationTitle("Save Path")
    }
}

struct TorrentDetailsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State var torrent: Torrent
    @State private var timer: Timer?
    @State private var buttonTextColor = UITraitCollection.current.userInterfaceStyle == .dark ? Color.white : Color.black
    @State private var presentDeleteAlert = false
    
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    
    
    func getTorrent() {
        let request = qBitRequest.prepareURLRequest(path: "/api/v2/torrents/info", queryItems: [URLQueryItem(name:"hashes", value: torrent.hash)])
        
        qBitRequest.requestTorrentListJSON(request: request) {
            torrent in
            if torrent.count >= 1 {
                self.torrent = torrent[0]
            } // There should be only one torrent in the response
        }
    }
    
    var body: some View {
        VStack {
            //Text("Torrent Details")
             //   .font(.tit
            List {
                Section(header: Text("Management")) {
                    Button(action: {
                        impactMed.impactOccurred()
                        if torrent.state.contains("paused") {
                            qBittorrent.resumeTorrent(hash: torrent.hash)
                        } else {
                            qBittorrent.pauseTorrent(hash: torrent.hash)
                        }
                        getTorrent()
                        
                    }) {
                        if torrent.state.contains("paused") {
                            Text("Resume Task")
                        } else {
                            Text("Pause Task")
                        }
                    }
                    
                    Button(action: {
                        impactMed.impactOccurred()
                        qBittorrent.recheckTorrent(hash: torrent.hash)
                    }) {
                        Text("Recheck Task")
                    }
                    
                    Button(action: {
                        impactMed.impactOccurred()
                        qBittorrent.reannounceTorrent(hash: torrent.hash)
                    }) {
                        Text("Reannounce Task")
                    }
                    Button(action: {
                        impactMed.impactOccurred()
                        presentDeleteAlert = true
                    }) {
                        Text("Delete Task")
                            .foregroundColor(Color.red)
                    }
                }
                
                Section(header: Text("Information")) {
                    ListElement(label: "Name", value: "\(torrent.name)")
                    
                    ListElement(label: "Added On", value: "\( qBittorrent.getFormatedDate(date: torrent.added_on) )")
                    
                    //listElement(label: "Categories", value: "\( torrent.category != "" ? torrent.category : "None" )")
                    
                    NavigationLink {
                        ChangeCategoryView(torrentHash: torrent.hash, category: torrent.category)
                    } label: {
                        ListElement(label: "Categories", value: "\( torrent.category != "" ? torrent.category : "None" )")
                    }
                    
                    /*NavigationLink {
                        ChangeTagsView(torrentHash: torrent.hash, selectedTags: torrent.tags.components(separatedBy: ","))
                    } label: {*/
                        ListElement(label: "Tags", value: "\( torrent.tags != "" ? torrent.tags : "None" )")
                    //}
                    
                    ListElement(label: "Size", value: "\(qBittorrent.getFormatedSize(size: torrent.size))")
                    
                    ListElement(label: "Total Size", value: "\(qBittorrent.getFormatedSize(size: torrent.total_size))")
                    
                    ListElement(label: "Availability", value: torrent.availability < 0 ? "-" : "\(String(format: "%.1f", torrent.availability))%")
                }
                
                Section(header: Text("Connections")) {
                    NavigationLink {
                        TorrentDetailsPeersView(torrentHash: .constant(torrent.hash))
                    } label: {
                        Text("Peers")
                    }
                    NavigationLink {
                        TorrentDetailsTrackersView(torrentHash: .constant(torrent.hash))
                    } label: {
                        Text("Trackers")
                    }
                }
                
                Section(header: Text("Files")) {
                    NavigationLink {
                        ChangePathView(path: torrent.save_path, torrentHash: torrent.hash)
                    } label: {
                        ListElement(label: "Save Path", value: torrent.save_path)
                    }
                    
                    NavigationLink {
                        TorrentDetailsFilesView(torrentHash: .constant(torrent.hash))
                    } label: {
                        Text("Files")
                    }
                }
                
                Section(header: Text("Status")) {
                    ListElement(label: "State", value: "\(qBittorrent.getState(state: torrent.state))")
                    
                    ListElement(label: "Progress", value: "\(String(format: "%.2f", (torrent.progress*100)))%")
                    
                    ListElement(label: "Download Speed", value: "\(qBittorrent.getFormatedSize(size: torrent.dlspeed))/s")
                    
                    ListElement(label: "Upload Speed", value: "\(qBittorrent.getFormatedSize(size: torrent.upspeed))/s")
                    
                    ListElement(label: "Downloaded", value: "\(qBittorrent.getFormatedSize(size: torrent.downloaded))")
                    
                    ListElement(label: "Uploaded", value: "\(qBittorrent.getFormatedSize(size: torrent.uploaded))")
                    
                    ListElement(label: "Ratio", value: "\(String(format:"%.2f", torrent.ratio))")
                    
                }
                
                Section(header: Text("Session")) {
                    ListElement(label: "Downloaded", value: "\(qBittorrent.getFormatedSize(size: torrent.downloaded_session))")
                    
                    ListElement(label: "Uploaded", value: "\(qBittorrent.getFormatedSize(size: torrent.uploaded_session))")
                }
                
                Section(header: Text("Limits")) {
                    //listElement(label: "Maximum Seeding Time", value: "n/a")
                    
                    ListElement(label: "Maximum Ratio", value: "\(torrent.max_ratio > -1 ? String(format:"%.2f", torrent.max_ratio) : "None")")
                    
                    ListElement(label: "Download Limit", value: "\(torrent.dl_limit > 0 ? qBittorrent.getFormatedSize(size: torrent.dl_limit)+"/s" : "None")")
                    
                    ListElement(label: "Upload Limit", value: "\(torrent.up_limit > 0 ? qBittorrent.getFormatedSize(size: torrent.up_limit)+"/s" : "None")")
                }
                
            }
            .navigationTitle("Details")
        }
        .onAppear() {
            timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) {
                timer in
                getTorrent()
            }
            
        }.onDisappear() {
            timer?.invalidate()
        }.confirmationDialog("Delete Task",isPresented: $presentDeleteAlert) {
            Button("Delete Task", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
                qBittorrent.deleteTorrent(hash: torrent.hash)
            }
            Button("Delete Task with Files", role: .destructive) {
                presentationMode.wrappedValue.dismiss()
                qBittorrent.deleteTorrent(hash: torrent.hash, deleteFiles: true)
            }
            Button("Cancel", role: .cancel) {}
        }.refreshable() {
            getTorrent()
        }
    }
}

/*struct TorrentDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TorrentDetailsView()
    }
}*/
