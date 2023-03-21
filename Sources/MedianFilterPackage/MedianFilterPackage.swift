import UIKit

public class MedianFilterPackage {
    
    public init() {
    }
    
    private var colorRectValues = [[(color: UIColor, rect: CGRect)]]()
    private var queue = DispatchQueue(label: "com.MedianFilterPackage.serial.queue", attributes: .concurrent)
    
    public func createMedianFilter(image: UIImage, completion: @escaping (UIImage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Load the input image
            let inputImage = image
            
            // Get the width and height of the input image
            let width = Int(inputImage.size.width)
            let height = Int(inputImage.size.height)
            
            // Define the filter parameters
            let windowSize = 3
            
            self.colorRectValues = .init(repeating: .init(repeating: (.clear, .zero), count: height), count: width)
            
            let group = DispatchGroup()
            // Iterate over each pixel in the input image
            for x in 0..<width {
                for y in 0..<height {
                    DispatchQueue.global(qos: .userInteractive).async(group: group) {
                        // Create an array to hold the pixel values in the window
                        var pixelValues = [Int]()
                        
                        // Iterate over each pixel in the window
                        for i in -windowSize/2...windowSize/2 {
                            for j in -windowSize/2...windowSize/2 {
                                // Calculate the coordinates of the current pixel in the input image
                                let xCoord = x + i
                                let yCoord = y + j
                                
                                // Check if the current pixel is within the input image bounds
                                guard xCoord >= 0 && xCoord < width && yCoord >= 0 && yCoord < height else {
                                    continue
                                }
                                
                                // Get the grayscale value of the current pixel
                                guard let pixelColor = inputImage.getPixelColor(x: xCoord, y: yCoord) else { fatalError("") }
                                let grayScaleValue = Int(pixelColor.alpha)
                                
                                // Add the grayscale value to the pixel values array
                                pixelValues.append(grayScaleValue)
                            }
                        }
                        
                        // Sort the pixel values array and get the median value
                        let sortedPixelValues = pixelValues.sorted()
                        let medianValue = sortedPixelValues[sortedPixelValues.count/2]
                        
                        // Create a new pixel color with the median value
                        let outputColor = UIColor(red: CGFloat(medianValue) / 255.0, green: CGFloat(medianValue) / 255.0, blue: CGFloat(medianValue) / 255.0, alpha: 1.0)
                        let rect = CGRect(x: x, y: y, width: 1, height: 1)
                        
                        self.queue.async(group: group, flags: .barrier) {
                            self.colorRectValues[x][y] = (outputColor, rect)
                        }
                        
                        print("""
----------------------------------
MedianFilterPackage
x = \(x)
y = \(y)
width = \(width)
height = \(height)
----------------------------------
""")
                    }
                }
            }
            group.notify(queue: .main) {
                // Create a new output image context
                UIGraphicsBeginImageContextWithOptions(inputImage.size, false, inputImage.scale)
                
                for arr in self.colorRectValues {
                    for value in arr {
                        // Set the pixel color in the output image context
                        value.color.setFill()
                        UIRectFill(value.rect)
                    }
                }
                
                
                // Get the output image from the context
                guard let outputImage = UIGraphicsGetImageFromCurrentImageContext() else {
                    fatalError("Output image cannot be accessed.")
                }
                
                // End the image context
                UIGraphicsEndImageContext()
                
                completion(outputImage)
            }
        }
    }
}

extension UIImage {
    func getPixelColor(x: Int, y: Int) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        
        let pixelData = cgImage.dataProvider!.data!
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        let pixelOffset = (y * bytesPerRow) + (x * bytesPerPixel)
        let r = CGFloat(data[pixelOffset]) / 255.0
        let g = CGFloat(data[pixelOffset + 1]) / 255.0
        let b = CGFloat(data[pixelOffset + 2]) / 255.0
        let a = (r + g + b)/3
        
        let red = Double(r)
        let green = Double(g)
        let blue = Double(b)
        let alpha = Double(a)
        
        return (red, green, blue, alpha)
    }
}
