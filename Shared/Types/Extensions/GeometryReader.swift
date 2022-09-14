import SwiftUI

public struct SizePreferenceKey: PreferenceKey {
    public static var defaultValue: CGSize = .zero
    public static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

public struct SafeAreaInsetsPreferenceKey: PreferenceKey {
    public static var defaultValue: EdgeInsets = .init()
    public static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {}
}

public extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

    func readSafeAreaInsets(onChange: @escaping (EdgeInsets) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SafeAreaInsetsPreferenceKey.self, value: geometryProxy.safeAreaInsets)
            }
        )
        .onPreferenceChange(SafeAreaInsetsPreferenceKey.self, perform: onChange)
    }
}
