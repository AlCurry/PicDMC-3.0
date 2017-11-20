//
//  PhotoViewController.swift
//  PhotoDMW
//
//  Created by Al Curry on 11/15/17.
//  Copyright © 2017. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController  {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var picImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = picImage

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
