//
//  AnnotationView.swift
//  ARLocation
//
//  Created by Rooban Abraham on 13/06/19.
//  Copyright © 2019 Rooban Abraham. All rights reserved.
// 


import UIKit

class AnnotationView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var offerImg: UIImageView!
    @IBOutlet weak var offerLbl: UILabel!
    @IBOutlet weak var offerDesc: UILabel!
    @IBOutlet weak var offerDistance: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
