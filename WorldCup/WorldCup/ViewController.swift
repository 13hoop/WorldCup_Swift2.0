//
//  ViewController.swift
//  WorldCup
//
//  Created by Pietro Rea on 8/2/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, NSFetchedResultsControllerDelegate {
  
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
        
        //		let sortDescriptor = NSSortDescriptor(key: "teamName", ascending: true)
        //		fetchRequset.sortDescriptors = [sortDescriptor]
        
        // 更改排序 - 注意排序不要冲突，否则会乱掉
        let zoneSort = NSSortDescriptor(key: "qualifyingZone", ascending: true)
        let scoreSort = NSSortDescriptor(key: "wins", ascending: false)
        let nameSort = NSSortDescriptor(key: "teamName", ascending: true)
        fetchRequset.sortDescriptors = [zoneSort, scoreSort, nameSort]
        
        // 2 fetch控制器的实例话仍然依赖于 NSFetchRequest 和 context上下文
        // 更改使用keyPath“qualifyingZone”做实例化
        // 再次更改，指定cache的name
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequset, managedObjectContext: coreDataStack.context, sectionNameKeyPath: "qualifyingZone", cacheName: "worldCup")
        
        // 设置代理
        fetchedResultsController.delegate = self
        
        
        // 3 控制器执行获取 －－performFetch && 错误处理
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error:\(error.localizedDescription)")
        }
    }
    
    // MARK: 震动激活添加按钮
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == UIEventSubtype.MotionShake {
            addButton.enabled = true
        }
    }
    @available(iOS 8.0, *)
    @IBAction func addTeam(sender: AnyObject) {
        let alert = UIAlertController(title: "天朝特色", message: "目前看来中国足球进世界杯只能用这种手段了", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Team name"
        }
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Qualifying Zone"
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("－－开始保送国足－－")
            // 1
            let nameTextFeild = alert.textFields![0] 
            let zoneTextFeild = alert.textFields![1] 
            // 2 新插入一个实体－－当然就是万年进不了的国足了
            let team = NSEntityDescription.insertNewObjectForEntityForName("Team", inManagedObjectContext: self.coreDataStack.context) as! Team
            team.teamName = nameTextFeild.text!
            team.qualifyingZone = zoneTextFeild.text!
            team.imageName = "wenderland-flag"
            // 3
            self.coreDataStack.saveContext()
        }))
        
        alert.addAction(UIAlertAction(title: "cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            print("被cancel，果然上帝都要放弃国足了🙀")
        }))
        
        presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: -- DataSource --
    func numberOfSectionsInTableView
        (tableView: UITableView) -> Int {
            return fetchedResultsController.sections!.count
    }
    // 设置title
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
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
            // 刷新UI - 更改到代理中实现
            //			tableView.reloadData()
    }
    
    // MARK: -- NSFetchedResultsControllerDelegate
    // 按照“begin updates-make changes-end updates”的顺序变更
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // 开始更新
        tableView.beginUpdates()
        print(__FUNCTION__)
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        print(__FUNCTION__)
        print("move \(indexPath) -> \(newIndexPath)")
        /*
        根据数据的不同type，进行区分操作
            - Insert - 注意插入时，用newIndexPath
            - Delete
            - Update
            - Move － 删除旧的（indexPath），插入新的(newIndexPath)
        */
        switch type {
        case NSFetchedResultsChangeType.Insert:
            //        tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        case NSFetchedResultsChangeType.Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        case NSFetchedResultsChangeType.Update:
            tableView.cellForRowAtIndexPath(indexPath!) as! TeamCell
        case NSFetchedResultsChangeType.Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//            tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        default :
            break
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // 结束更新
        tableView.endUpdates()
        print(__FUNCTION__)
    }
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        print(__FUNCTION__)
        let indexSet = NSIndexSet(index: sectionIndex)
        
        switch type {
        case NSFetchedResultsChangeType.Insert:
            tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
        case NSFetchedResultsChangeType.Delete:
            tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
        default:
            break
        }
    }
}