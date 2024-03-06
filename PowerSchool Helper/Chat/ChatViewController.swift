//
//  ChatViewController.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 11/2/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView


struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
    
    
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserUsername: String
    private let conversationID: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let username = UserDefaults.standard.value(forKey: "student-username") as? String else {
            return nil
        }
        return Sender(photoURL: "",
                   senderId: username,
                   displayName: "Me")
        
    }
    
   
    
    init(with username: String, id: String?) {
        self.conversationID = id
        otherUserUsername = username
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationID {
            listenForMessages(id: conversationId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.backgroundColor = .black
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }

    private func listenForMessages(id: String) {
        FirebaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                print("New Messge was sent: \(messages)")
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageID = createMessageID() else {
            return
        }
        
        print("SENDING: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageID,
                              sentDate: Date(),
                              kind: .text(text))
        //Send Message
        if isNewConversation {
            // Create New Conversation in Database
            
            FirebaseManager.shared.createNewConversation(with: otherUserUsername, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("MESSAGE SENT")
                    self?.isNewConversation = false
                } else {
                    print("FAILED TO SEND")
                }
            })
        } else {
            guard let conversationID = conversationID, let name = self.title else {
                return
            }
            // append to existing conversation data
            FirebaseManager.shared.sendMessage(to: conversationID, name: name, otherUserUsername: otherUserUsername, newMessage: message, completion: { success in
                if success {
                    print("Message sent")
                    self.messageInputBar.inputTextView.text = ""
                } else {
                    print("Failed to send")
                }
            })
        }
    }
    
    private func createMessageID() -> String? {
        //date, otherUserUsername, senderUsername, randomInt
        guard let currentUsername = UserDefaults.standard.string(forKey: "student-username") else {
            return nil
        }
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserUsername)_\(currentUsername)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender

        }
        fatalError("Self Sender is nil. Username should be cached")
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return Util.getThemeColor()
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
