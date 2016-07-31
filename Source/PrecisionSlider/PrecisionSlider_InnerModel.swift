// MIT license. Copyright (c) 2016 SwiftyFORM. All rights reserved.
import Foundation

class PrecisionSlider_InnerModel: CustomDebugStringConvertible {
	var originalMaximumValue: Double = 0.0
	var originalMinimumValue: Double = 100.0
	
	var fallbackValue: Double {
		return (originalMaximumValue - originalMinimumValue) / 2
	}
	
	var minimumValue: Double = 0.0
	var maximumValue: Double = 100.0
	
	var zoomMode = PrecisionSlider_InnerZoomMode.None
	
	func updateRange() {
		zoomMode = PrecisionSlider_InnerZoomMode.create(scale)
		//print("zoomMode: \(zoomMode)  scale: \(scale)")
		
		maximumValue = originalMaximumValue * zoomMode.scalar
		minimumValue = originalMinimumValue * zoomMode.scalar
		
		var count = Int(floor(maximumValue) - ceil(minimumValue)) + 1
		
		let sizeBefore = ceil(minimumValue) - minimumValue
		//print("size before: \(sizeBefore)    \(minimumValue)")
		if sizeBefore > 0.0000001 {
			//print("partial item before. size: \(sizeBefore)   minimumValue: \(minimumValue)")
			hasPartialItemBefore = true
			sizeOfPartialItemBefore = sizeBefore
			count -= 1
		} else {
			hasPartialItemBefore = false
			sizeOfPartialItemBefore = 0
		}
		
		let sizeAfter = maximumValue - floor(maximumValue)
		//print("size after: \(sizeAfter)    \(maximumValue)")
		if sizeAfter > 0.0000001 {
			//print("partial item after. size: \(sizeAfter)   minimumValue: \(maximumValue)")
			hasPartialItemAfter = true
			sizeOfPartialItemAfter = sizeAfter
			count -= 1
		} else {
			hasPartialItemAfter = false
			sizeOfPartialItemAfter = 0
		}
		
		// prevent negative number of items
		if count < 0 {
			// In this case use the "single_cell"
			//			print("maximumValue=\(maximumValue)  minimumValue=\(minimumValue)")
			numberOfFullItems = 0
			hasOnePartialItem = true
			sizeOfOnePartialItem = maximumValue - minimumValue
			hasPartialItemBefore = false
			sizeOfPartialItemBefore = 0
			hasPartialItemAfter = false
			sizeOfPartialItemAfter = 0
		} else {
			numberOfFullItems = count
			hasOnePartialItem = false
		}
		
		//		print("model: \(self)")
	}
	
	/**
	This is used as a last resort when the range is too tiny that no other cells can be shown.
	
	The single_cell shows two markers.
	 1. Shows a `leftMark` for the minimumValue
	 2. Shows a `rightMark` for the maximumValue
	*/
	var hasOnePartialItem = false
	var sizeOfOnePartialItem: Double = 0.0
	
	/**
	This is used when the minimumValue doesn't align with any marker.
	
	The first_cell is two cells wide.
	The first_cell shows two markers. 
	 1. Shows a `mark` for the nearest marker to minimumValue
	 2. Shows a `partialMark` that indicates where the minimumValue is located
	*/
	var hasPartialItemBefore = false
	var sizeOfPartialItemBefore: Double = 0.0
	
	/**
	This is used when the maximumValue doesn't align with any marker.
	
	The last_cell is two cells wide.
	The last_cell shows two markers.
	 1. Shows a `mark` for the nearest marker to maximumValue
	 2. Shows a `partialMark` that indicates where the maximumValue is located
	*/
	var hasPartialItemAfter = false
	var sizeOfPartialItemAfter: Double = 0.0
	
