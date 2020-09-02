//
//  DebtViewController.swift
//  CoreDataStoryboard
//
//  Created by Kajetan Kuczorski on 01.09.20.
//  Copyright © 2020 Kajetan Kuczorski. All rights reserved.
//

import UIKit
import CoreData

class DebtViewController: UIViewController {

    @IBOutlet weak var debtLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var debtItems: [NSManagedObject] = []
    var debtItem: DebtItem!
    var currency: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "Das schwarze Heft"
        currency = UserDefaults.standard.optionalString(forKey: "currency") ?? "€"
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable(notification:)), name: NSNotification.Name(rawValue: "reloadDebtTable"), object: nil)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCoreData()
        debtLabel.text = "- \(getOverallDebt()) \(currency!)"
    }
    
    func fetchCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DebtItem")
        
        do {
            debtItems = try managedContext.fetch(fetchRequest)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getOverallDebt() -> Double {
        var sum: Double = 0.0
        for i in debtItems {
            let item = i as! DebtItem
            if !item.isPayed {
                sum += item.cost
            }
        }
        
        return sum
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addDebtItem" {
            let nav = segue.destination as! UINavigationController
            let dest = nav.topViewController as! DetailViewController
            dest.fromDebtViewController = true
        } else if segue.identifier == "toDebtItem" {
            let nav = segue.destination as! UINavigationController
            let dest = nav.topViewController as! ItemViewController
            dest.fromDebtViewController = true
            dest.debtItem = debtItem
        }
    }
    
    @objc func reloadTable(notification: NSNotification) {
        fetchCoreData()
        debtLabel.text = "- \(getOverallDebt()) \(currency!)"
        tableView.reloadData()
    }
}

extension DebtViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        debtItem = debtItems[indexPath.row] as? DebtItem
        performSegue(withIdentifier: "toDebtItem", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return debtItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let debtItem = debtItems[indexPath.row] as! DebtItem
        cell.textLabel?.text = debtItem.value(forKey: "name") as? String
        cell.detailTextLabel?.text = "\(debtItem.cost) \(currency!)"
        cell.detailTextLabel?.textColor = (debtItem.value(forKey: "isPayed") as! Bool) ? UIColor.green : UIColor.red
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let managedContext = appDelegate?.persistentContainer.viewContext
            managedContext?.delete(debtItems[indexPath.row] as NSManagedObject)
            debtItems.remove(at: indexPath.row)
            
            do {
                try managedContext?.save()
            } catch {
                print(error.localizedDescription)
            }
        }
        tableView.reloadData()
    }
}
