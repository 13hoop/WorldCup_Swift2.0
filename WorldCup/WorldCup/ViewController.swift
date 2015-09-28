//
//  ViewController.swift
//  WorldCup
//
//  Created by Pietro Rea on 8/2/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
  
  var coreDataStack: CoreDataStack!
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addButton: UIBarButtonItem!
	
	var fetchedResultsController: NSFetchedResultsController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
		
		setFetchController()

		
    
  }
	
	// MARK:设置fetchedResultsController
	// handles the coordination between Core Data and your table view
	// requires at least one sort descriptor.Note that how would it know the right order for table view
	func setFetchController() {
		// 1 创建请求 ＋ 指定排序
		let fetchRequset = NSFetchRequest(entityName: "Team")
		let sortDescriptor = NSSortDescriptor(key: "teamName", ascending: true)
		fetchRequset.sortDescriptors = [sortDescriptor]
		
		
		// 2 fetch控制器的实例话仍然依赖于 NSFetchRequest 和 context上下文
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequset, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)

		// 3 控制器执行获取 －－performFetch && 错误处理 
		do {
			try fetchedResultsController.performFetch()
		} catch let error as NSError {
			print("Error:\(error.localizedDescription)")
		}
	}
	
	// MARK: -- DataSource --
  func numberOfSectionsInTableView
    (tableView: UITableView) -> Int {
      return fetchedResultsController.sections!.count
  }
  func tableView(tableView: UITableView,
    numberOfRowsInSection section: Int) -> Int {
      let sectionInfo = fetchedResultsController.sections![section] 
      return sectionInfo.numberOfObjects
  }
  func tableView(tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath)
    -> UITableViewCell {
      
      let resuseIdentifier = "teamCellReuseIdentifier"
      let cell =
      tableView.dequeueReusableCellWithIdentifier(
        resuseIdentifier, forIndexPath: indexPath)
        as! TeamCell
			// 配置cell
      configureCell(cell, indexPath: indexPath)
      
      return cell
  }
	func configureCell(cell: TeamCell, indexPath: NSIndexPath) {
		// － 通过fetchCtoller获取数据
		let team = fetchedResultsController.objectAtIndexPath(indexPath) as! Team
		// － cell设置
		cell.flagImageView.image = UIImage(named: team.imageName)
		cell.teamLabel.text = team.teamName
		cell.scoreLabel.text = "Wins: \(team.wins)"
	}
	
  // MARK: -- tableView delegat --
  func tableView(tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath) {

			let team = fetchedResultsController.objectAtIndexPath(indexPath) as! Team
			// tap加1 操作
			let wins = team.wins.integerValue
			team.wins = NSNumber(integer: wins + 1) // 类型转换
			// 保存
			coreDataStack.saveContext()
			// 刷新UI
			tableView.reloadData()
  }
}

