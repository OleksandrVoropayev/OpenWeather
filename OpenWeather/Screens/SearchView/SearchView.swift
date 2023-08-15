//
//  SearchView.swift
//  OpenWeather
//
//  Created by Oleksandr Voropayev on 14.08.2023.
//

import SwiftUI

struct SearchView: View {
    // MARK: - PROPERTIES

    @ObservedObject var viewModel: ViewModel = ViewModel()
    @State private var isAlertPresented = false

    let layout = [GridItem(.flexible())]

    // MARK: - BODY

    var body: some View {
        VStack {
            searchBar

            if viewModel.geoItems.count > 0 {
                scrollView
            } else {
                placeholder
            }
        }
        .padding(.horizontal)
        .alert(isPresented: $isAlertPresented, error: viewModel.error) {}
        .onReceive(viewModel.$error) {
            guard $0 != nil else { return }

            isAlertPresented = true
        }
    }

    // MARK: - SEARCHBAR

    var searchBar: some View {
        TextField("Search here", text: $viewModel.searchText)
            .padding([.vertical, .trailing], 10)
            .padding(.leading, 40)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(alignment: .leading) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundColor(.gray)
                    .padding(.leading, 10)
            }
    }

    // MARK: - PLACEHOLDER

    var placeholder: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(text: nil)
            } else {
                VStack {
                    Spacer()
                    Text("Please Search Your Location")
                    Spacer()
                }
            }
        }
    }

    // MARK: - SCROLLVIEW

    var scrollView: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: layout, spacing: 8) {
                ForEach(viewModel.geoItems, id: \.self) { item in
                    SearchItemView(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Remove focus from search bar before switching the tab to prevent from AttributeGraph errors
                            UIApplication.shared
                                .sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil, from:nil, for:nil
                                )

                            viewModel.didSelect(item)
                        }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: - PREVIEW

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
