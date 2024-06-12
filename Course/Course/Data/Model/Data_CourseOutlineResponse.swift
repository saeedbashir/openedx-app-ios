//
//  CourseOutlineResponse.swift
//  CourseOutline
//
//  Created by  Stepanok Ivan on 28.09.2022.
//

import Foundation
import CoreData
import Core

public extension DataLayer {
    
    typealias Blocks = [String: CourseBlock]
    
    struct CourseStructure: Decodable {
        public let rootItem: String
        public var dict: Blocks
        public let id: String
        public let media: DataLayer.CourseMedia
        public let certificate: Certificate?
        public let org: String?
        public let isSelfPaced: Bool
        public let courseModes: [CourseMode]?
        public let enrollmentDetails: EnrollmentDetail?
        public let courseStart: String?
        public var courseSKU: String?
        public var courseMode: Mode?
        public let coursewareAccessDetails: CoursewareAccessDetails?
        public let courseProgress: CourseProgress?
        
        enum CodingKeys: String, CodingKey {
            case blocks
            case rootItem = "root"
            case id
            case media
            case certificate
            case org
            case isSelfPaced = "is_self_paced"
            case enrollmentDetails = "enrollment_details"
            case courseStart = "start"
            case courseModes = "course_modes"
            case coursewareAccessDetails = "course_access_details"
            case courseProgress = "course_progress"
        }
        
        public init(
            rootItem: String,
            dict: Blocks,
            id: String,
            media: DataLayer.CourseMedia,
            certificate: Certificate?,
            org: String?,
            isSelfPaced: Bool,
            courseModes: [CourseMode]? = nil,
            enrollmentDetails: EnrollmentDetail? = nil,
            courseStart: String? = nil,
            courseSKU: String? = nil,
            courseMode: Mode? = .unknown,
            coursewareAccessDetails: CoursewareAccessDetails? = nil,
            courseProgress: CourseProgress?
        ) {
            self.rootItem = rootItem
            self.dict = dict
            self.id = id
            self.media = media
            self.certificate = certificate
            self.org = org
            self.isSelfPaced = isSelfPaced
            self.courseModes = courseModes
            self.enrollmentDetails = enrollmentDetails
            self.courseStart = courseStart
            self.coursewareAccessDetails = coursewareAccessDetails
            
            if enrollmentDetails?.mode != nil {
                self.courseMode = enrollmentDetails?.mode
            }
            self.courseProgress = courseProgress
            
            populateCourseSKU()
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            dict = try values.decode(Blocks.self, forKey: .blocks)
            rootItem = try values.decode(String.self, forKey: .rootItem)
            id = try values.decode(String.self, forKey: .id)
            media = try values.decode(DataLayer.CourseMedia.self, forKey: .media)
            certificate = try values.decode(Certificate.self, forKey: .certificate)
            org = try values.decode(String.self, forKey: .org)
            isSelfPaced = try values.decode(Bool.self, forKey: .isSelfPaced)
            courseModes = try values.decode([CourseMode].self, forKey: .courseModes)
            enrollmentDetails = try values.decode(EnrollmentDetail.self, forKey: .enrollmentDetails)
            courseStart = try values.decode(String.self, forKey: .courseStart)
            coursewareAccessDetails = try values.decode(CoursewareAccessDetails.self, forKey: .coursewareAccessDetails)
            courseProgress = try? values.decode(DataLayer.CourseProgress.self, forKey: .courseProgress)
            populateCourseSKU()
        }
        
        mutating func populateCourseSKU() {
            for mode in courseModes ?? [] where mode.slug == .verified {
                courseSKU = mode.iosSku ?? ""
            }
        }
    }
    
    struct CoursewareAccessDetails: Codable {
        public let hasUNMETPrerequisites: Bool
        public let isTooEarly: Bool
        public let auditAccessExpires: String?
        public let coursewareAccess: CoursewareAccess?
        
        public init(
            hasUNMETPrerequisites: Bool,
            isTooEarly: Bool,
            auditAccessExpires: String?,
            coursewareAccess: CoursewareAccess?
        ) {
            self.hasUNMETPrerequisites = hasUNMETPrerequisites
            self.isTooEarly = isTooEarly
            self.auditAccessExpires = auditAccessExpires
            self.coursewareAccess = coursewareAccess
        }
        
        public enum CodingKeys: String, CodingKey {
            case hasUNMETPrerequisites = "has_unmet_prerequisites"
            case isTooEarly = "is_too_early"
            case auditAccessExpires = "audit_access_expires"
            case coursewareAccess = "courseware_access"
        }
    }
}
public extension DataLayer {
    struct CourseBlock: Decodable {
        public let blockId: String
        public let id: String
        public let graded: Bool
        public let due: String?
        public let completion: Double?
        public let studentUrl: String
        public let webUrl: String
        public let type: String
        public let displayName: String
        public let descendants: [String]?
        public let allSources: [String]?
        public let userViewData: CourseDetailUserViewData?
        public let multiDevice: Bool?
        public let assignmentProgress: AssignmentProgress?
        
