//
//  MeetingViewModel.swift
//  meetups
//
//  Created by Nisarg on 2020-12-07.
//

import Foundation
import Firebase
import SwiftUI
import os

class MeetingViewModel: ObservableObject{
    @Published var meetingList = [Meeting]()
   // @EnvironmentObject() var userViewModel: UserViewModel
    @EnvironmentObject var userSettings: UserSettings
    //private var db = Firestore.firestore()
    private let db: Firestore
    private let auth: Auth
    private let COLLECTION_NAME = "Meetings"
    
    func addMeeting(newMeeting: Meeting){
        do{
            _ = try db.collection(COLLECTION_NAME).addDocument(from: newMeeting)
        }catch let error as NSError{
            print(#function, "Error Creating document")
        }
    }
    
    init(firestore: Firestore, auth: Auth) {
        self.db = firestore
        
        self.auth = auth
    }
    func getAllMeetings(){
       // let userEmail = userSettings.userEmail
        let userEmail = self.auth.currentUser?.email
        db.collection(COLLECTION_NAME)
        .whereField("email", isEqualTo: userEmail as Any)
            .order(by: "meetingDate", descending: true)
            .addSnapshotListener({ (querySnapshot, error) in
                
                guard let snapshot = querySnapshot else{
                    print(#function, "Error fetching documents \(error!.localizedDescription)")
                    return
                }
                
                snapshot.documentChanges.forEach{(doc) in
                    
                    var meeting = Meeting()
                    
                    do{
                        meeting = try doc.document.data(as: Meeting.self)!
                        
                        if doc.type == .added{
                            
                            if (!self.meetingList.contains(meeting)){
                                self.meetingList.append(meeting)
                            }
                        }
                        if doc.type == .modified{
                            //TODO for updated document
                        }
                        
                        if doc.type == .removed{
                            //TODO for deleted document
                            let docID = doc.document.documentID
                            
                            let index = self.meetingList.firstIndex(where: {
                                ($0.id?.elementsEqual(docID))!
                            })
                            
                            if (index != nil){
                                self.meetingList.remove(at: index!)
                            }
                        }
                        self.meetingList.sort{ (currentObj, nextObj) in
                            currentObj.meetingDate > nextObj.meetingDate
                        }
                        
                    }catch let error as NSError{
                        print("Error decoding document : \(error.localizedDescription)")
                    }
                }
            })
    }
    
    func deleteMeeting(index: Int){
        db.collection(COLLECTION_NAME)
            .document(self.meetingList[index].id!)
            .delete{ (error) in
                
                if let error = error{
                    Logger().error("Error deleting document \(error.localizedDescription)")
                }else{
                    Logger().debug("Document successfully deleted.")
                }
                
            }
    }
    func updateMeeting(meeting: Meeting, index: Int){
        
        db.collection(COLLECTION_NAME)
            .document(self.meetingList[index].id!)
            .updateData(["purpose" : meeting.purpose, "meetingDate" : meeting.meetingDate]){ (error) in
                if let error = error{
                    Logger().error("Error updating document \(error.localizedDescription)")
                }else{
                    Logger().debug("Document successfully updated.")
                }
            }
    }
                        
            
    
}
