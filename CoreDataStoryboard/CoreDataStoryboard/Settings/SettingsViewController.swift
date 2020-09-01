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

class SettingsViewController: UIViewController {

    var people: [NSManagedObject] = []
    var debtItems: [NSManagedObject] = []
    var loanLabel = UILabel()
    var debtLabel = UILabel()
    var debtValue: Double = 0.0 {
        didSet {
            debtLabel.text = "Debts: \(debtValue) €"
        }
    }
    var loanValue: Double = 0.0 {
           didSet {
               loanLabel.text = "Loans: \(debtValue) €"
           }
       }

    @IBOutlet weak var pieChart: CSPieChart!
    var dataList: [CSPieChartData] = []

    var colorList = [UIColor.red, UIColor.green, UIColor.yellow]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "Das schwarze Heft"
        pieChart.frame = CGRect(x: view.frame.width/2, y: 0, width: view.frame.width/2, height: view.frame.width/2)
        pieChart.backgroundColor = UIColor.clear
//        calculateData()
        setupUI()
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
    
    }
    
    func calculateData() {
        for p in people {
            let person = p as? Person
            if (person?.items!.count)! > 0 {
                for i in person!.items! {
                    let item = i as? Item
                    loanValue += item!.cost
                }
            }
        }
        
        for i in debtItems {
            let item = i as? DebtItem
            debtValue += item!.cost
        }
        
        dataList.append(CSPieChartData(key: "Loans", value: loanValue))
        dataList.append(CSPieChartData(key: "Debts", value: debtValue))
    }
    
    func setupUI() {
        loanLabel = UILabel()
        loanLabel.text = "Loans: \(loanValue) €"
        debtLabel = UILabel()
        debtLabel.text = "Debts: \(debtValue) €"
        loanLabel.frame = CGRect(x: 20, y: 0, width: view.frame.width/3, height: view.frame.width/3)
        debtLabel.frame = CGRect(x: 20, y: loanLabel.frame.maxY + 20, width: view.frame.width/3, height: view.frame.width/3)
        view.addSubview(loanLabel)
        view.addSubview(debtLabel)
        
        // Labels falsch
        // Add Category Type
        // Choose Währung
        // Export List
        // import List
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
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let label = UILabel(frame: view.frame)
        label.font = UIFont.systemFont(ofSize: 8)
        label.text = dataList[index].key
        view.addSubview(label)
        
        return view
    }
}

extension SettingsViewController: CSPieChartDelegate {
    
}
