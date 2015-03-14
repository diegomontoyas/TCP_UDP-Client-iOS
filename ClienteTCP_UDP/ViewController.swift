//
//  ViewController.swift
//  ClienteTCP_UDP
//
//  Created by Diego on 3/14/15.
//  Copyright (c) 2015 diegomontoyas. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, ReporterDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startStopButton: UIButton!
 
    let reporter = Reporter()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        tableView.dataSource = self
        reporter.delegate = self
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startStopButtonPressed(sender: UIButton)
    {
        reporter.startStop()
        startStopButton.titleLabel!.text = reporter.reporting ? "Detener":"Iniciar"
    }
    
    @IBAction func protocolChanged(sender: UISegmentedControl)
    {
        reporter.protocolToUSe = sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)!
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return reporter.history.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("HistoryCell") as UITableViewCell!
        cell.textLabel!.text = reporter.history[indexPath.row]
        return cell
    }
    
    func reporterDidReportLocation(reporter: Reporter)
    {
        tableView.reloadData()
    }
}

