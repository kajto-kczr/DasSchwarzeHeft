//
//  ItemViewController.swift
//  CoreDataStoryboard
//
//  Created by Kajetan Kuczorski on 31.08.20.
//  Copyright © 2020 Kajetan Kuczorski. All rights reserved.
//

import UIKit
import CoreData

class ItemViewController: UIViewController {
    
    internal var cellTitle = UITableViewCell()
    internal var cellCost = UITableViewCell()
    internal var cellDate = UITableViewCell()
    internal var cellIsPayed = UITableViewCell()
    internal var cellType = UITableViewCell()
    internal var cellNotice = UITableViewCell()
    @IBOutlet weak var paidButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var currentItem: Item!
    var debtItem: DebtItem!
    var currentPerson: Person!
    var sections: [(name: String, cell: UITableViewCell)] = []
    
    var isPayed: Bool = false {
        didSet {
            paidButton.title = isPayed ? "Unpaid" : "Paid"
        }
    }
    var type: itemType = .personal {
        didSet {
            let btn = cellType.contentView.subviews[0] as! UIButton
            btn.setTitle(type.name, for: UIControl.State())
        }
    }
    var datePicker: UIDatePicker!
    var descriptionTextfield: UITextField!
    var fromDebtViewController: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Debt Item"
        isPayed = fromDebtViewController ? debtItem.isPayed : currentItem.isPayed
        paidButton.title = isPayed ? "Unpaid" : "Paid"
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        cellTitle = tableView.dequeueReusableCell(withIdentifier: "basic")!
        cellCost = tableView.dequeueReusableCell(withIdentifier: "basic")!
        cellDate = tableView.dequeueReusableCell(withIdentifier: "basic")!
        cellIsPayed = tableView.dequeueReusableCell(withIdentifier: "basic")!
        cellType = tableView.dequeueReusableCell(withIdentifier: "basic")!
        cellNotice = tableView.dequeueReusableCell(withIdentifier: "basic")!
        
        let lblTitle = cellTitle.contentView.subviews[0] as! UILabel
        lblTitle.text = fromDebtViewController ? debtItem.name : currentItem.name
        
        let lblDate = cellDate.contentView.subviews[0] as! UILabel
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        lblDate.text = df.string(from: fromDebtViewController ? debtItem.datum! : currentItem.date!)
        
        let lblCost = cellCost.contentView.subviews[0] as! UILabel
        lblCost.text = fromDebtViewController ? "\(debtItem.cost)" : "\(currentItem.cost) €"
        
        let lblType = cellType.contentView.subviews[0] as! UILabel
        lblType.text = fromDebtViewController ? debtItem.type : currentItem.type
        
        let lblIsPayed = cellIsPayed.contentView.subviews[0] as! UILabel
        if !fromDebtViewController {
            lblIsPayed.text = currentItem.isPayed ? "Yes" : "No"
        } else {
            lblIsPayed.text = debtItem.isPayed ? "Yes" : "No"
        }
        
        let lblDescription = cellNotice.contentView.subviews[0] as! UILabel
        lblDescription.text = fromDebtViewController ? debtItem.notice : currentItem.notice
        
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
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func paidButtonTapped(_ sender: UIButton) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entityName: String = fromDebtViewController ? "DebtItem" : "Item"
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let predicateArg = fromDebtViewController ? debtItem.name : currentItem.name
        let predicate = NSPredicate(format: "name = %@", predicateArg!)
        fetchRequest.predicate = predicate
        
        do {
            let fetchResults = try managedContext.fetch(fetchRequest)
            if fetchResults.count != 0 {
                let managedObject = fetchResults[0]
                managedObject.setValue(isPayed ? false : true, forKey: "isPayed")
                
                try managedContext.save()
            }
        } catch {
            print(error.localizedDescription)
        }
        
        NotificationCenter.default.post(Notification(name: Notification.Name("reloadItemTable")))
        NotificationCenter.default.post(Notification(name: Notification.Name("reloadTable")))
        NotificationCenter.default.post(Notification(name: Notification.Name("reloadDebtTable")))
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cellButtonTapped(_ sender: UIButton) {

    }
}

extension ItemViewController: UITableViewDataSource {
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
