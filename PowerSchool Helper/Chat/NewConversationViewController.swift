//
//  NewConversationViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 11/2/23.
//

import UIKit

class NewConversationViewController: UIViewController {

    public var completion: (([String : String]) -> (Void))?

    
    private var users = [[String : String]]()
    
    private var results = [[String : String]]()

    private var hasFetched = false
    
    
    private let searchBar: UISearchBar = {
       let searchBar = UISearchBar()
        searchBar.placeholder = "Search For Users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .black
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        view.backgroundColor = .white
        
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", 
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
        searchBar.barStyle = .black
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.frame.width/4, y: (view.frame.height-200)/2, width: view.frame.width/2, height: 100)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .black
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targetUserData)
        })
    }
}


extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        results.removeAll()
        self.searchUsers(query: text)
        
        searchBar.resignFirstResponder()
        
    }
    
    func searchUsers(query: String) {
        //check if array has fb results
        if hasFetched {
            //if it does : filter
            filterUsers(with: query)
        } else {
            // if not: fetch, then filter
            FirebaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.hasFetched = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get All Users: \(error)")
                }
            })
        }
        
    }
    
    func filterUsers(with term: String) {
        //update the UI
        guard hasFetched else { return }
        
        let results: [[String : String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        })
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
