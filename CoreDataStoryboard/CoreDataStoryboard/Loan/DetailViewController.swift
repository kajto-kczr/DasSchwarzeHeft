//
//  DetailViewController.swift
//  CoreDataStoryboard
//
//  Created by Kajetan Kuczorski on 31.08.20.
//  Copyright © 2020 Kajetan Kuczorski. All rights reserved.
//

import UIKit
import CoreData

enum itemType {
    case personal, business, family, friends, other
    
    var name: String {
        switch self {
        case .personal:
            return "Personal"
        case .business:
            return "Business"
        case .family:
            return "Family"
        case .friends:
            return "Friends"
        case .other:
            return "Other"
        }
    }
}

class DetailViewController: UIViewController {
    
    internal var cellTitle = UITableViewCell()
    internal var cellCost = UITableViewCell()
    internal var cellDate = UITableViewCell()
    internal var cellIsPayed = UITableViewCell()
    internal var cellType = UITableViewCell()
    internal var cellNotice = UITableViewCell()
    
    @IBOutlet weak var tableView: UITableView!
    var currentPerson: Person!
    var sections: [(name: String, cell: UITableViewCell)] = []
    var isPayed: Bool = false {
        didSet {
            let btn = cellIsPayed.contentView.subviews[0] as! UIButton
            btn.setTitle(isPayed ? "Yes" : "No", for: UIControl.State())
        }
    }
    var type: itemType = .personal {
        didSet {
            let btn = cellType.contentView.subviews[0] as! UIButton
            btn.setTitle(type.name, for: UIControl.State())
        }
    }
    
    var fromDebtViewController: Bool = false
    var datePicker: UIDatePicker!
    var descriptionTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add debt item"
        tableView.dataSource = self
        cellTitle = tableView.dequeueReusableCell(withIdentifier: "textfield")!
        cellCost = tableView.dequeueReusableCell(withIdentifier: "textfield")!
        let tfCost = cellCost.contentView.subviews[0] as! UITextField
        tfCost.keyboardType = .numberPad
        cellDate = tableView.dequeueReusableCell(withIdentifier: "datePicker")!
        cellIsPayed = tableView.dequeueReusableCell(withIdentifier: "button")!
        cellType = tableView.dequeueReusableCell(withIdentifier: "button")!
        cellNotice = tableView.dequeueReusableCell(withIdentifier: "textfield")!
        descriptionTextfield = cellNotice.contentView.subviews[0] as! UITextField
        let date = Date()
        let datePicker = cellDate.contentView.subviews[0] as! UIDatePicker
        datePicker.date = date
        self.datePicker = datePicker
        
        let buttonPayed = cellIsPayed.contentView.subviews[0] as! UIButton
        buttonPayed.setTitle("No", for: UIControl.State())
        buttonPayed.tag = 2
        
        let buttonType = cellType.contentView.subviews[0] as! UIButton
        buttonType.setTitle("Private", for: UIControl.State())
        buttonType.tag = 1
        
        sections = [
            (name: "Title:", cell: cellTitle),
            (name: "Datum:", cell: cellDate),
            (name: "Cost:", cell: cellCost),
            (name: "Type:", cell: cellType),
            (name: "Already payed:", cell: cellIsPayed),
            (name: "Description:", cell: cellNotice)
        ]
        
        tableView.rowHeight = self.view.frame.height/16
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        let tfTitle = cellTitle.contentView.subviews[0] as! UITextField
        guard tfTitle.text != "" else {
            showMissingAlert(missing: "title")
            return
        }
        let tfCost = cellCost.contentView.subviews[0] as! UITextField
        guard tfCost.text != "" && tfCost.text?.double != nil else {
            showMissingAlert(missing: "cost")
            return
        }
        if !fromDebtViewController {
            saveItem(name: tfTitle.text!, cost: (tfCost.text?.double!)!)
        } else {
            saveDebtItem(name: tfTitle.text!, cost: (tfCost.text?.double!)!)
        }
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
        // HAVE TO CUSTOMIZE IT
        item.setValue(datePicker.date, forKey: "date")
        item.setValue(isPayed, forKey: "isPayed")
        item.setValue(type.name, forKey: "type")
        item.setValue(descriptionTextfield.text, forKey: "notice")
        
        do {
            try managedContext.save()
        } catch {
            print(error.localizedDescription)
        }
        
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "reloadTable")))
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "reloadItemTable")))
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveDebtItem(name: String, cost: Double) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "DebtItem", in: managedContext)!
        let debtItem = NSManagedObject(entity: entity, insertInto: managedContext)
        
        debtItem.setValue(name, forKey: "name")
        debtItem.setValue(cost, forKey: "cost")
        debtItem.setValue(datePicker.date, forKey: "datum")
        debtItem.setValue(isPayed, forKey: "isPayed")
        debtItem.setValue(type.name, forKey: "type")
        debtItem.setValue(descriptionTextfield.text, forKey: "notice")
        
        do {
            try managedContext.save()
        } catch {
            print(error.localizedDescription)
        }
        
        NotificationCenter.default.post(Notification(name: Notification.Name("reloadDebtTable")))
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cellButtonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 1:
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Personal", style: .default) { [unowned self] action in
                self.type = .personal
            })
            alert.addAction(UIAlertAction(title: "Business", style: .default) { [unowned self] action in
                self.type = .business
            })
            alert.addAction(UIAlertAction(title: "Family", style: .default) { [unowned self] action in
                self.type = .family
            })
            alert.addAction(UIAlertAction(title: "Friends", style: .default) { [unowned self] action in
                self.type = .friends
            })
            alert.addAction(UIAlertAction(title: "Other", style: .default) { [unowned self] action in
                self.type = .other
            })
            present(alert, animated: true)
        case 2:
            let alert = UIAlertController(title: nil, message: "Is the debt payed?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { [unowned self] action in
                self.isPayed = true
            })
            alert.addAction(UIAlertAction(title: "No", style: .default) { [unowned self] action in
                self.isPayed = false
            })
            present(alert, animated: true)
        default:
            print("didnt recognized button")
        }
    }
    
    func showMissingAlert(missing: String) {
        var message: String = ""
        switch missing {
        case "title":
            message = "Please add title to your Debt Item"
        case "cost":
            message = "Please add the debt amount correctly"
        default:
            message = "Something went wrong! please correct your submission"
        }
        let alert = UIAlertController(title: "Oops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

extension DetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].cell
    }
}

extension StringProtocol{
    var double: Double? { Double(self) }
}
