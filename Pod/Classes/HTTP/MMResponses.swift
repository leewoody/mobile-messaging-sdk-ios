//
//  MMResponses.swift
//  MobileMessaging
//
//  Created by Andrey K. on 23/02/16.
//  
//

import SwiftyJSON

typealias MMRegistrationResult = Result<MMHTTPRegistrationResponse>
typealias MMFetchMessagesResult = Result<MMHTTPSyncMessagesResponse>
typealias MMSeenMessagesResult = Result<MMHTTPSeenMessagesResponse>
typealias MMUserDataSyncResult = Result<MMHTTPUserDataSyncResponse>
typealias MMSystemDataSyncResult = Result<MMHTTPSystemDataSyncResponse>
typealias MMMOMessageResult = Result<MMHTTPMOMessageResponse>
typealias MMLibraryVersionResult = Result<MMHTTPLibraryVersionResponse>
typealias MMGeoEventReportingResult = Result<MMHTTPGeoEventReportingResponse>

public protocol JSONDecodable {
	init?(json: JSON)
}
public protocol JSONEncodable {
	func toJSON() -> JSON
}

extension Date: JSONEncodable {
	public func toJSON() -> JSON {
		return JSON(DateStaticFormatters.ContactsServiceDateFormatter.string(from: self))
	}
}

public struct MMRequestError {
	public var isUNAUTHORIZED: Bool {
		return messageId == "UNAUTHORIZED"
	}
	
	public let messageId: String
	
	public let text: String
	
	var foundationError: NSError {
		var userInfo = [AnyHashable: Any]()
		userInfo[NSLocalizedDescriptionKey] = text
		userInfo[MMAPIKeys.kErrorText] = text
		userInfo[MMAPIKeys.kErrorMessageId] = messageId
		return NSError(domain: MMAPIKeys.kBackendErrorDomain, code: Int(messageId) ?? 0, userInfo: userInfo)
	}
}

extension MMRequestError: JSONDecodable {
	public init?(json value: JSON) {
		let serviceException = value[MMAPIKeys.kRequestError][MMAPIKeys.kServiceException]
		guard
			let text = serviceException[MMAPIKeys.kErrorText].string,
			let messageId = serviceException[MMAPIKeys.kErrorMessageId].string
		else {
			return nil
		}
		
		self.messageId = messageId
		self.text = text
	}
}

class MMHTTPResponse: JSONDecodable {
	required init?(json value: JSON) {
	}
}

//MARK: API Responses
final class MMHTTPRegistrationResponse: MMHTTPResponse {
    let internalUserId: String

	required init?(json value: JSON) {
		if let internalUserId = value[MMAPIKeys.kInternalRegistrationId].string {
			self.internalUserId = internalUserId
		} else {
			return nil
		}
		super.init(json: value)
	}
}

class MMHTTPEmptyResponse: MMHTTPResponse {
}

final class MMHTTPUserDataUpdateResponse: MMHTTPEmptyResponse { }
final class MMHTTPSeenMessagesResponse: MMHTTPEmptyResponse { }

final class MMHTTPGeoEventReportingResponse: MMHTTPResponse {
	let finishedCampaignIds: [String]?
	let suspendedCampaignIds: [String]?

	required init?(json value: JSON) {
		self.finishedCampaignIds = value[GeoReportingAPIKeys.finishedCampaignIds].arrayObject as? [String]
		self.suspendedCampaignIds = value[GeoReportingAPIKeys.suspendedCampaignIds].arrayObject as? [String]
		super.init(json: value)
	}
}

final class MMHTTPLibraryVersionResponse: MMHTTPResponse {

	let platformType : String
	let libraryVersion : String
	let updateUrl : String
	
	required init?(json value: JSON) {
		
		guard let platformType = value[MMAPIKeys.kLibraryVersionPlatformType].rawString(),
			let libraryVersion = value[MMAPIKeys.kLibraryVersionLibraryVersion].rawString(),
			let updateUrl = value[MMAPIKeys.kLibraryVersionUpdateUrl].rawString() else {
				return nil
		}
		
		self.platformType = platformType
		self.libraryVersion = libraryVersion
		self.updateUrl = updateUrl
		
		super.init(json: value)
	}
}

final class MMHTTPSyncMessagesResponse: MMHTTPResponse {
    let messages: [MTMessage]?
	required init?(json value: JSON) {
		self.messages = value[APNSPayloadKeys.kPayloads].arrayValue.flatMap { MMMessageFactory.makeMessage(with: $0) }
		super.init(json: value)
	}
}

final class MMHTTPSystemDataSyncResponse: MMHTTPEmptyResponse { }

final class MMHTTPUserDataSyncResponse: MMHTTPResponse {
	typealias ErrorMessage = String
	typealias AttributeName = String
	typealias ValueType = Any
	
	let predefinedData: [AttributeName: ValueType]?
	let customData: [CustomUserData]?
	let error: MMRequestError?
	
	required init?(json value: JSON) {
		self.predefinedData = value[MMAPIKeys.kUserDataPredefinedUserData].dictionaryObject
		self.customData = value[MMAPIKeys.kUserDataCustomUserData].dictionaryObject?.reduce([CustomUserData](), { (result, pair) -> [CustomUserData] in
			if let element = CustomUserData(dictRepresentation: [pair.0: pair.1]) {
				return result + [element]
			} else {
				return result
			}
		})
		
		self.error = MMRequestError(json: value)
		super.init(json: value)
	}
}
final class MMHTTPMOMessageResponse: MMHTTPResponse {
	let messages: [MOMessage]
	
	required init?(json value: JSON) {
		self.messages = value[MMAPIKeys.kMOMessages].arrayValue.flatMap(MOMessage.init)
		super.init(json: value)
	}
}


//MARK: Other
func ==(lhs: MTMessage, rhs: MTMessage) -> Bool {
	return lhs.messageId == rhs.messageId
}

protocol MMMessageMetadata: Hashable {
	var isSilent: Bool {get}
	var messageId: String {get}
}