        public init(
            blockId: String,
            id: String,
            graded: Bool,
            due: String?,
            completion: Double?,
            studentUrl: String,
            webUrl: String,
            type: String,
            displayName: String,
            descendants: [String]?,
            allSources: [String]?,
            userViewData: CourseDetailUserViewData?,
            multiDevice: Bool?,
            assignmentProgress: AssignmentProgress?
        ) {
            self.blockId = blockId
            self.id = id
            self.graded = graded
            self.due = due
            self.completion = completion
            self.studentUrl = studentUrl
            self.webUrl = webUrl
            self.type = type
            self.displayName = displayName
            self.descendants = descendants
            self.allSources = allSources
            self.userViewData = userViewData
            self.multiDevice = multiDevice
            self.assignmentProgress = assignmentProgress
        }
        
        public enum CodingKeys: String, CodingKey {
            case id, type, descendants, graded, completion, due
            case blockId = "block_id"
            case studentUrl = "student_view_url"
            case webUrl = "lms_web_url"
            case displayName = "display_name"
            case userViewData = "student_view_data"
            case allSources = "all_sources"
            case multiDevice = "student_view_multi_device"
            case assignmentProgress = "assignment_progress"
        }
    }
    
    struct AssignmentProgress: Codable {
        public let assignmentType: String?
        public let numPointsEarned: Double?
        public let numPointsPossible: Double?

        public enum CodingKeys: String, CodingKey {
            case assignmentType = "assignment_type"
            case numPointsEarned = "num_points_earned"
            case numPointsPossible = "num_points_possible"
        }
        
        public init(assignmentType: String?, numPointsEarned: Double?, numPointsPossible: Double?) {
            self.assignmentType = assignmentType
            self.numPointsEarned = numPointsEarned
            self.numPointsPossible = numPointsPossible
        }
    }

    struct Transcripts: Codable {
        public let en: String?

        enum CodingKeys: String, CodingKey {
            case en
        }

        public init(en: String?) {
            self.en = en
        }
    }
    
    struct EnrollmentDetail: Codable {
        let created: String
        let isActive: Bool
        let mode: Mode
        let upgradeDeadline: String?
        
        public enum CodingKeys: String, CodingKey {
            case created
            case isActive = "is_active"
            case mode
            case upgradeDeadline = "upgrade_deadline"
        }
        
        init(created: String, isActive: Bool, mode: Mode, upgradeDeadline: String?) {
            self.created = created
            self.isActive = isActive
            self.mode = mode
            self.upgradeDeadline = upgradeDeadline
        }
    }
    
    struct CourseDetailUserViewData: Decodable {
        public let transcripts: [String: String]?
        public let encodedVideo: CourseDetailEncodedVideoData?
        public let topicID: String?
        
        public init(
            transcripts: [String: String]?,
            encodedVideo: CourseDetailEncodedVideoData?,
            topicID: String?
        ) {
            self.transcripts = transcripts
            self.encodedVideo = encodedVideo
            self.topicID = topicID
        }
        
        public enum CodingKeys: String, CodingKey {
            case encodedVideo = "encoded_videos"
            case topicID = "topic_id"
            case transcripts
        }
    }
    
    struct CourseDetailEncodedVideoData: Decodable {
        public let youTube: EncodedVideoData?
        public let fallback: EncodedVideoData?
        public let desktopMP4: EncodedVideoData?
        public let mobileHigh: EncodedVideoData?
        public let mobileLow: EncodedVideoData?
        public let hls: EncodedVideoData?

        public init(
            youTube: EncodedVideoData?,
            fallback: EncodedVideoData?,
            desktopMP4: EncodedVideoData? = nil,
            mobileHigh: EncodedVideoData? = nil,
            mobileLow: EncodedVideoData? = nil,
            hls: EncodedVideoData? = nil
        ) {
            self.youTube = youTube
            self.fallback = fallback
            self.desktopMP4 = desktopMP4
            self.mobileHigh = mobileHigh
            self.mobileLow = mobileLow
            self.hls = hls
        }
        
        enum CodingKeys: String, CodingKey {
            case youTube = "youtube"
            case fallback
            case desktopMP4 = "desktop_mp4"
            case mobileHigh = "mobile_high"
            case mobileLow = "mobile_low"
            case hls
        }
    }
    
    struct EncodedVideoData: Decodable {
        public let url: String?
        public let fileSize: Int?
        public let streamPriority: Int?

        public init(url: String?, fileSize: Int?, streamPriority: Int? = nil) {
            self.url = url
            self.fileSize = fileSize
            self.streamPriority = streamPriority
        }

        enum CodingKeys: String, CodingKey {
            case url
            case fileSize = "file_size"
            case streamPriority = "stream_priority"
        }
    }
}

extension DataLayer.CourseStructure {
    var isUpgradeable: Bool {
        guard let start = courseStart,
              let upgradeDeadline = enrollmentDetails?.upgradeDeadline,
              enrollmentDetails?.mode == .audit
        else { return false }
        
        let startDate = Date(iso8601: start)
        let dynamicUpgradeDeadline = Date(iso8601: upgradeDeadline)
        
        return startDate.isInPast()
        && courseSKU?.isEmpty == false
        && !dynamicUpgradeDeadline.isInPast()
    }
}
