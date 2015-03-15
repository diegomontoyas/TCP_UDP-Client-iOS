//
//  System.swift
//  ClienteTCP_UDP
//
//  Created by Diego on 3/14/15.
//  Copyright (c) 2015 diegomontoyas. All rights reserved.
//

import UIKit
import CoreLocation

protocol ReporterDelegate
{
    func reporterDidReportLocation(reporter:Reporter)
}

class Reporter: NSObject, CLLocationManagerDelegate
{
    let locationManager = CLLocationManager()
    let reportingInterval = 1.0
    let historyLimit = 100
    
    let serverIP = ""
    let serverTCPPort = 8080 as UInt16
    let serverUDPPort = 8080 as UInt16
    
    let UDPSocket: GCDAsyncUdpSocket!
    let TCPSocket: GCDAsyncSocket!
    
    private(set) var history = [String]()
    var historyLock = NSObject()
    
    private var reportingTimer: NSTimer!
    var protocolToUSe = "TCP"
    private(set) var reporting = false
    
    var numberOfThreads: Int = 1
    {
        didSet
        {
            updateThreads()
        }
    }
    
    var operationQueues = [NSOperationQueue]()
    
    var delegate: ReporterDelegate?
    
    override init()
    {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = CLLocationAccuracy.infinity
            
        locationManager.requestWhenInUseAuthorization()
        
        UDPSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        TCPSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
    }
    
    func startStop()
    {
        if !reporting
        {
            establishConnectionAndStartReporting()
        }
        else
        {
            reportingTimer.invalidate()
        }
    }
    
    private func establishConnectionAndStartReporting()
    {
        reportingTimer = NSTimer.scheduledTimerWithTimeInterval(self.reportingInterval, target: self, selector: Selector("reportingTimerTicked:"), userInfo: nil, repeats: true)
       
        createThreads()
    }
    
    private func updateThreads()
    {
        for operationQueue in operationQueues
        {
            operationQueue.cancelAllOperations()
        }
        operationQueues = []
        
        createThreads()
    }
    
    private func createThreads()
    {
        for i in 1...numberOfThreads
        {
            addThread(i)
        }
    }
    
    private func addThread(tag:Int)
    {
        let operationQueue = NSOperationQueue()
        operationQueue.addOperation(ReporterOperation(reporter: self, tag: tag))
        operationQueues.append(operationQueue)
    }
    
    private func removeThread()
    {
        operationQueues.last?.cancelAllOperations()
        operationQueues.removeLast()
    }
    
    func reportingTimerTicked(timer:NSTimer)
    {
        dispatch_async(dispatch_get_main_queue()){
            
            self.delegate?.reporterDidReportLocation(self)
            ()
        }
    }
    
    private func addToHistory(event:String)
    {
        objc_sync_enter(historyLock)
        
        if history.count == historyLimit
        {
            history.removeAtIndex(0)
        }
        
        history.append(event)
        
        objc_sync_exit(historyLock)
    }

    // LocationDelegate

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        locationManager.startUpdatingLocation()
    }
}

class ReporterOperation: NSOperation
{
    let reporter:Reporter!
    let tag:Int!
    
    init(reporter:Reporter, tag:Int)
    {
        super.init()
        self.reporter = reporter
        self.tag = tag
    }
    
    override func main()
    {
        while !cancelled
        {
            let coordinate = reporter.locationManager.location.coordinate
            let event = "\(coordinate.latitude), \(coordinate.longitude): \(reporter.protocolToUSe)"
            let data = (event as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
            
            if reporter.protocolToUSe == "TCP"
            {
                sendDataOverTCP(data, eventDescription: event)
            }
            else
            {
                sendDataOverUDP(data, eventDescription: event)
            }
            
            NSThread.sleepForTimeInterval(reporter.reportingInterval)
        }
    }
    
    private func sendDataOverUDP(data: NSData, eventDescription:String)
    {
        reporter.UDPSocket.sendData(data, toHost: reporter.serverIP, port: reporter.serverTCPPort, withTimeout: 0.0, tag: 0)
        reporter.addToHistory(eventDescription)
    }
    
    private func sendDataOverTCP(data: NSData, eventDescription:String)
    {
        var error:NSError? = nil
        
        reporter.TCPSocket.connectToHost(reporter.serverIP, onPort: reporter.serverTCPPort, error: &error)
        reporter.addToHistory(eventDescription)
    }
}
