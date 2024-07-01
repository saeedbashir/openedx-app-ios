//
//  CourseAccessMessageView.swift
//  Core
//
//  Created by Saeed Bashir on 6/28/24.
//

import Foundation
import SwiftUI
import Theme

public struct CourseAccessMessageView: View {
    public let startDate: Date?
    public let endDate: Date?
    public let auditAccessExpires: Date?
    public let startDisplay: Date?
    public let startType: DisplayStartType?
    public let font: Font
    public let textColor: Color
    public let dateStyle: DateStringStyle
    
    public init(
        startDate: Date?,
        endDate: Date?,
        auditAccessExpires: Date?,
        startDisplay: Date?,
        startType: DisplayStartType?,
        font: Font = Theme.Fonts.labelMedium,
        textColor: Color = Theme.Colors.textSecondaryLight,
        dateStyle: DateStringStyle = .startDDMonthYear
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.auditAccessExpires = auditAccessExpires
        self.startDisplay = startDisplay
        self.startType = startType
        self.font = font
        self.textColor = textColor
        self.dateStyle = dateStyle
    }
    
    public var body: some View {
        Text(nextRelevantDate ?? "")
            .font(font)
            .foregroundStyle(textColor)
    }
    
    private var nextRelevantDate: String? {
        if startDate?.isInPast() ?? false {
            if auditAccessExpires != nil {
                return formattedAuditExpires
            }
            
            guard let endDate = endDate else {
                return nil
            }
            
            let formattedEndDate = endDate.stringValue(style: dateStyle)
            
            return endDate.isInPast() ? CoreLocalization.Course.ended(formattedEndDate) :
            CoreLocalization.Course.ending(formattedEndDate)
        } else {
            let formattedStartDate = startDate?.stringValue(style: dateStyle) ?? ""
            switch startType {
            case .string where startDisplay != nil:
                if startDisplay?.daysUntil() ?? 0 < 1 {
                    return CoreLocalization.Course.starting(startDate?.timeUntilDisplay() ?? "")
                } else {
                    return CoreLocalization.Course.starting(formattedStartDate)
                }
            case .timestamp where startDate != nil:
                return CoreLocalization.Course.starting(formattedStartDate)
            case .empty where startDate != nil:
                return CoreLocalization.Course.starting(formattedStartDate)
            default:
                return CoreLocalization.Course.starting(CoreLocalization.Course.soon)
            }
        }
    }
    
    private var formattedAuditExpires: String {
        guard let auditExpiry = auditAccessExpires as Date? else { return "" }

        let formattedExpiryDate = auditExpiry.stringValue(style: dateStyle)
        let timeSpan = 7 // show number of days when less than a week
        
        if auditExpiry.isInPast() {
            let days = auditExpiry.daysAgo()
            if days < 1 {
                return CoreLocalization.Course.Audit.expiredAgo(auditExpiry.timeAgoDisplay())
            }
            
            if days <= timeSpan {
                return CoreLocalization.Course.Audit.expiredDaysAgo(days)
            } else {
                return CoreLocalization.Course.Audit.expiredOn(formattedExpiryDate)
            }
        } else {
            let days = auditExpiry.daysUntil()
            if days < 1 {
                return CoreLocalization.Course.Audit.expiresIn(auditExpiry.timeUntilDisplay())
            }
            
            if days <= timeSpan {
                return CoreLocalization.Course.Audit.expiresIn(days)
            } else {
                return CoreLocalization.Course.Audit.expiresOn(formattedExpiryDate)
            }
        }
    }
}
