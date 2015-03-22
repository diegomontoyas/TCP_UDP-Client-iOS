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
    let historyLimit = 1000
    
    let serverIP = "192.168.0.11"
    let serverTCPPort = 5050 as UInt16
    let serverUDPPort = 4040 as UInt16
    
    private(set) var history = [String]()
    var historyLock = NSObject()
    
    private var reportingTimer: NSTimer!
    var protocolToUSe: String = "TCP"
    {
        didSet
        {
            updateThreads()
        }
    }
    
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
    }
    
    func startStop()
    {
        if !reporting
        {
            establishConnectionAndStartReporting()
            reporting = true
        }
        else
        {
            killThreads()
            reportingTimer.invalidate()
            reporting = false
        }
    }
    
    private func establishConnectionAndStartReporting()
    {
        createThreads()
        
        reportingTimer = NSTimer.scheduledTimerWithTimeInterval(self.reportingInterval, target: self, selector: Selector("reportingTimerTicked:"), userInfo: nil, repeats: true)
    }
    
    private func updateThreads()
    {
        if !reporting
        {
            startStop()
        }
        
        killThreads()
        createThreads()
    }
    
    private func createThreads()
    {
        println("Creating threads")

        for i in 1...numberOfThreads
        {
            addThread(i)
        }
    }
    
    private func killThreads()
    {
        println("Killing threads")
        for operationQueue in operationQueues
        {
            operationQueue.cancelAllOperations()
        }
        operationQueues = []
    }
    
    private func addThread(tag:Int)
    {
        let operationQueue = NSOperationQueue()
        operationQueue.addOperation(ReporterOperation(reporter: self, tag: tag))
        operationQueues.append(operationQueue)
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
    
    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int)
    {
        
    }
    
    // LocationDelegate

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        locationManager.startUpdatingLocation()
    }
}

class ReporterOperation: NSOperation, GCDAsyncSocketDelegate
{
    let reporter:Reporter!
    let tag:Int!
    
    let queue = NSOperationQueue()
    var TCPSocket: GCDAsyncSocket!
    let UDPSocket: GCDAsyncUdpSocket!
    
    let protocolToUSe: String!
    
    init(reporter:Reporter, tag:Int)
    {
        super.init()
        self.reporter = reporter
        self.tag = tag
        self.protocolToUSe = reporter.protocolToUSe
        
        if protocolToUSe == "TCP"
        {
            TCPSocket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
            var error:NSError? = nil
            TCPSocket.connectToHost(reporter.serverIP, onPort: reporter.serverTCPPort, error: &error)
        }
        else
        {
            UDPSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue)
        }
    }
    
    override func main()
    {
        while !cancelled
        {
            let TCP = protocolToUSe == "TCP"

            sendData()
            
            NSThread.sleepForTimeInterval(reporter.reportingInterval)
        }
    }
    
    private func sendData()
    {
        let TCP = protocolToUSe == "TCP"
        var error:NSError? = nil
        
        if TCP && TCPSocket.isDisconnected
        {
            TCPSocket.connectToHost(reporter.serverIP, onPort: reporter.serverTCPPort, error: &error)
        }
        
        if (TCP && TCPSocket.isConnected) || !TCP
        {
            let location = reporter.locationManager.location
            let coordinate = location.coordinate
            let events = ["t\(tag)-lat-\(abs(coordinate.latitude))", "t\(tag)-long-\(abs(coordinate.longitude))", "t\(tag)-alt-\(location.altitude)", "t\(tag)-speed-\(abs(location.speed))"]
            
            for event in events
            {
                let data = (event as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
                
                if TCP
                {
                    sendDataOverTCP(data, eventDescription: event)
                }
                else
                {
                    sendDataOverUDP(data, eventDescription: event)
                }
            }
        }
        else
        {
            reporter.addToHistory("T\(tag) Connection Failed")
        }
    }
    
    private func sendDataOverUDP(data: NSData, eventDescription:String)
    {
        UDPSocket.sendData(data, toHost: reporter.serverIP, port: reporter.serverUDPPort, withTimeout: 0.0, tag: 0)
        reporter.addToHistory("UDP: " + eventDescription)
    }
    
    private func sendDataOverTCP(data: NSData, eventDescription:String)
    {
        TCPSocket.writeData(data, withTimeout: 1, tag: 0)
        reporter.addToHistory("TCP: " + eventDescription)
    }
}