	/**
	The full_cell is used for showing markers inbetween minimumValue and maximumValue.
	
	A full_cell shows a marker at midX.
	
	Example of such a range: from min=5.0 to max=6.0
	In this case there will be 2 full cells
	 * Cell 1: spans from min=4.5 to max=5.5 with a marker shown at 5.0
	 * Cell 2: spans from min=5.5 to max=6.5 with a marker shown at 6.0
	*/
	var numberOfFullItems = 100
	

	var markerSpacing: Double = 30

	/**
	The `scale` is logarithmic
	
	 1. scale  2 == 100   zoomed out
	 2. scale  1 == 10
	 3. scale  0 == 1     normal
	 4. scale -1 == 0.1
	 5. scale -2 == 0.01  zoomed in
	
	The scale works best in the range -3 to +3.
	Scale values outside -6 to +6 are extreme.
	*/
	var scale: Double = 0.0
	var minimumScale: Double = -5.0
	var maximumScale: Double = 5.0
	
	
	/// length is in pixels
	var lengthOfFullItem: Double {
		let result = ceil(pow(10, scale) * markerSpacing / zoomMode.scalar)
		if result < 0.1 {
			return 0.1
		}
		return result
	}
	
	var lengthOfAllFullItems: Double {
		return Double(numberOfFullItems) * lengthOfFullItem
	}
	var lengthOfOnePartialItem: Double {
		return ceil(lengthOfFullItem * sizeOfOnePartialItem)
	}
	var lengthOfPartialItemBefore: Double {
		return ceil(lengthOfFullItem * sizeOfPartialItemBefore)
	}
	var remainingLengthOfPartialItemBefore: Double {
		return ceil(lengthOfFullItem * (1.0 - sizeOfPartialItemBefore))
	}
	var lengthOfPartialItemAfter: Double {
		return ceil(lengthOfFullItem * sizeOfPartialItemAfter)
	}
	var remainingLengthOfPartialItemAfter: Double {
		return ceil(lengthOfFullItem * (1.0 - sizeOfPartialItemAfter))
	}
	
	var lengthOfContent: Double {
		if hasOnePartialItem {
			return lengthOfOnePartialItem
		}
		var length: Double = 0
		if hasPartialItemBefore {
			length += lengthOfFullItem * 2
		}
		length += lengthOfAllFullItems
		if hasPartialItemAfter {
			length += lengthOfFullItem * 2
		}
		return length
	}
	
	static let height: CGFloat = 130
	
	func labelTextForIndexPath(indexPath: NSIndexPath) -> String? {
		var index = Int(floor(minimumValue)) + indexPath.row
		if hasPartialItemBefore {
			index += 1
		}
		return zoomMode.markerText(index)
	}
	
	let markMajorColor = UIColor.blackColor()
	let markMinorColor = UIColor(white: 0.7, alpha: 1.0)
	
	func markColorForIndexPath(indexPath: NSIndexPath) -> UIColor? {
		var index = Int(floor(minimumValue)) + indexPath.row
		if hasPartialItemBefore {
			index += 1
		}
		switch zoomMode.markerType(index: index) {
		case .Major: return markMajorColor
		case .Minor: return markMinorColor
		case .Other: return UIColor.redColor()
		}
	}
	
	var debugDescription: String {
		var strings = [String]()
		strings.append("zoomMode: \(zoomMode)")
		strings.append(String(format: "scale: %.5f", scale))
		strings.append(String(format: "scale-range: %.5f %.5f", minimumScale, maximumScale))
		strings.append(String(format: "value-range: %.5f %.5f", minimumValue, maximumValue))
		if hasOnePartialItem {
			strings.append(String(format: "one-partial: %.5f", sizeOfOnePartialItem))
		}
		if hasPartialItemBefore {
			strings.append(String(format: "partial-before: %.5f", sizeOfPartialItemBefore))
		}
		strings.append("full: \(numberOfFullItems)")
		if hasPartialItemAfter {
			strings.append(String(format: "partial-after: %.5f", sizeOfPartialItemAfter))
		}
		return strings.joinWithSeparator(" , ")
	}
}