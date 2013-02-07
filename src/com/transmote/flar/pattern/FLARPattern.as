/* 
* PROJECT: FLARManager
* http://transmote.com/flar
* Copyright 2009, Eric Socolofsky
* --------------------------------------------------------------------------------
* This work complements FLARToolkit, developed by Saqoosha as part of the Libspark project.
*	http://www.libspark.org/wiki/saqoosha/FLARToolKit
* FLARToolkit is Copyright (C)2008 Saqoosha,
* and is ported from NYARToolkit, which is ported from ARToolkit.
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this framework; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
* 
* For further information please contact:
*	<eric(at)transmote.com>
*	http://transmote.com/flar
* 
*/
package com.transmote.flar.pattern {
	import com.transmote.flar.marker.FLARMarker;
	
	
	/**
	 * Wrapper for all information needed by FLARToolkit to track an individual marker.
	 *  
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARPattern {
		public static const DEFAULT_UNSCALED_MARKER_WIDTH:Number = 80;
		public static const DEFAULT_PATTERN_TO_BORDER_RATIO:Number = 50;
		public static const DEFAULT_MIN_CONFIDENCE:Number = 0.5;
		
		internal var _filename:String;
		internal var _resolution:int;
		internal var _patternToBorderRatioX:Number;
		internal var _patternToBorderRatioY:Number;
		internal var _unscaledMarkerWidth:Number;
		internal var _minConfidence:Number;
		
		/**
		 * constructor.
		 * 
		 * @param	filename				The location of the marker pattern file.
		 * @param	resolution				The resolution (width/height) of the marker pattern file.
		 * @param	patternToBorderRatioX	Out of the entire width of a marker, the amount that
		 * 									the pattern occupies relative to the amount the border occupies.
		 * 									This value is expressed as a percentage.
		 * 									For example, a value of 50 indicates that the width of the pattern area
		 * 									is equal to the total width (on either side of the pattern) of the border.
		 *									Note that the border must still be a square (equal width and height).
		 * 									Defaults to 50.
		 * @param	patternToBorderRatioY	Out of the entire height of a marker, the amount that
		 * 									the pattern occupies relative to the amount the border occupies.
		 * 									This value is expressed as a percentage.
		 * 									For example, a value of 50 indicates that the width of the pattern area
		 * 									is equal to the total width (on either side of the pattern) of the border.
		 * 									Note that the border must still be a square (equal width and height).
		 * 									Defaults to 50.
		 * @param	unscaledMarkerWidth		The width of a marker (in pixels) on-screen at which
		 * 									the scale of its transformation matrix is 1.0.
		 * 									Defaults to 80.
		 * @param	minConfidence			'Confidence' is a value assigned by FLARToolkit to each detected marker,
		 * 									that describes the algorithm's perceived accuracy of the pattern match.
		 * 									This value sets the minimum confidence required to signal a recognized marker.
		 * 									Defaults to 0.5.
		 */
		public function FLARPattern (filename:String, resolution:int,
									 patternToBorderRatioX:Number=DEFAULT_PATTERN_TO_BORDER_RATIO, patternToBorderRatioY:Number=DEFAULT_PATTERN_TO_BORDER_RATIO,
									 unscaledMarkerWidth:Number=DEFAULT_UNSCALED_MARKER_WIDTH, minConfidence:Number=DEFAULT_MIN_CONFIDENCE) {
			this._filename = filename;
			this._resolution = resolution;
			
			// default parameters don't work with Numbers...
			if (isNaN(patternToBorderRatioX) || patternToBorderRatioX <= 0) {
				this._patternToBorderRatioX = DEFAULT_PATTERN_TO_BORDER_RATIO;
			} else {
				this._patternToBorderRatioX = patternToBorderRatioX;
			}
			if (isNaN(patternToBorderRatioY) || patternToBorderRatioY <= 0) {
				this._patternToBorderRatioY = DEFAULT_PATTERN_TO_BORDER_RATIO;
			} else {
				this._patternToBorderRatioY = patternToBorderRatioY;
			}
			
			if (isNaN(unscaledMarkerWidth) || unscaledMarkerWidth <= 0) {
				this._unscaledMarkerWidth = FLARMarker.DEFAULT_UNSCALED_MARKER_WIDTH;
			} else {
				this._unscaledMarkerWidth = unscaledMarkerWidth;
			}
			
			if (isNaN(minConfidence)) {
				this._minConfidence = DEFAULT_MIN_CONFIDENCE;
			} else {
				this._minConfidence = minConfidence;
			}
		}
		
		/**
		 * The location of the marker pattern file.
		 */
		public function get filename () :String {
			return this._filename;
		}
		
		/**
		 * The resolution (width/height) of the marker pattern file.
		 */
		public function get resolution () :Number {
			return this._resolution;
		}
		
		/**
		 * Out of the entire width of a marker, the amount that
		 * the pattern occupies relative to the amount the border occupies.
		 * This value is expressed as a percentage.
		 * For example, a value of 50 indicates that the width of the pattern area
		 * is equal to the total width (on either side of the pattern) of the border.
		 * Note that the border must still be a square (equal width and height).
		 */
		public function get patternToBorderRatioX () :Number {
			return this._patternToBorderRatioX;
		}
		/**
		 * Out of the entire height of a marker, the amount that
		 * the pattern occupies relative to the amount the border occupies.
		 * This value is expressed as a percentage.
		 * For example, a value of 50 indicates that the width of the pattern area
		 * is equal to the total width (on either side of the pattern) of the border.
		 * Note that the border must still be a square (equal width and height).
		 */
		public function get patternToBorderRatioY () :Number {
			return this._patternToBorderRatioY;
		}
		
		/**
		 * The width of a marker (in pixels) on-screen at which
		 * the scale of its transformation matrix is 1.0.
		 */
		public function get unscaledMarkerWidth () :Number {
			return this._unscaledMarkerWidth;
		}
		
		/**
		 * 'Confidence' is a value assigned by FLARToolkit to each detected marker,
		 * that describes the algorithm's perceived accuracy of the pattern match.
		 * This value sets the minimum confidence required to signal a recognized marker.
		 */
		public function get minConfidence () :Number {
			return this._minConfidence;
		}
		public function set minConfidence (val:Number) :void {
			this._minConfidence = val;
		}
	}
}