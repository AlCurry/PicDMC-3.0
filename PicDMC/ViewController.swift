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
    var measure : String {
        return UserDefaults().string(forKey: "user_measure") ?? ""
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
    
    var pAddress : String = ""
    var pDistanceMiles : Double = 0.0
    
    var measure = UserDefaults.standard.measure
    var font_color = UserDefaults().string(forKey: "user_font_color") ?? ""
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    let client = DarkSkyClient(apiKey: "662e626026f320de24eda9df36ec7d01")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        //print("lat : ", location.coordinate.latitude)
        //print("long : ", location.coordinate.longitude)
        //print("alt : ", location.altitude)
        
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
        
        // Is this a suitable place to get these values again, rather than restarting the app ?
        measure = UserDefaults().string(forKey: "user_measure") ?? ""
        font_color = UserDefaults().string(forKey: "user_font_color") ?? ""
    }
    
    func getAddress(point location: CLLocation, completion: @escaping (_ address: String?) -> ()) {
        
        let ceo: CLGeocoder = CLGeocoder()
        //let loc: CLLocation = CLLocation(latitude:picLat, longitude: picLong)
        
        var address : String = String()
        ceo.reverseGeocodeLocation(location, completionHandler:
            {(placemarks, error) in
                if (error != nil)
                {
                    print("reverse geodcode fail: \(error!.localizedDescription)")
                }
                let pm = placemarks! as [CLPlacemark]
                
                if pm.count > 0 {
                    let pm = placemarks![0]
                    
                     print(pm.country)
                     print(pm.locality)
                     print(pm.subLocality)
                     print(pm.thoroughfare)
                     print(pm.postalCode)
                     print(pm.subThoroughfare)
 
                    
                    
                    if pm.subLocality != nil {
                        address = address + pm.subLocality! + ", "
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
                        address = address + pm.country! + ", "
                    }
                    if pm.postalCode != nil {
                        address = address + pm.postalCode! + " "
                    }
                    
                    //print(address)
                }
                completion(address)
                self.pAddress = address
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
        }
    }
    
    
    func updateForForecast(forecast: Forecast) {
        let currentTemp = forecast.currently?.temperature
        let intTemp = measure == "metric" ? getCelsius(forTemp: currentTemp!) : Int(currentTemp!)
        //print("temperature at location:", intTemp)
        let summary = (forecast.currently?.summary ?? "").lowercased()
        let coordinate0 = CLLocation(latitude: self.currentLatitude, longitude: self.currentLongitude)
        let coordinate1 = CLLocation(latitude: CLLocationDegrees(self.picLat), longitude: CLLocationDegrees(self.picLong))
        print("lat : ", self.picLat)
        print("long : ", self.picLong)
        self.getAddress(point: coordinate1) { (address:String?) in
            //print("address ", address ?? "")
            print(self.timeAtPlace(time: (forecast.currently?.time)!, timezone: forecast.timezone))
            let convertedTime = self.timeAtPlace(time: (forecast.currently?.time)!, timezone: forecast.timezone)
            DispatchQueue.main.async(execute: {

                self.setFontColor(color: self.font_color)
                self.tempLabel.text = "weather now  \(summary) \(intTemp)"
                self.distanceLabel.text = self.distanceBetween(point1: coordinate0, point2: coordinate1)
                self.timeLabel.text = "time \(convertedTime)"
                self.addressLabel.text = "address \n\(address!)"

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
        if let url = info["UIImagePickerControllerReferenceURL"] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
            if let asset = assets.firstObject, let location = asset.location, let creationDate = asset.creationDate {
                
                print("creationDate : ", creationDate)
                picLat = location.coordinate.latitude
                picLong = location.coordinate.longitude
                client.getForecast(latitude: picLat,
                                   longitude: picLong,
                                   completion: { (result:Result<Forecast>) in
                                    if let f = result.value.0 {
                                        self.updateForForecast(forecast: f)
                                    }
                })
            }
            //print("picLat :", picLat)
            //print("picLong :", picLong)
            
            picker.dismiss(animated: true, completion: nil)
            
            if (picLat == 0.0 && picLong == 0.0) {
                self.addressLabel.text = "This is not a standard iPhone photo image, details not available"
                self.tempLabel.text = ""
                self.distanceLabel.text = ""
                self.timeLabel.text = ""
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
        
        if (measure == "metric") {
            if (distanceInMeters < 1000) {
                print("meters: ", distanceInMeters)
                let intMDistance = Int(round(distanceInMeters))
                distanceString = "distance \(intMDistance) meters"
            } else {
                let intKmDistance = Int(round(distanceInMeters / 1000))
                distanceString = "distance \(intKmDistance) km"
            }
        } else {  // if not metric, assume imperial (miles/feet)
            if (distanceInMiles < 1) {
                let intFeetDistance = Int(round(distanceInMiles * 5280))
                distanceString = "distance \(intFeetDistance) feet"
            } else {
                let intMileDistance = Int(round(distanceInMiles))
                distanceString = "distance \(intMileDistance) miles"
            }
        }

        return distanceString
    }
    
    func timeAtPlace(time: Date, timezone: String) -> String {
        
        print(time)
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeZone = TimeZone(identifier: timezone)
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let convertedTime = dateFormatter.string(from: Date())
        
        //print("EXT convertedDate (time at \(timezone))", convertedTime)
        
        return convertedTime
    }
    
    func getCelsius(forTemp: Float) -> Int {
        
        var celsius : Float = 0
        
        celsius = (( forTemp - 32 ) * 5.0 ) / 9.0
        
        return Int(round(celsius))
    }
    
    // inquire in class if this is the best approach - it works, but seems like there should be a cleaner option
    // such as setting all text colors with the string value
    func setFontColor(color: String)  {
        
        if (self.font_color == "black") {
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


