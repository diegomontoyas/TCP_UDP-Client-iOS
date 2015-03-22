//
//  ViewController.swift
//  ClienteTCP_UDP
//
//  Created by Diego on 3/14/15.
//  Copyright (c) 2015 diegomontoyas. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, ReporterDelegate, UITextFieldDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var numberOfThreadsTextField: UITextField!
    @IBOutlet weak var numberOfThreadsLabel: UILabel!
 
    let reporter = Reporter()
    var history: [String]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        tableView.dataSource = self
        reporter.delegate = self
        numberOfThreadsLabel.text = reporter.numberOfThreads.description
        
        numberOfThreadsTextField.delegate = self
        
        history = reporter.history
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        reporter.numberOfThreads = numberOfThreadsTextField.text.toInt()!
        textField.endEditing(true)
        return true
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func updateButtonPressed(sender: AnyObject)
    {
        reporter.numberOfThreads = numberOfThreadsTextField.text.toInt()!
        numberOfThreadsLabel.text = reporter.numberOfThreads.description
    }
    
    @IBAction func startStopButtonPressed(sender: UIButton)
    {
        reporter.startStop()
        startStopButton.setTitle(reporter.reporting ? "Detener":"Iniciar", forState: UIControlState.Normal)
    }
    
    @IBAction func protocolChanged(sender: UISegmentedControl)
    {
        reporter.protocolToUSe = sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return history.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("HistoryCell") as UITableViewCell!
        cell.textLabel!.text = history[indexPath.row]
        return cell
    }
    
    func reporterDidReportLocation(reporter: Reporter)
    {
        numberOfThreadsLabel.text = reporter.numberOfThreads.description
        startStopButton.setTitle(reporter.reporting ? "Detener":"Iniciar", forState: UIControlState.Normal)

        history = reporter.history
        tableView.reloadData()
        
        if history.count > 0
        {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: history.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
}

