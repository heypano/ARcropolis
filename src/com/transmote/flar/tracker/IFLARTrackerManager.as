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
*/
package com.transmote.flar.tracker {
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.source.IFLARSource;
	import com.transmote.flar.utils.FLARManagerConfigLoader;
	import com.transmote.flar.utils.threshold.IThresholdAdapter;
	
	import flash.display.Bitmap;
	import flash.display.Stage;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	/**
	 * Interface that defines how different tracking libraries plug into FLARManager.
	 * All tracker managers must implement this interface.
	 *  
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public interface IFLARTrackerManager extends IEventDispatcher {
		/**
		 * The string id of this tracker manager.
		 * All tracker manager ids are enumerated in FLARManager.as.
		 */
		function get id () :String;
		
		/**
		 * Reference to IFLARSource instance from which the tracker gets
		 * the BitmapData object to analyze for object tracking.
		 */
		function get trackerSource () :IFLARSource;
		function set trackerSource (flarSource:IFLARSource) :void;
		
		/**
		 * IFLARThresholdAdapter instance used to automate threshold changes.
		 * 
		 * @see com.transmote.flar.FLARManager#thresholdAdapter
		 */
		function get thresholdAdapter () :IThresholdAdapter;
		function set thresholdAdapter (thresholdAdapter:IThresholdAdapter) :void;
		
		/**
		 * Threshold applied to BitmapData before tracker analysis.
		 * 
		 * @see com.transmote.flar.FLARManager#threshold
		 */
		function get threshold () :Number;
		function set threshold (threshold:Number) :void;
		
		/**
		 * Set to <code>true</code> to display the source BitmapData used by the tracker post-thresholding.
		 * 
		 * @see com.transmote.flar.FLARManager#thresholdSourceDisplay
		 */
		function get thresholdSourceDisplay () :Boolean;
		function set thresholdSourceDisplay (val:Boolean) :void;
		
		/**
		 * Retrieve a Bitmap to display the source BitmapData analyzed by the tracker post-thresholding.
		 * Displaying the thresholded source can be useful for debugging threshold changes.
		 */ 
		function get thresholdSourceBitmap () :Bitmap;
		
		/**
		 * Retrieve the projection matrix used by the tracker
		 * to map 3D transform matrices to the perspective view of the application.
		 * Use the returned Matrix3D instance with the application's 3D framework camera,
		 * or apply directly to a container object.
		 * 
		 * @param	frameworkId		The id of the 3D framework used by the application,
		 * 							as enumerated in FLARManager.
		 * @param	viewportSize	The size, as a Rectangle instance, of the container
		 * 							holding all 3D objects to be transformed by the tracker results.
		 */ 
		function getProjectionMatrix (frameworkId:int, viewportSize:Rectangle) :Matrix3D;
		
		/**
		 * Load configuration data for the tracker, including camera parameters.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	configLoader	The FLARManagerConfigLoader instance with loaded configuration data.
		 */
		function loadTrackerConfig (configLoader:FLARManagerConfigLoader) :void;
		
		/**
		 * Initialize the tracker.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	stage	A reference to the application's Stage.
		 */
		function initTracker (stage:Stage=null) :void;
		
		/**
		 * Perform any adjustments, such as thresholding,
		 * to the source BitmapData before tracker analysis.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 */
		function performSourceAdjustments () :void;
		
		/**
		 * Instruct the tracker to detect objects (e.g. markers, patterns, images).
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 */
		function detectMarkers () :Vector.<FLARMarker>;
		
		/**
		 * Halts all processes and frees the tracker for garbage collection.
		 */
		function dispose () :void;
	}
}