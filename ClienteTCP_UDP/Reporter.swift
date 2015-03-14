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
    private var reportingTimer: NSTimer!
    var protocolToUSe = "TCP"
    private(set) var reporting = false
    
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
        /*NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            
            
        })*/
        
        reportingTimer = NSTimer.scheduledTimerWithTimeInterval(self.reportingInterval, target: self, selector: Selector("reportingTimerTicked:"), userInfo: nil, repeats: true)
    }
    
    private func reportingTimerTicked(timer:NSTimer)
    {
        if protocolToUSe == "TCP"
        {
            sendLocationOverTCP()
        }
        else
        {
            sendLocationOverUDP()
        }
    }
    
    private func sendLocationOverUDP()
    {
        let coordinate = locationManager.location.coordinate
        let data = NSString(string: "\(coordinate.latitude), \(coordinate.longitude): \(protocolToUSe)").dataUsingEncoding(NSUTF8StringEncoding)!
        
        UDPSocket.sendData(data, toHost: serverIP, port: serverTCPPort, withTimeout: 0.0, tag: 0)
    }
    
    private func sendLocationOverTCP()
    {
        let coordinate = locationManager.location.coordinate
        let data = NSString(string: "\(coordinate.latitude), \(coordinate.longitude): \(protocolToUSe)").dataUsingEncoding(NSUTF8StringEncoding)!
        var error:NSError? = nil
        
        TCPSocket.connectToHost(serverIP, onPort: serverTCPPort, error: &error)
    }
    
    private func addToHistory(event:String)
    {
        if history.count == historyLimit
        {
            history.removeAtIndex(0)
        }
        history.append(event)
        
        dispatch_async(dispatch_get_main_queue()){
            
            self.delegate?.reporterDidReportLocation(self)
            ()
        }
    }

    // LocationDelegate

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        locationManager.startUpdatingLocation()
    }
}
