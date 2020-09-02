//
//  ViewController.swift
//  CoreDataStoryboard
//
//  Created by Kajetan Kuczorski on 28.08.20.
//  Copyright © 2020 Kajetan Kuczorski. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var people: [NSManagedObject] = []
    var currentPerson: Person!
    @IBOutlet weak var debtLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var currency: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        currency = UserDefaults.standard.optionalString(forKey: "currency") ?? "€"
        self.navigationItem.title = "Das schwarze Heft"
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable(notification:)), name: NSNotification.Name(rawValue: "reloadTable"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchCoreData()
        debtLabel.text = "- \(getOverallDebt()) \(currency!)"
    }
    
    @objc func reloadTable(notification: NSNotification) {
        debtLabel.text = "- \(getOverallDebt()) \(currency!)"
        tableView.reloadData()
    }
    
    func getOverallDebt() -> Double {
        var sum: Double = 0.0
        for p in people {
            let person = p as! Person
            sum += debtSum(person: person)
        }
        return sum
    }
    
    func fetchCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Person")
        
        do {
            people = try managedContext.fetch(fetchRequest)
        } catch {
            print(error.localizedDescription)
        }
    }

    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "New Debtor", message: "Add a new name", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] action in
            guard let textField = alert.textFields?.first, let nameToSave = textField.text else {
                return
            }
            self.save(name: nameToSave)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func save(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Person", in: managedContext)!
        let person = NSManagedObject(entity: entity, insertInto: managedContext)
        person.setValue(name, forKey: "name")

        
        do {
            try managedContext.save()
            people.append(person)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detail" {
            let nav = segue.destination as! UINavigationController
            let dest = nav.topViewController as! SecondaryViewController
            dest.currentPerson = currentPerson
        }
    }
    
    func debtSum(person: Person) -> Double {
        var sum: Double = 0.0
        for i in person.items! {
            let item = i as! Item
            if !item.isPayed {
                sum += item.cost
            }
        }
        return sum
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let person = people[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = person.value(forKey: "name") as? String
        cell.detailTextLabel?.text = "\(debtSum(person: person as! Person)) \(currency!)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let person = people[indexPath.row] as! Person
        currentPerson = person
        performSegue(withIdentifier: "detail", sender: self)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let managedContext = appDelegate?.persistentContainer.viewContext
            managedContext?.delete(people[indexPath.row] as NSManagedObject)
            people.remove(at: indexPath.row)
            
            do {
                try managedContext?.save()
            } catch {
                print(error.localizedDescription)
            }
        }
        tableView.reloadData()
    }
}



