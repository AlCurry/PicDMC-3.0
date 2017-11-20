//
//  MapViewController.swift
//  PhotoDMW
//
//  Created by Al Curry on 11/15/17.
//  Copyright © 2017 ]. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var photoMapView: MKMapView!
    
    var photoLatitude = 0.0
    var photoLongitude = 0.0
    var photoSpan = 0.1
    var photoAddress : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var photoRegion = MKCoordinateRegion()
        var center = CLLocationCoordinate2D()
        center.latitude = photoLatitude
        center.longitude = photoLongitude
        var span = MKCoordinateSpan()
        span.latitudeDelta = photoSpan
        span.longitudeDelta = photoSpan
        
        photoRegion.center = center
        photoRegion.span = span
        photoMapView.setRegion(photoRegion, animated: true)
        
        let photoPoint = MKPointAnnotation()
        photoPoint.coordinate = center
        photoPoint.title = photoAddress
        photoMapView.addAnnotation(photoPoint)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
