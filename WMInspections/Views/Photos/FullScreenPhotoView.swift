import SwiftUI

struct FullScreenPhotoView: View {
    let filename: String
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero

    private let dismissThreshold: CGFloat = 120

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image = PhotoStorageService.loadFullImage(filename: filename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(dragOffset)
                        .opacity(opacityForDrag)
                        .gesture(magnification)
                        .simultaneousGesture(scale <= 1.01 ? swipeDownToDismiss : nil)
                        .gesture(doubleTap)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("Photo unavailable")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                if let onDelete {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var opacityForDrag: Double {
        let progress = min(abs(dragOffset.height) / 400, 1)
        return 1.0 - progress * 0.6
    }

    private var magnification: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = max(1.0, min(lastScale * value.magnification, 5.0))
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private var swipeDownToDismiss: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = CGSize(width: 0, height: value.translation.height)
                }
            }
            .onEnded { value in
                if value.translation.height > dismissThreshold {
                    dismiss()
                } else {
                    withAnimation(.spring()) { dragOffset = .zero }
                }
            }
    }

    private var doubleTap: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    if scale > 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                    } else {
                        scale = 2.5
                        lastScale = 2.5
                    }
                }
            }
    }
}
