//
//  SettingsViewController.swift
//  CoreDataStoryboard
//
//  Created by Kajetan Kuczorski on 01.09.20.
//  Copyright © 2020 Kajetan Kuczorski. All rights reserved.
//

import UIKit
import CoreData
import CSPieChart

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var people: [NSManagedObject] = []
    var debtItems: [NSManagedObject] = []
    var loanLabel = UILabel()
    var debtLabel = UILabel()
    var debtValue: Double = 0.0
    var loanValue: Double = 0.0
    let redColors = [UIColor(red: 64/255, green: 13/255, blue: 11/255, alpha: 0.25), UIColor(red: 127/255, green: 27/255, blue: 21/255, alpha: 0.5), UIColor(red: 191/255, green: 40/255, blue: 32/255, alpha: 0.75),
                     UIColor(red: 255/255, green: 53/255, blue: 42/255, alpha: 1)]
    let blueColors = [UIColor(red: 41/255, green: 86/255, blue: 217/255, alpha: 0.85), UIColor(red: 48/255, green: 104/255, blue: 217/255, alpha: 0.85), UIColor(red: 54/255, green: 125/255, blue: 217/255, alpha: 0.85),
                      UIColor(red: 130/255, green: 184/255, blue: 217/255, alpha: 0.85)]
    
    
    @IBOutlet weak var currencyTextfield: UITextField!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var nav: UINavigationItem!
    @IBOutlet weak var pieChart: CSPieChart!
    var dataList: [CSPieChartData] = []
    var currency: String?
    var colorList: [UIColor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "Das schwarze Heft"
        let n = self.navigationController!
        currency = UserDefaults.standard.optionalString(forKey: "currency") ?? "€"
        stack.frame = CGRect(x: 0, y: n.navigationBar.frame.height + 10, width: view.frame.width - 40, height: stack.frame.height)
        let calculateHeight = view.frame.maxY-(120 + stack.frame.height + 40)
        pieChart.frame = CGRect(x: 20, y: debtLabel.frame.maxY+60, width: view.frame.width, height: calculateHeight)
        pieChart.center.x = view.center.x
        pieChart.backgroundColor = UIColor.clear
        
        initializeHideKeyboard()
        pieChart.delegate = self
        pieChart.dataSource = self
        
        pieChart?.pieChartRadiusRate = 0.7
        pieChart.pieChartLineLength = 12
        pieChart.seletingAnimationType = .touch
        
        
        pieChart.show(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchCoreData()
        calculateData()
        setupUI()
    }
    
    func calculateData() {
        dataList.removeAll()
        var loansArray: [(cost: Double, person: String)] = []
        var debtsArray: [(cost: Double, person: String)] = []
        
        loanValue = 0; debtValue = 0
        for p in people {
            let person = p as? Person
            if (person?.items!.count)! > 0 {
                for i in person!.items! {
                    let item = i as? Item
                    if !item!.isPayed {
                        loanValue += item!.cost
                        loansArray.append((cost: item!.cost, person: item!.name!))
                    }
                }
            }
        }
        
        for i in debtItems {
            let item = i as? DebtItem
            if !item!.isPayed {
                debtValue += item!.cost
                debtsArray.append((cost: item!.cost, person: item!.name!))
            }
        }
        
        loansArray.sort { $0.0 > $1.0 }
        debtsArray.sort { $0.0 > $1.0 }
        var loansString = "Loans"
        var debtsString = "Debts"
        var restLoan = loanValue
        var restDebt = debtValue
        
        if loansArray.count >= 3 {
            dataList.append(CSPieChartData(key: loansArray[0].person, value: loansArray[0].cost))
            restLoan -= loansArray[0].cost
            dataList.append(CSPieChartData(key: loansArray[1].person, value: loansArray[1].cost))
            restLoan -= loansArray[1].cost
            dataList.append(CSPieChartData(key: loansArray[2].person, value: loansArray[2].cost))
            restLoan -= loansArray[2].cost
            loansString = "other loans"
            colorList += redColors[0...2]
        } else {
            colorList.append(redColors[0])
        }
        
        if debtsArray.count >= 3 {
            dataList.append(CSPieChartData(key: debtsArray[0].person, value: debtsArray[0].cost))
            restDebt -= debtsArray[0].cost
            dataList.append(CSPieChartData(key: debtsArray[1].person, value: debtsArray[1].cost))
            restDebt -= debtsArray[1].cost
            dataList.append(CSPieChartData(key: debtsArray[2].person, value: debtsArray[2].cost))
            restDebt -= debtsArray[2].cost
            debtsString = "other debts"
            colorList += blueColors[0...2]
        } else {
            colorList.append(blueColors[0])
        }
        
        dataList.append(CSPieChartData(key: loansString, value: restLoan))
        colorList.append(redColors[3])
        dataList.append(CSPieChartData(key: debtsString, value: restDebt))
        colorList.append(blueColors[3])
    }
    
    func setupUI() {
        loanLabel = UILabel()
        loanLabel.text = "Loans: \(loanValue) \(currency!)"
        loanLabel.decorate()
        debtLabel = UILabel()
        debtLabel.text = "Debts: \(debtValue) \(currency!)"
        debtLabel.decorate()
        loanLabel.frame = CGRect(x: 20, y: stack.frame.maxY+20, width: view.frame.width, height: 60)
        debtLabel.frame = CGRect(x: 20, y: loanLabel.frame.maxY + 20, width: view.frame.width, height: 60)
        view.addSubview(loanLabel)
        view.addSubview(debtLabel)
        
        currencyTextfield.placeholder = currency
    }
    
    @IBAction func currencyDoneButtonTapped(_ sender: Any) {
        guard currencyTextfield.text != "" else {
            let alert = UIAlertController(title: nil, message: "Currency field cannot be empty!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        let currency = currencyTextfield.text!
        UserDefaults.standard.set(currency, forKey: "currency")
    }
    
    func fetchCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let loanFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Person")
        let debtFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DebtItem")
        
        do {
            people = try managedContext.fetch(loanFetchRequest)
            debtItems = try managedContext.fetch(debtFetchRequest)
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension SettingsViewController: CSPieChartDataSource {
    func numberOfComponentData() -> Int {
        return dataList.count
    }
    
    func pieChart(_ pieChart: CSPieChart, dataForComponentAt index: Int) -> CSPieChartData {
        return dataList[index]
    }
    
    func numberOfComponentColors() -> Int {
        return colorList.count
    }
    
    func pieChart(_ pieChart: CSPieChart, colorForComponentAt index: Int) -> UIColor {
        return colorList[index]
    }
    
    func numberOfComponentSubViews() -> Int {
        return dataList.count
    }
    
    func pieChart(_ pieChart: CSPieChart, viewForComponentAt index: Int) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        let label = UILabel(frame: view.frame)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 8)
        label.text = dataList[index].key
        view.addSubview(label)
        
        return view
    }
}

extension SettingsViewController: CSPieChartDelegate {
    
}

extension UILabel {
    func decorate() {
        self.font = UIFont.boldSystemFont(ofSize: 30)
    }
}

extension UserDefaults {
    public func optionalString(forKey defaultName: String) -> String? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? String
        }
        return nil
    }
    
    public func optionalInteger(forKey defaultName: String) -> Int? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Int
        }
        return nil
    }
}

extension UIViewController {
    func initializeHideKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
