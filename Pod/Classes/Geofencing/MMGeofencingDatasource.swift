//
//  MMGeofencingDatasource.swift
//
//  Created by Ivan Cigic on 06/07/16.
//
//

import Foundation
import CoreLocation

//FIXME: thread safety
class MMGeofencingDatasource {
	
	static let plistDir = "com.mobile-messaging.geo-data"
	static let plistFile = "CampaignsData.plist"
	static let sharedInstance = MMGeofencingDatasource()
	var campaigns = Set<MMCampaign>()
	var regions: Set<MMRegion> {
		return campaigns.reduce(Set<MMRegion>()) { (accumulator, campaign) -> Set<MMRegion> in
			return accumulator.union(campaign.regions)
		}
	}
	var numberOfCampaigns: Int {
		return campaigns.count
	}
	
	init() {
		load()
	}
	
	func campaingWithId(id: String) -> MMCampaign? {
		return campaigns.filter({ $0.id == id }).first
	}
	
	func addNewCampaign(newCampaign: MMCampaign) {
		campaigns.insert(newCampaign)
		save()
	}
	
	func removeCampaign(campaingToRemove: MMCampaign) {
		campaigns.remove(campaingToRemove)
		save()
	}
	
	lazy var rootURL: NSURL = {
		return NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)[0]
	}()
	
	lazy var fileDirectoryURL: NSURL = {
		return self.rootURL.URLByAppendingPathComponent(MMGeofencingDatasource.plistDir)
	}()
	
	lazy var plistURL: NSURL = {
		self.fileDirectoryURL.URLByAppendingPathComponent(MMGeofencingDatasource.plistFile)
	}()
	
	func save() {
		//FIXME: move to BG thread
		if let path = fileDirectoryURL.path where !NSFileManager.defaultManager().fileExistsAtPath(path) {
			do {
				try NSFileManager.defaultManager().createDirectoryAtURL(fileDirectoryURL, withIntermediateDirectories: true, attributes: nil)
			} catch {
				MMLogError("Can't create a directory for a plist.")
				return
			}
		}
		
		
		let campaignDicts = campaigns.map { $0.dictionaryRepresentation }
		
		do {
			let data = try NSPropertyListSerialization.dataWithPropertyList(campaignDicts, format: NSPropertyListFormat.XMLFormat_v1_0, options: 0)
			try data.writeToURL(plistURL, options: NSDataWritingOptions.AtomicWrite)
		} catch {
			MMLogError("Can't write to a plist.")
		}
	}
	
	func load() {
		//FIXME: move to BG thread
		guard let plistPath = plistURL.path,
			let data = NSFileManager.defaultManager().contentsAtPath(plistPath),
			let plistArray = try? NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListMutabilityOptions.MutableContainersAndLeaves, format: nil),
			let plistDicts = plistArray as? [[String: AnyObject]] else
		{
			MMLogError("Can't load campaigns from plist.")
			self.campaigns = []
			return
		}
		
		self.campaigns = Set(plistDicts.flatMap(MMCampaign.init))
	}
}

