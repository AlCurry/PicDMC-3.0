//
//  ViewController.swift
//  PhotoDMW
//
//  Created by Al Curry on 11/8/17.
//

import UIKit
import Photos
import ForecastIO
import CoreLocation

extension UserDefaults {
    static var measure : String {
        return UserDefaults().string(forKey: "user_measure") ?? ""
    }
    static var font_color : String {
        return UserDefaults().string(forKey: "user_font_color") ?? ""
    }
    static var labels : String {
        return UserDefaults().string(forKey: "user_label") ?? ""
    }
}

class ViewController: UIViewController, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    var havePushedImageVC = false
    
    let manager = CLLocationManager()
    
    var currentLatitude: Double = 0.0
    var currentLongitude: Double = 0.0
    var picLat: Double = 0.0
    var picLong: Double = 0.0
    var picImage: UIImage!
    var picCreationDate : Date?
    var picDescription : String!
    
    var pAddress : String = ""
    var pDistanceMiles : Double = 0.0
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    let client = DarkSkyClient(apiKey: "662e626026f320de24eda9df36ec7d01")
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.tempLabel.text = ""
        self.distanceLabel.text = ""
        self.timeLabel.text = ""
        self.addressLabel.text = ""
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if havePushedImageVC == false {
            push()
            havePushedImageVC = true
        }
    }
    
    @IBAction func barButtonTouchUpInside(_ sender: UIBarButtonItem) {
        push()
    }
    
    func push(){
        let viewController = UIImagePickerController()
        viewController.delegate = self
        
        // enable ImagePickerControl to support landscape mode
        viewController.modalPresentationStyle = .overCurrentContext
        
        present(viewController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
        
    }
    
    func getAddress(point location: CLLocation, completion: @escaping (_ address: String?) -> ()) {
        
        let ceo: CLGeocoder = CLGeocoder()
        //let loc: CLLocation = CLLocation(latitude:picLat, longitude: picLong)
        
        var address : String = String()
        var shortAddress : String = String()
        ceo.reverseGeocodeLocation(location, completionHandler:
            {(placemarks, error) in
                if (error != nil)
                {
                    print("reverse geodcode fail: \(error!.localizedDescription)")
                }
                let pm = placemarks! as [CLPlacemark]
                
                if pm.count > 0 {
                    let pm = placemarks![0]
                    /*
                     print(pm.country)
                     print(pm.locality)
                     print(pm.subLocality)
                     print(pm.thoroughfare)
                     print(pm.postalCode)
                     print(pm.subThoroughfare)
                    */
                    if pm.subLocality != nil {
                        address = address + pm.subLocality! + ", "
                        shortAddress = shortAddress + pm.subLocality! + ", "
                    }
                    if pm.subThoroughfare != nil {
                        address = address + pm.subThoroughfare! + " "
                    }
                    if pm.thoroughfare != nil {
                        address = address + pm.thoroughfare! + ", "
                    }
                    if pm.locality != nil {
                        address = address + pm.locality! + ", "
                    }
                    if pm.country != nil {
                        address = address + pm.country!
                        shortAddress = shortAddress + pm.country!
                    }
                    if pm.postalCode != nil {
                        address = address + ", " + pm.postalCode! + " "
                        shortAddress = shortAddress + ", " + pm.postalCode! + " "
                    }
                    
                    //print(address)
                }
                completion(address)
                self.pAddress = address
                self.picDescription = shortAddress
                print("short addr: ", shortAddress)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "to_map" {
            guard let mapViewController = segue.destination as? MapViewController else {
                fatalError()
            }
            
            mapViewController.photoLatitude = picLat
            mapViewController.photoLongitude = picLong
            mapViewController.photoAddress = pAddress
            if (pDistanceMiles > 2000) {
               mapViewController.photoSpan = 2.0
            } else if (pDistanceMiles > 10) {
               mapViewController.photoSpan = 0.1
            } else {
               mapViewController.photoSpan = 0.01
            }

        }
        if segue.identifier == "to_photo" {
            guard let photoViewController = segue.destination as? PhotoViewController else {
                fatalError()
            }
            photoViewController.picImage = picImage
            photoViewController.picCreationDate = picCreationDate // ?? nil
            photoViewController.picDescription = picDescription

        }
    }
    
    
    func updateForForecast(forecast: Forecast) {
        
        let currentTemp = forecast.currently?.temperature

        let intTemp = UserDefaults.measure == "metric" ? getCelsius(forTemp: currentTemp!) : Int(currentTemp!)
        let summary = (forecast.currently?.summary ?? "").lowercased()
        
        let coordinate0 = CLLocation(latitude: self.currentLatitude, longitude: self.currentLongitude)
        let coordinate1 = CLLocation(latitude: CLLocationDegrees(self.picLat), longitude: CLLocationDegrees(self.picLong))
        
        self.getAddress(point: coordinate1) { (address:String?) in
            //print("address ", address ?? "")
            print(self.timeAtPlace(time: (forecast.currently?.time)!, timezone: forecast.timezone))
            let convertedTime = self.timeAtPlace(time: (forecast.currently?.time)!, timezone: forecast.timezone)
            DispatchQueue.main.async(execute: {

                self.setFontColor(color: UserDefaults.font_color)
                
                if (UserDefaults.labels != "no") {
                    self.tempLabel.text = "weather now  \(summary) \(intTemp)"
                    self.timeLabel.text = "time \(convertedTime)"
                    self.addressLabel.text = "address \n\(address!)"
                } else {
                    self.tempLabel.text = "\(summary) \(intTemp)"
                    self.timeLabel.text = "\(convertedTime)"
                    self.addressLabel.text = "\(address!)"
                }
                
                self.distanceLabel.text = self.distanceBetween(point1: coordinate0, point2: coordinate1)
            })
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        imageView.image = image
        picImage = image
        
        picLat = 0.0
        picLong = 0.0
        self.navigationItem.rightBarButtonItems?[1].isEnabled = true
        
        if let url = info["UIImagePickerControllerReferenceURL"] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
            if let asset = assets.firstObject, let location = asset.location, let creationDate = asset.creationDate {
                
                print("creationDate : ", creationDate)
                picLat = location.coordinate.latitude
                picLong = location.coordinate.longitude
                picCreationDate = creationDate
                client.getForecast(latitude: picLat,
                                   longitude: picLong,
                                   completion: { (result:Result<Forecast>) in
                                    if let f = result.value.0 {
                                        self.updateForForecast(forecast: f)
                                    }
                })
            }
            print("picLat :", picLat)
            print("picLong :", picLong)
            
            picker.dismiss(animated: true, completion: nil)
            
            if (picLat == 0.0 && picLong == 0.0) {
                self.addressLabel.text = "This is not a standard iPhone photo image, details not available"
                self.tempLabel.text = ""
                self.distanceLabel.text = ""
                self.timeLabel.text = ""
                picCreationDate = nil
                picDescription = ""
                
                // disable map option since latitude and longitude are 0 in this case
                self.navigationItem.rightBarButtonItems?[1].isEnabled = false
            }
        }
    }
    func distanceBetween(point1: CLLocation, point2: CLLocation) -> String {
        
        //let coordinate1 = CLLocation(latitude: 37.785834, longitude: -122.406417)   // San Francisco
        //let coordinate1 = CLLocation(latitude: 40.693058, longitude: -73.9938)   // NYC (Bk)
        //let coordinate0 = CLLocation(latitude: 52.5200, longitude: 13.4050)         // Berlin
        var distanceString : String = ""
        
        let distanceInMeters = point1.distance(from: point2)
        let distanceInMiles = distanceInMeters / 1609.344
        pDistanceMiles = distanceInMiles
        
        //print("EXT distance from current location to picture location in meters : ", distanceInMeters)
        //print("EXT distance  in km : ", distanceInMeters/1000)
        //print("EXT distance in miles : ", round(distanceInMiles) )
        
        if (UserDefaults.measure == "metric") {
            if (distanceInMeters < 1000) {
                print("meters: ", distanceInMeters)
                let intMDistance = Int(round(distanceInMeters))
                distanceString = "\(intMDistance) meters"
            } else {
                let intKmDistance = Int(round(distanceInMeters / 1000))
                distanceString = "\(intKmDistance) km"
            }
        } else {  // if not metric, assume imperial (miles/feet)
            if (distanceInMiles < 1) {
                let intFeetDistance = Int(round(distanceInMiles * 5280))
                distanceString = "\(intFeetDistance) feet"
            } else {
                let intMileDistance = Int(round(distanceInMiles))
                distanceString = "\(intMileDistance) miles"
            }
        }

        if (UserDefaults.labels != "no") {
            distanceString = "distance " + distanceString
        }
        return distanceString
    }
    
    func timeAtPlace(time: Date, timezone: String) -> String {
        
        print(time)
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeZone = TimeZone(identifier: timezone)
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let convertedTime = dateFormatter.string(from: Date())

        return convertedTime
    }
    
    func getCelsius(forTemp: Float) -> Int {
        
        var celsius : Float = 0
        
        celsius = (( forTemp - 32 ) * 5.0 ) / 9.0
        
        return Int(round(celsius))
    }
    
    func setFontColor(color: String)  {
        
        if (color == "black") {
            self.tempLabel.textColor = UIColor.black
            self.distanceLabel.textColor = UIColor.black
            self.timeLabel.textColor = UIColor.black
            self.addressLabel.textColor = UIColor.black
        } else {
            self.tempLabel.textColor = UIColor.white
            self.distanceLabel.textColor = UIColor.white
            self.timeLabel.textColor = UIColor.white
            self.addressLabel.textColor = UIColor.white
            
        }
    }

}


