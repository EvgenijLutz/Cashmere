//
//  PlatformViewController.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 14.03.25.
//

import CMPlatform


open class PlatformViewController: CMViewController {
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupLayout()
    }
    
    open func setupLayout() {
        // Override by superclasses
    }
}
