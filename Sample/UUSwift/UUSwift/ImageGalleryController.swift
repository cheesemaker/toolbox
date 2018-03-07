//
//  ImageGalleryController.swift
//  UUSwift
//
//  Created by Ryan DeVore on 8/29/17.
//  Copyright © 2017 Useful Utilities. All rights reserved.
//

import UIKit
import UUToolbox

class ImageGalleryController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    private var tableData : [String] = []
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        title = "Image Gallery"
        
        UUDataCache.shared.clearCache()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePhotoDownloaded), name: UURemoteData.Notifications.DataDownloaded, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        let url = "https://api.shutterstock.com/v2/images/search"
        
        var args : [String:String] = [:]
        args["page"] = "1"
        args["per_page"] = "500"
        args["query"] = "forest"
        
        let req = UUHttpRequest.getRequest(url, args)
        
        let username = "d4a89-1400b-04251-4faee-f7a23-12271:61764-d9c3c-8a832-a7bdf-098e4-0b382"
        let usernameData = username.data(using: .utf8)
        let usernameEncoded = usernameData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
        req.headerFields["Authorization"] = "Basic \(usernameEncoded)"
        
        _ = UUHttpSession.executeRequest(req)
        { (response: UUHttpResponse) in
        
            if (response.httpError == nil)
            {
                self.tableData.removeAll()
                
                let parsed = response.parsedResponse as? [AnyHashable:Any]
                if (parsed != nil)
                {
                    let data = parsed!["data"] as? [ [AnyHashable:Any] ]
                    if (data != nil)
                    {
                        for item in data!
                        {
                            let assets = item["assets"] as? [AnyHashable:Any]
                            if (assets != nil)
                            {
                                let largeThumb = assets!["large_thumb"] as? [AnyHashable:Any]
                                if (largeThumb != nil)
                                {
                                    let value = largeThumb!["url"] as? String
                                    if (value != nil)
                                    {
                                        self.tableData.append(value!)
                                    }
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async
                    {
                        self.collectionView.reloadData()
                    }
                }
            }
            else
            {
                self.tableData.removeAll()
                
                DispatchQueue.main.async
                {
                    self.collectionView.reloadData()
                }
            }
        }
    }

    @objc public func handlePhotoDownloaded(notification: Notification)
    {
        let remotePath = notification.uuRemoteDataPath
        UUDebugLog("Image downloaded: %@", String(describing: remotePath))
        
        if (remotePath != nil)
        {
            let md = UURemoteData.shared.metaData(for: remotePath!)
            print("AFTER - Meta Data for \(remotePath!): \(md)")
            
            let index = tableData.index(of: remotePath!)
            if (index != nil)
            {
                UUDebugLog("Reloading row %@", String(describing: index))
                collectionView.reloadItems(at: [ IndexPath(row: index!, section: 0) ])
            }
        }
    }
    
    public func handlePhotoDownloadFailure(notification: Notification)
    {
        let remotePath = notification.uuRemoteDataPath
        let err = notification.uuRemoteDataError
        UUDebugLog("Image download failed: %@, err: %@", String(describing: remotePath), String(describing: err))
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return tableData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let path = tableData[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let md = UURemoteData.shared.metaData(for: path)
        print("BEFORE - Meta Data for \(path): \(md)")
        
        let img = UURemoteImage.shared.image(for: path)
        cell.photo.image = img
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let w = collectionView.bounds.size.width / 2
        return CGSize(width: w, height: w)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let path = tableData[indexPath.row]
        
        let md = UURemoteData.shared.metaData(for: path)
        print("Meta Data for \(path): \(md)")
    }
}

class PhotoCell : UICollectionViewCell
{
    
    @IBOutlet var photo: UIImageView!
}
