//
//  ConversationTableViewCell.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 11/5/23.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 100,
                                     height: 100)
        userNameLabel.frame = CGRect(x: userImageView.frame.origin.x+userImageView.frame.width + 10,
                                     y: 10,
                                     width: contentView.frame.width - 20 - userImageView.frame.width,
                                     height: (contentView.frame.height-20)/2)
        
        userMessageLabel.frame = CGRect(x: userImageView.frame.origin.x+userImageView.frame.width + 10,
                                        y: userNameLabel.frame.origin.y + userNameLabel.frame.height,
                                     width: contentView.frame.width - 20 - userImageView.frame.width,
                                     height: (contentView.frame.height-20)/2)
        

    }
    public func configure(with model: Conversation) {
        self.userMessageLabel.text = model.latestMessage.text
        self.userNameLabel.text = model.name
        
    }

}
