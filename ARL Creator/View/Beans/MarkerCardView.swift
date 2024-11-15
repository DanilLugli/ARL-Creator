import SwiftUI

struct MarkerCardView: View {
    var image: ReferenceMarker
    
    init(imageName: ReferenceMarker) {
        self.image = imageName
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 360, height: 200)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            image.image
                .resizable()
                .scaledToFit()
                .frame(width: 360, height: 200)
                .cornerRadius(10)
            
            if image.physicalWidth == 0.0 {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
                    .font(.system(size: 30))
                    .padding(10) // Spazio per posizionare l'icona all'interno del bordo
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
