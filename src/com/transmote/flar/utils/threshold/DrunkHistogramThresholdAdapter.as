/* 
* PROJECT: FLARManager
* http://transmote.com/flar
* Copyright 2009, Eric Socolofsky
* --------------------------------------------------------------------------------
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
package com.transmote.flar.utils.threshold {
	import flash.display.BitmapData;
	
	/**
	 * DrunkHistogramThresholdAdapter calculates a new threshold using weighted randomization.
	 * When marker detection is poor, DrunkHistogramThresholdAdapter adjusts the threshold by moving a random amount
	 * away from the current threshold value based on <code>this.speed</code> and a bias calculated from the source histogram.
	 * <p>
	 * See the following URLs for more information:
	 * <ul>
	 * <li><a href="http://blog.jactionscripters.com/2009/05/18/adaptive-thresholding-experiment/comment-page-1/#comment-367">http://blog.jactionscripters.com/2009/05/18/adaptive-thresholding-experiment/comment-page-1/#comment-367</a></li>
	 * <li><a href="http://makc3d.wordpress.com/2009/07/03/alternative-to-adaptive-thresholding/">http://makc3d.wordpress.com/2009/07/03/alternative-to-adaptive-thresholding/</a></li>
	 * </ul>
	 * </p>
	 * Thanks for <a href="http://mattreyuk.wordpress.com/">Matt Reynolds</a> for
	 * the suggestion to combine histogram analysis with the drunk walk.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class DrunkHistogramThresholdAdapter implements IThresholdAdapter {
		private static const MIN_VARIANCE:Number = 5;
		private static const MAX_VARIANCE:Number = 50;
		
		private var _speed:Number;
		
		private var adaptiveThresholdingStep:Number = MIN_VARIANCE;
		
		
		public function DrunkHistogramThresholdAdapter (speed:Number=0.3) {
			this._speed = speed;
		}
		
		/**
		 * Init from a name-value paired object that contains parameters parsed from XML.
		 */
		public function initFromXML (paramsObj:Object) :void {
			if (!isNaN(paramsObj.speed)) {
				this.speed = parseFloat(paramsObj.speed);
			}
		}

		/**
		 * Calculate a new threshold.
		 * 
		 * @param	source				Used to calculate bias adjustment based on source histogram.
		 * @param	currentThreshold	Current threshold value.
		 * @return						New threshold value.
		 */
		public function calculateThreshold (source:BitmapData, currentThreshold:Number) :Number {
			var thresholdAdaptationMod:Number = (Math.random()-0.5 + 0.5*this.calculateBias(source));
			this.adaptiveThresholdingStep = Math.min(Math.pow(this.adaptiveThresholdingStep, 1+this._speed), MAX_VARIANCE);
			
			var newThreshold:Number = currentThreshold + (thresholdAdaptationMod * this.adaptiveThresholdingStep);
			newThreshold = Math.max(0, Math.min(newThreshold, 255));
			
			return newThreshold;
		}
		
		/**
		 * Reset calculations.
		 */
		public function resetCalculations (currentThreshold:Number) :void {
			this.adaptiveThresholdingStep = MIN_VARIANCE;
		}
		
		/**
		 * Free this instance for garbage collection.
		 */
		public function dispose () :void {
			//
		}
		
		/**
		 * Returns <code>false</code>;
		 * DrunkHistogramThresholdAdapter runs only when confidence is low (poor marker detection).
		 */
		public function get runsEveryFrame () :Boolean {
			return false;
		}
		
		/**
		 * The speed at which the threshold changes during adaptive thresholding.
		 * Larger values may increase the speed at which the markers in uneven illumination are detected,
		 * but may also result in instability in marker detection.
		 * 
		 * Value must be zero or greater.  The default is 0.3.
		 * A value of zero will disable adaptive thresholding.
		 */
		public function get speed () :Number {
			return this._speed;
		}
		public function set speed (val:Number) :void {
			this._speed = Math.max(0, val);
		}
		
		private function calculateBias (source:BitmapData) :Number {
			var histogram:Vector.<Vector.<Number>> = source.histogram();
			var numPx:Number = source.width * source.height;
			
			// calculate average brightness of source image
			var i:int = 255;
			var sum:Number = 0;
			while (i--) {
				sum += (histogram[0][i] + histogram[1][i] + histogram[2][i]) * i;
			}
			
			// apply bias based on distance from neutral brightness (255/2)
			var avg:Number = sum / (numPx * 3);
			var bias:Number = Math.pow((avg-127.5)/127.5, 3);
			
			return bias;
		}
	}
}