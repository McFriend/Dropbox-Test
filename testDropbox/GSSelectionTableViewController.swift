//
//  GSSelectionTableViewController.swift
//  testDropbox
//
//  Created by George Sabanov on 14.07.2018.
//  Copyright © 2018 George Sabanov. All rights reserved.
//

import UIKit
import SwiftyDropbox

class GSSelectionTableViewController: UITableViewController {
    var folderPath = ""
    var cursor : String?
    var files = Array<Files.Metadata>()
    var prompt = ""
    var hasMore = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadFiles()
        self.configureNavigationItems()        
        self.setHeader()
        self.setRefreshControl()
    }
    
    func setRefreshControl()
    {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: 
            #selector(handleRefresh(sender:)), 
                                 for: UIControlEvents.valueChanged)
        self.refreshControl = refreshControl  
    }
    
    func setHeader()
    {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 44))
        header.clipsToBounds = true
        let button = UIButton(frame: header.bounds)
        button.setTitle(NSLocalizedString("LogOut", comment: ""), for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        button.addTarget(self, action: #selector(logOut(_:)), for: .touchUpInside)
        header.addSubview(button)
        self.tableView.tableHeaderView = header
        self.tableView.alwaysBounceVertical = true
        self.tableView.contentInset = UIEdgeInsetsMake(-44, 0, 0, 0)
    }
    
    @objc func handleRefresh(sender: UIRefreshControl)
    {
        sender.beginRefreshing()
        self.reloadFiles()
    }
    
    func configureNavigationItems()
    {
        if(self == self.navigationController?.viewControllers.first)
        {
            let closeItem = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: .done, target: self, action: #selector(close))
            self.navigationItem.leftBarButtonItem = closeItem
        }
        if(prompt.isEmpty)
        {
            AuthManager.authorizedClient?.users.getCurrentAccount().response(completionHandler: { (account, error) in
                DispatchQueue.main.async {
                    if(account != nil)
                    {
                        self.prompt = account?.email ?? ""
                        self.navigationItem.prompt = self.prompt
                    }
                }
            })
        }
        else
        {
            self.navigationItem.prompt = self.prompt
        }
    }
    
    func loadFiles()
    {
        if(self.cursor == nil)
        {
            reloadFiles()
        }
        else
        {
            loadMoreFiles()
        }
    }
    func reloadFiles()
    {
        AuthManager.authorizedClient?.files.listFolder(path: folderPath, recursive: false, includeMediaInfo: true, includeDeleted: false, includeHasExplicitSharedMembers: false, includeMountedFolders: false, limit: nil, sharedLink: nil, includePropertyGroups: nil).response(completionHandler: { (result, error) in
            if(error == nil)
            {
                self.refreshControl?.endRefreshing()
                self.parseDropboxResponse(result: result, reload: true)
            }
            else
            {
                self.showErrorAlert(message: error!.description)
            }
        })
    }
    func loadMoreFiles()
    {
        AuthManager.authorizedClient?.files.listFolderContinue(cursor: self.cursor ?? "").response(completionHandler: { (result, error) in
            if(error == nil)
            {
                self.parseDropboxResponse(result: result, reload: false)

            }
            else
            {
                self.showErrorAlert(message: error!.description)
            }
        })
    }
    
    func parseDropboxResponse(result: Files.ListFolderResult?, reload: Bool)
    {
        DispatchQueue.main.async {
            self.cursor = result?.cursor
            self.hasMore = result?.hasMore ?? false
            if(self.hasMore)
            {
                self.loadMoreFiles()
            }
            if let entries = result?.entries
            {
                if(reload)
                {
                    self.files = entries
                }
                else
                {
                    self.files.append(contentsOf: entries)
                }
            }
            self.toggleEmptyFolderLabel()
            self.files.sort(by: { (f1, f2) -> Bool in
                return f1 is Files.FolderMetadata
            })
            self.tableView.reloadData()
        }
    }
        
    func toggleEmptyFolderLabel()
    {
        if(files.count == 0)
        {
            guard self.tableView.viewWithTag(109) == nil else { return }
            self.tableView.separatorStyle = .none
            self.tableView.addSubview(self.getBackgroundView())
        }
        else
        {
            self.tableView.separatorStyle = .singleLine
            self.tableView.viewWithTag(109)?.removeFromSuperview()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func close()
    {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int 
    {
        return files.count
    }

    func getBackgroundView() -> UIView
    {
        let bgView = UIView(frame: self.tableView.bounds)
        let label = UILabel(frame: CGRect(x: 0, y: 140, width: self.tableView.frame.size.width, height: 60))
        label.textAlignment = .center
        label.text = NSLocalizedString("Folder is empty", comment: "")
        label.font = UIFont.systemFont(ofSize: 17, weight: .light)
        label.textColor = UIColor.darkGray
        bgView.addSubview(label)
        bgView.tag = 109
        return bgView
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let file = files[indexPath.row]
        if let fileData = file as? Files.FileMetadata
        {      
            let cell = tableView.dequeueReusableCell(withIdentifier: "File", for: indexPath) as! GSFileTableViewCell
            cell.textLabel?.text = file.name
            let sizeString = ByteCountFormatter.string(fromByteCount: Int64(fileData.size), countStyle: .file)
            cell.detailTextLabel?.text = "\(sizeString) - \(DateToString.process(date: fileData.clientModified))"
            cell.imageView?.image = #imageLiteral(resourceName: "file")
            cell.imageView?.contentMode = .scaleAspectFit
            cell.accessoryType = .none
            cell.request = AuthManager.authorizedClient?.files.getThumbnail(path: file.pathLower!).response(completionHandler: { (response, error) in
                DispatchQueue.main.async {
                    if(response != nil)
                    {
                        cell.imageView?.image = UIImage(data: response!.1)
                    }
                }
            })
            return cell
        }
        else if file is Files.FolderMetadata
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Folder", for: indexPath) as! GSFolderTableViewCell
            cell.textLabel?.text = file.name
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.image = #imageLiteral(resourceName: "folder")
            cell.imageView?.contentMode = .scaleAspectFit
            cell.detailTextLabel?.text = "-"
            cell.request = AuthManager.authorizedClient?.files.listFolder(path: file.pathLower!).response(completionHandler: { (response, error) in
                DispatchQueue.main.async {
                    if(response != nil)
                    {
                        let filesCountString = "\(response!.entries.count) \(NSLocalizedString("files", comment: ""))"
                        cell.detailTextLabel?.text = filesCountString
                    }
                }
            })
            return cell
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let file = files[indexPath.row]
        if let fileData = file as? Files.FileMetadata
        {
            var dataDict = [String : Any]()
            dataDict["name"] = fileData.name
            dataDict["clientModified"] = fileData.clientModified.timeIntervalSince1970
            dataDict["size"] = fileData.size
            dataDict["url"] = fileData.pathLower
            UserDefaults.standard.set(dataDict, forKey: "lastSelectedItem")
            self.close()
        }
        else if let folderData = file as? Files.FolderMetadata
        {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "selectionScreen") as! GSSelectionTableViewController
            vc.folderPath = folderData.pathLower ?? ""
            vc.prompt = self.prompt
            vc.title = folderData.name
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func logOut(_ sender: Any) 
    {
        let alertVC = UIAlertController(title: NSLocalizedString("LogOutTitle", comment: ""), message: NSLocalizedString("LogOutDesc", comment: "") + "\n\(self.prompt)?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        let logOut = UIAlertAction(title: NSLocalizedString("LogOut", comment: ""), style: .destructive) { (action) in
            DropboxClientsManager.unlinkClients()
            UserDefaults.standard.removeObject(forKey: "lastSelectedItem")
            self.close()
        }
        alertVC.addAction(cancel)
        alertVC.addAction(logOut)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        guard scrollView.contentOffset.y > -220 else { return } //Проверка что пользователь не обновляет страницу
        if(scrollView.contentOffset.y < -98)
        {
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0) //Когда пользователь тянет экран вниз и кнопка лог аута полностью видна, она разблокируется.
        }
        else if (scrollView.contentOffset.y < -54)
        {
            self.tableView.setContentOffset(CGPoint(x: 0, y: -54), animated: true) //Когда пользователь хочет скрыть кнопка лог аута и тянет экран вверх, таблица скроллится в нормальное положение и блокирует кнопку логаут сверху.
        }
    }
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        if(scrollView.contentOffset.y == -54)
        {
            self.tableView.contentInset = UIEdgeInsetsMake(-44, 0, 0, 0) //Блокировка кнопки лог аута сверху.
        }
    }
}
