//
//  MovieDetailViewController.swift
//  DarsayTechTest
//
//  Created by Farzaneh on 11/8/1401 AP.

import Combine
import Foundation
import SnapKit
import UIKit

fileprivate extension Layout {
    static let bannersSectionGroupWidthInset: CGFloat = 48
    static let contentScrollViewContentInsetBottom: CGFloat = 100
}

fileprivate extension PageSection {
    static let reviewSection =  Self.init(id: "section-review")
}

final class MovieDetailViewController: UIViewController, BaseSceneViewController {
    
    // MARK: - Variables
    
    let router: MovieDetailRouterProtocol?
    let viewModel: any ViewModel<MovieDetail.State, MovieDetail.Action>
    var cancellables = Set<AnyCancellable>()

    var sections: [PageSection] {
        [.reviewSection]
    }
    
    // MARK: - UI Components
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        return label
    }()
    
    lazy var popularityLabel: UILabel = {
        let label = UILabel()
        label.textColor = .green
        label.font.withSize(12)
        return label
    }()
    
    lazy var overviewLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font.withSize(10)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout())

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.semanticContentAttribute = .forceLeftToRight
        collectionView.backgroundColor = .white
        collectionView.contentInset.bottom = Layout.contentScrollViewContentInsetBottom
        collectionView.dataSource = self

        let cellReuseIdentifiers = [ PageSection.reviewSection.cellReuseIdentifier ]

        for reuseIdentifier in cellReuseIdentifiers {
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        }

        return collectionView
    }()
    
    // MARK: - Initialization
    
    init(viewModel: any ViewModel<MovieDetail.State, MovieDetail.Action>, router: MovieDetailRouterProtocol?) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        
        prepareUI()
        
        bind()
        
        self.viewModel.handle(action: .fetchDetail)
        
        self.viewModel.handle(action: .fetchReviews)
    }
    
    // MARK: - Prepare UI
    
    func prepareUI() {
        view.backgroundColor = .white
        // add subviews
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(popularityLabel)
        view.addSubview(overviewLabel)
        view.addSubview(collectionView)
        setConstraints()
    }
    
    // MARK: - Prepare Layout
    
    func collectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout.init { [unowned self] sectionIndex, _ in
            
            let section =  self.sections[sectionIndex]
            switch section {
            case .reviewSection:
                return getReviewCollectionLayoutSection()
            default:
                fatalError("Invalid section: \(section)")
            }
        }
    }
    
    private func getReviewCollectionLayoutSection() -> NSCollectionLayoutSection {
        let width = UIScreen.main.bounds.size.width - Layout.bannersSectionGroupWidthInset
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(width),
            heightDimension: .absolute(200)
        )
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        group.contentInsets.trailing = 16
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets.bottom = 40
        return section
    }
    
    // MARK: - Constraints
    
    func setConstraints() {
        imageView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(4)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(160)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        popularityLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        overviewLabel.snp.makeConstraints { make in
            make.top.equalTo(popularityLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(overviewLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(8)
        }
    }
    
    // MARK: - Bind
    
    func bind() {
        viewModel.statePublisher.compactMap(\.movie).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] movie in
            guard let self else { return }
         
            self.titleLabel.text = movie.title
            let formattedText = String(format: "%.2f", movie.popularity/100.0)
            self.popularityLabel.text = "Popularity: \(formattedText)%"
            self.overviewLabel.text = movie.overview
            self.setImageView(nestedURL: movie.backdropPath)
          
        }).store(in: &cancellables)
        
        viewModel.statePublisher.compactMap(\.reviewList).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] _ in
            guard let self else { return }
         
            self.releadList()
            
        }).store(in: &cancellables)
        
        viewModel.statePublisher.compactMap(\.error).receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] error in
            guard let self else { return }
         
            self.router?.showErrorAlert(message: error.localizedDescription)
            
        }).store(in: &cancellables)
        
    }
    
    func setImageView(nestedURL: String?) {
        if let nestedURL = nestedURL {
            do {
                let url = try URL.getFullPath(sizeType: .poster(.w780) ,nestedURLString: nestedURL)
                
                ImageLoader.shared.loadImage(from: url).sinkToResult { result in
                    
                    guard case .success(let image) = result else {
                        return
                    }
                    self.imageView.image = image
                    
                }.store(in: &self.cancellables)
            } catch {
                self.imageView.image = UIImage(named: "placeholder")
            }
        }
    }
    // MARK: - Actions
    
    func releadList(completion: (() -> Void)? = nil) {
        collectionView.reloadData()
        completion?()
    }
}

// MARK: - UICollectionViewDataSource

extension MovieDetailViewController: UICollectionViewDataSource {
   
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let section = self.sections[section]
        
        switch section {
        case .reviewSection:
            return self.viewModel.state.reviewList?.count ?? 0
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = self.sections[indexPath.section]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.sections[indexPath.section].cellReuseIdentifier, for: indexPath)
        
        switch section {
        case .reviewSection:
            
            guard let reviewList = self.viewModel.state.reviewList else { return UICollectionViewCell() }
            
            cell.contentConfiguration = ReviewView.Configuration(author: reviewList[indexPath.row].author, description: reviewList[indexPath.row].content)
        default:
            return UICollectionViewCell()
        }
        return cell
    }
}