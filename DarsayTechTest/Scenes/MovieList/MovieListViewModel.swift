//
//  MovieListViewModel.swift
//  DarsayTechTest
//
//  Created by Farzaneh on 11/8/1401 AP.

import Combine
import Foundation

class MovieListViewModel: SubjectedViewModel {

    typealias State = MovieList.State
    
    typealias Action = MovieList.Action
    
    let stateSubject: CurrentValueSubject<State, Never>
    let networkManager: MovieNetworkAPI
    var cancellables = Set<AnyCancellable>()

    init(configuration: MovieList.Configuration) {
        stateSubject = .init(.init())
        networkManager = configuration.movieNetworkAPIManager
    }
    
    func handle(action: Action) {
        switch action {
        case .fetchTopRatedMovies:
            fetchTopRatedMovies()
        case .fetchPopularMovies:
            fetchPopularMovies()
        }
    }
    
    private func fetchTopRatedMovies() {
        networkManager.getTopRatedMovies().sinkToResult { result in
            switch result {
            case .success(let movieList):
                self.stateSubject.value.update({
                    $0.topRatedList = movieList.results
                })
            case .failure(let error):
                self.stateSubject.value.update({
                    $0.error = error
                })
            }
        }.store(in: &cancellables)
    }
    
    private func fetchPopularMovies(completion: (() -> Void)? = nil) {
        
        networkManager.getPopularMovies().sinkToResult { result in
            switch result {
            case .success(let movieList):
            
                self.stateSubject.value.update({
                    $0.popularList = movieList.results
                })
            case .failure(let error):
                self.stateSubject.value.update({
                    $0.error = error
                })
            }
            completion?()
        }.store(in: &cancellables)
    }
}