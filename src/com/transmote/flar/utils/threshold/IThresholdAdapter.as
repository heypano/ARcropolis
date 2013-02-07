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
	 * Interface that defines how classes used for adaptive thresholding will interface with FLARManager.
	 * <p>
	 * Adaptive thresholding can result in better marker detection across a range of illumination.
	 * This is desirable for applications with low lighting, or in which the developer has little control
	 * over lighting conditions, such as with web applications.
	 * </p>
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public interface IThresholdAdapter {
		/**
		 * Init from a name-value paired object that contains parameters parsed from XML.
		 */
		function initFromXML (paramsObj:Object) :void;
		
		/**
		 * Calculate a new threshold.
		 * <p>
		 * This algorithm may just calculate a threshold and pass that back to FLARManager,
		 * which then passes it on to the tracker for internal thresholding.
		 * </p>
		 * <p>
		 * However, this algorithm may also modify the source BitmapData directly.
		 * In this case, the algorithm must return -1, to tell the tracker to skip
		 * its internal thresholding algorithm, and use the source BitmapData as modified here.
		 * </p>
		 * 
		 * @param	source				Source BitmapData used for computer vision analysis.
		 * @param	currentThreshold	Current threshold value.
		 * @return						New threshold value.
		 */
		function calculateThreshold (source:BitmapData, currentThreshold:Number) :Number;
		
		/**
		 * Reset calculations.
		 * @param	currentThreshold	current threshold value.
		 */
		function resetCalculations (currentThreshold:Number) :void;
		
		/**
		 * Returns <code>true</code> if this threshold adapter should run every frame;
		 * Returns <code>false</code> if this threshold adapter should run only when no markers are found.
		 */
		function get runsEveryFrame () :Boolean;
		
		/**
		 * Free this instance for garbage collection.
		 */
		function dispose () :void;
	}
}