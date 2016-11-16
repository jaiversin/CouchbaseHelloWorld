//
//  ViewController.swift
//  CouchbaseHelloWorld
//
//  Created by Usuario on 11/15/16.
//  Copyright © 2016 Jhon Jaiver López. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    var statusLiveQuery: CBLLiveQuery!
    
    fileprivate struct Configuration {
        static let syncURL = URL(string: "http://localhost:4984/dash")!
        static let dbName = "dash"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let database = buildDatabse() {
            startPullReplicator(database: database)
            let query : CBLQuery = createViewQuery(database: database)!
//            let query : CBLQuery = createAllDocsQuery(database: database)!
            createLiveQuery(query: query)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    func buildDatabse() -> CBLDatabase? {
        guard let database = try? CBLManager.sharedInstance().databaseNamed(Configuration.dbName)
            else {
                return nil
        }
        return database
    }

    func startPullReplicator (database: CBLDatabase) {
        let pull = database.createPullReplication(Configuration.syncURL)
        
        pull.continuous = true
//        pull.channels = ["facilitystatus"]
        observeSync(pull: pull)
        
        pull.start()
    }
    
    func observeSync(pull: CBLReplication) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onReplicationChanged),
            name: NSNotification.Name.cblReplicationChange,
            object: pull)
    }
    
    @objc  func onReplicationChanged(note: NSNotification) {
        print("\(note)")
    }
    
    func createViewQuery (database: CBLDatabase) -> CBLQuery?{
        let view = database.viewNamed("facilityStatusView")
        if view.mapBlock == nil {
            view.setMapBlock({ (doc, emit) -> Void in
                if let _ = doc["waitMinutes"] as? Int {
                    emit(doc["id"], nil)
                }
            }, version: "1.6")
        }
        
        return view.createQuery()

    }
    
    func createAllDocsQuery(database: CBLDatabase) -> CBLQuery? {
        return database.createAllDocumentsQuery()
    }
    
    func createLiveQuery (query: CBLQuery) {
        statusLiveQuery = query.asLive()
        
        statusLiveQuery.addObserver(self, forKeyPath: "rows", options: .new, context: nil)
        statusLiveQuery.start()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? NSObject == statusLiveQuery {
            printAllRows()
        }
    }
    
    func printAllRows () {
        let rows = statusLiveQuery.rows?.allObjects as? [CBLQueryRow] ?? nil
        
        print(rows)
        
    }
    
}

