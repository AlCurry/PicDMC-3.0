//
//  PhotoViewController.swift
//  PhotoDMW
//
//  Created by Al Curry on 11/15/17.
//  Copyright © 2017. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var picImage: UIImage!
    var picCreationDate : Date!
    var picDescription : String?
    
    var firstLabel = UILabel()
    var secondLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
        
        imageView.image = picImage
        
        addTopLabels()
        
        self.imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoViewController.imageTapped))
        self.imageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func imageTapped() {
        self.navigationController?.isNavigationBarHidden = !(self.navigationController?.isNavigationBarHidden)!
        UIApplication.shared.isStatusBarHidden = !UIApplication.shared.isStatusBarHidden
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        firstLabel.removeFromSuperview()
        secondLabel.removeFromSuperview()
        print("viewWillDisappear")
    }
    
    func addTopLabels() {
        firstLabel.removeFromSuperview()
        secondLabel.removeFromSuperview()
        
        /* Build and add labels to top bar */
        if let navigationBar = self.navigationController?.navigationBar {
            let firstFrame = CGRect(x: 0, y: 0, width: navigationBar.frame.width, height: navigationBar.frame.height/2)
            let secondFrame = CGRect(x: 0, y: navigationBar.frame.height/2, width: navigationBar.frame.width, height: navigationBar.frame.height/2)
            
            firstLabel = UILabel(frame: firstFrame)
            firstLabel.text = picDescription
            firstLabel.textAlignment = .center
            firstLabel.font = firstLabel.font.withSize(14)
            
            let dateFormatter = DateFormatter()
            
            // e.g. December 15 2017 2:16 PM 
            dateFormatter.dateFormat = "MMMM d yyyy h:mm a"
            var creationDateStr = ""
            if (picCreationDate != nil) {
               creationDateStr = dateFormatter.string(from: picCreationDate)
            }
            
            secondLabel = UILabel(frame: secondFrame)
            secondLabel.text = creationDateStr
            secondLabel.textAlignment = .center
            secondLabel.font = secondLabel.font.withSize(12)
            
            navigationBar.addSubview(firstLabel)
            navigationBar.addSubview(secondLabel)
            
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (context:UIViewControllerTransitionCoordinatorContext) in
            ()
        }, completion: { (context:UIViewControllerTransitionCoordinatorContext) in
            self.addTopLabels()
        })
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    

}
