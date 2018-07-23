//
//  GSAuthViewController.swift
//  testDropbox
//
//  Created by George Sabanov on 14.07.2018.
//  Copyright © 2018 George Sabanov. All rights reserved.
//

import UIKit

class GSAuthViewController: UIViewController {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var selectButton: UIButton!
    var lastSelectedItem : [String: Any]?
    {
        get
        {
            return UserDefaults.standard.value(forKey: "lastSelectedItem") as? [String : Any]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadContent()
    }
    
    func reloadContent()
    {
        if(lastSelectedItem != nil)
        {
            AuthManager.authorizedClient?.files.getTemporaryLink(path: lastSelectedItem!["url"] as! String).response(completionHandler: { (response, error) in
                DispatchQueue.main.async {
                    if(response != nil)
                    {
                        var descriptionText = ""
                        descriptionText += NSLocalizedString("Title", comment: "") + ": " + (self.lastSelectedItem!["name"] as! String) + "\n"
                        let size = self.lastSelectedItem!["size"] as! UInt64
                        let sizeString = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
                        descriptionText += NSLocalizedString("Size", comment: "") + ": " + sizeString + "\n"
                        let lastModified = self.lastSelectedItem!["clientModified"] as! TimeInterval
                        let lastModDate = Date(timeIntervalSince1970: lastModified)
                        descriptionText += NSLocalizedString("Last modified", comment: "") + ": " + DateToString.process(date: lastModDate) + "\n"
                        descriptionText += NSLocalizedString("URL", comment: "") + ": " + response!.link
                        self.descriptionLabel.text = descriptionText
                    }
                }
            })
            
            AuthManager.authorizedClient?.files.getThumbnail(path: lastSelectedItem!["url"] as! String, format: .jpeg, size: .w640h480, mode: .strict).response(completionHandler: { (response, error) in
                DispatchQueue.main.async {
                    if(response != nil)
                    {
                        self.previewImageView.image = UIImage(data: response!.1)
                    }
                    else
                    {
                        self.previewImageView.image = #imageLiteral(resourceName: "file")
                    }
                }
            })
        }
        else
        {
            self.descriptionLabel.text = NSLocalizedString("You haven't selected any file from your dropbox storage yet.", comment: "")
            self.previewImageView.image = nil
        }
    }
    
    @IBAction func selectNewFile(sender: UIButton?)
    {
        checkAuth(success: { 
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "selectionScreen")
            let nav = UINavigationController(rootViewController: vc)
            self.present(nav, animated: true, completion: nil)
        }) { 
            self.showErrorAlert(message: NSLocalizedString("Failed to authorize", comment: ""))
        }
        
    }
    
    func checkAuth(success: @escaping () -> (), failure: @escaping () -> ())
    {
        if(AuthManager.authorizedClient != nil)
        {
            success()
        }
        else
        {
            AuthManager.authorise(controller: self) { (succeeded) in
                DispatchQueue.main.async {
                    if(succeeded) { success() } else { failure() }
                }
            }
        }
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
