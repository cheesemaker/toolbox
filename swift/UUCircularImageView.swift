//
//  UUCircularImageView
//  Useful Utilities - UIImageView subclass that maintains circular clipping
//
//  Created by Ryan DeVore on 05/23/2017
//
//	License:
//  You are free to use this code for whatever purposes you desire.
//  The only requirement is that you smile everytime you use it.
//
//  Contact: @ryandevore or ryan@silverpine.com
//

import UIKit

class UUCircularImageView: UIImageView
{
    override func layoutSubviews()
    {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.width / 2
    }
}
