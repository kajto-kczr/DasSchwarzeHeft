//
//  SecondaryViewController.swift
//  CoreDataStoryboard
//
//  Created by Kajetan Kuczorski on 28.08.20.
//  Copyright © 2020 Kajetan Kuczorski. All rights reserved.
//

import UIKit
import CoreData

class SecondaryViewController: UIViewController {
    
    var currentPerson: Person!
    var items: [NSManagedObject] = []
    var currentItem: Item!

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable(notification:)), name: NSNotification.Name("reloadItemTable"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = currentPerson.name!
        fetchCoreData()
        
        for item in items {
            let item = item as! Item
            print(item.name! + " costs: \(item.cost)")
        }
    }
    
    func fetchCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
        let predicate = NSPredicate(format: "person = %@", currentPerson)
        fetchRequest.predicate = predicate
        
        do {
            items = try managedContext.fetch(fetchRequest)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toDetail", sender: self)
        
    }
    
    func saveItem(name: String, cost: Double) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Item", in: managedContext)!
        let item = NSManagedObject(entity: entity, insertInto: managedContext)
        item.setValue(name, forKey: "name")
        item.setValue(cost, forKey: "cost")
        item.setValue(currentPerson, forKey: "person")

        do {
            try managedContext.save()
            items.append(item)
        } catch {
            print(error.localizedDescription)
        }
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "reloadTable")))
    }
    
    @objc func reloadTable(notification: NSNotification) {
        fetchCoreData()
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail" {
            let nav = segue.destination as! UINavigationController
            let dest = nav.topViewController as! DetailViewController
            dest.currentPerson = currentPerson
        } else if segue.identifier == "toItem" {
            let nav = segue.destination as! UINavigationController
            let dest = nav.topViewController as! ItemViewController
            dest.currentItem = currentItem
        }
    }
}

extension SecondaryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentItem = items[indexPath.row] as? Item
        performSegue(withIdentifier: "toItem", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row] as! Item
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = item.value(forKey: "name") as? String
        cell.accessoryType = item.isPayed ? .checkmark : .none
        
        let cost = item.value(forKey: "cost") ?? 0.0
        cell.detailTextLabel?.text = "\(cost) €"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let managedContext = appDelegate?.persistentContainer.viewContext
            managedContext?.delete(items[indexPath.row] as NSManagedObject)
            items.remove(at: indexPath.row)
            
            do {
                try managedContext?.save()
            } catch {
                print(error.localizedDescription)
            }
        }
        tableView.reloadData()
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "reloadTable")))
    }
}
