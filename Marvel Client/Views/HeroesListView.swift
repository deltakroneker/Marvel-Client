//
//  HeroesListView.swift
//  Marvel Client
//
//  Created by Conrado Mateu Gisbert on 2/3/22.
//

import SwiftUI
import CoreData

struct HeroesListView: View {

    @StateObject var viewmodel = HeroesViewModel()

    var body: some View {
        NavigationView {
            VStack {

                if viewmodel.result.count != 0 {
                    List {
                        ForEach(viewmodel.result, id: \.id) { hero in
                            NavigationLink {
                                DetailRow(hero: hero,
                                          onFavoriteToggled: viewmodel.toggleFavoriteFor)
                            } label: {
                                HeroRow(hero: hero)
                            }.task {
                                if viewmodel.result.count > 0 {
                                    if viewmodel.result.last == hero {
                                        await viewmodel.togglePagination()
                                    }
                                }
                            }
                        }.onDelete(perform: delete)

                    }.refreshable {
                        await viewmodel.getHeroes(isRefreshing: true)

                    }
                } else {

                    Button( action: {
                        Task {
                            await viewmodel.getHeroes()
                        }
                    }, label: {
                        Text("Get Heroes")
                    }).buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }

            }                .alert(isPresented: $viewmodel.triggerInternetAlert, content: {
                return Alert(title: Text("No Internet Connection"),
                             message: Text("Please enable Wifi or Cellular data"),
                             dismissButton: .default(Text("OK")))
            })

                .onAppear {
                Task {
                    await viewmodel.getHeroes()
                }
            }.onDisappear {
                viewmodel.goingToDetailView()
            }.makeToolbarItems(addItem: viewmodel.addRandomHero, deleteItem: viewmodel.deleteAllHeroes)
                .navigationTitle("Heroes")
        }.navigationViewStyle(.stack).loaderViewWrapper(isLoading: viewmodel.isLoading)
            .alert(isPresented: $viewmodel.triggerErrorAlert, content: {
                return Alert(title: Text("An Error Has Occurred"),
                             message: Text(viewmodel.error?.localizedDescription ?? ""),
                             dismissButton: .default(Text("OK")))
            })
    }

    // Required Function for deleting an element from a swipe
    func delete(at offsets: IndexSet) {
        let index = offsets[offsets.startIndex]
        Task {
            try await self.viewmodel.deleteHero(index: index)
        }
    }
}

 struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HeroesListView(viewmodel: HeroesViewModel(repository: DependencyInjector.fakeRepository()))
            .preferredColorScheme(.dark)
    }
 }