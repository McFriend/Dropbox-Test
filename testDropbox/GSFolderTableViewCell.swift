//
//  GSFileTableViewCell.swift
//  testDropbox
//
//  Created by George Sabanov on 15.07.2018.
//  Copyright © 2018 George Sabanov. All rights reserved.
//

import UIKit
import SwiftyDropbox
class GSFolderTableViewCell: UITableViewCell {
    var request: RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderErrorSerializer>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        request?.cancel()
        self.imageView?.image = nil
    }

}
