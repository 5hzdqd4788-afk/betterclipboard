import SwiftUI

enum Theme {
    static let popupWidth: CGFloat = 380
    static let maxPopupHeight: CGFloat = 520
    static let minPopupHeight: CGFloat = 200
    static let cornerRadius: CGFloat = 12
    static let itemCornerRadius: CGFloat = 8
    static let horizontalPadding: CGFloat = 10
    static let verticalPadding: CGFloat = 8
    
    static let animation = Animation.spring(response: 0.32, dampingFraction: 0.78)
    static let quickAnimation = Animation.easeOut(duration: 0.18)
}
