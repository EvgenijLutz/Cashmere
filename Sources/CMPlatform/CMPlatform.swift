//
//  CMPlatform.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 03.03.25.
//

#if os(macOS)

@_exported import AppKit

public typealias CMView = NSView
public typealias CMViewController = NSViewController
public typealias PlatformScrollView = NSScrollView
public typealias PlatformStackView = NSStackView
public typealias PlatformTextField = NSTextField
public typealias PlatformTextFieldDelegate = NSTextFieldDelegate
public typealias PlatformTextView = NSTextView
public typealias PlatformTextViewDelegate = NSTextViewDelegate
public typealias PlatformTableCellView = NSTableCellView
public typealias PlatformOutlineView = NSOutlineView
public typealias PlatformRect = NSRect
public typealias PlatformSize = NSSize
public typealias PlatformPoint = CGPoint
public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont

#elseif os(iOS)

@_exported import UIKit

public typealias CMView = UIView
public typealias CMViewController = UIViewController
public typealias PlatformScrollView = UIScrollView
public typealias PlatformStackView = UIStackView
public typealias PlatformTextField = UITextField
public typealias PlatformTextFieldDelegate = UITextFieldDelegate
public typealias PlatformTextView = UITextView
public typealias PlatformTextViewDelegate = UITextViewDelegate
public typealias PlatformTableCellView = UITableViewCell
public typealias PlatformOutlineView = UITableView
public typealias PlatformRect = CGRect
public typealias PlatformSize = CGSize
public typealias PlatformPoint = CGPoint
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont

#endif
