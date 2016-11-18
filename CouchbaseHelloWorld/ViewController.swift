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
    
    struct Configuration {
        static let syncURL = NSURL(string: "http://localhost:4984/dash")!
        static let dbName = "dash"
        static let localdbName = "dash-nonprod"
        static let localdbExtension = "cblite2"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let database = buildDatabse() {
            startPullReplicator(database)
            let query : CBLQuery = createViewQuery(database)!
            //            let query : CBLQuery = createAllDocsQuery(database: database)!
            createLiveQuery(query)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func buildDatabse() -> CBLDatabase? {
        
        //If none present, then create it with the one shipped in the bundle
        let cannedDbPath = NSBundle.mainBundle().pathForResource(Configuration.localdbName, ofType: Configuration.localdbExtension)
        
        try? CBLManager.sharedInstance().replaceDatabaseNamed(Configuration.dbName, withDatabaseDir: cannedDbPath!)
        
        let database = try? CBLManager.sharedInstance().existingDatabaseNamed(Configuration.dbName)
        
        if database == nil {
            print("Unable to copy local database from bundle")
            return nil
        }
        
        return database
    }
    
    func startPullReplicator (database: CBLDatabase) {
        let pull = database.createPullReplication(Configuration.syncURL)
        
        pull.continuous = true
        //        pull.channels = ["facilitystatus"]
        observeSync(pull)
        
        pull.start()
    }
    
    func observeSync(pull: CBLReplication) {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(onReplicationChanged),
            name: kCBLReplicationChangeNotification,
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
                    emit(doc["id"]!, nil)
                }
                }, version: "6")
        }
        
        return view.createQuery()
        
    }
    
    func createAllDocsQuery(database: CBLDatabase) -> CBLQuery? {
        return database.createAllDocumentsQuery()
    }
    
    func createLiveQuery (query: CBLQuery) {
        statusLiveQuery = query.asLiveQuery()
        
        statusLiveQuery.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        statusLiveQuery.start()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if object as? NSObject == statusLiveQuery {
            printAllRows()
        }
    }
    
    func printAllRows () {
        let rows = statusLiveQuery.rows?.allObjects as? [CBLQueryRow] ?? nil
        
        print(rows)
        
    }
    
}

