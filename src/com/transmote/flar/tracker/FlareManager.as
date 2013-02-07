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
package com.transmote.flar.tracker {
	import at.imagination.flare.FlareTracker;
	import at.imagination.flare.IFlareTracker;
	
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.flarManagerInternal;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FlareMarker;
	import com.transmote.flar.source.IFLARSource;
	import com.transmote.flar.utils.FLARManagerConfigLoader;
	import com.transmote.flar.utils.geom.FlareGeomUtils;
	import com.transmote.flar.utils.threshold.IThresholdAdapter;
	import com.transmote.utils.time.Timeout;
	
	import flash.display.Bitmap;
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	use namespace flarManagerInternal;
	
	
	/**
	 * Tracker library manager for use with Flare.
	 * Pass a FlareManager instance into the FLARManager constructor
	 * in order to use FLARManager with Flare.
	 *  
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FlareManager extends EventDispatcher implements IFLARTrackerManager {
		private static const DEFAULT_MARKER_TYPE:int = FlareTracker.MARKER_SIMPLE_ID;
		
		protected var markerDetector:IFlareTracker;
		protected var flarSource:IFLARSource;
		
		protected var resourcesPath:String;
		protected var cameraParamsFile:String;
		
		private var _logLevel:int = 1;
		private var bCameraParamsLoaded:Boolean = false;
		private var bTrackerInited:Boolean = false;
		
		private var pendingMarkerTypes:Vector.<int>;
		
		
		/**
		 * Constructor.
		 */
		public function FlareManager () {
			this.pendingMarkerTypes = new Vector.<int>();
		}
		
		
		//-----<ACCESSORS>-------------------------------------------//
		/**
		 * The string id of this tracker manager.
		 * All tracker manager ids are enumerated in FLARManager.as.
		 */
		public function get id () :String {
			return FLARManager.TRACKER_ID_FLARE;
		}
		
		/**
		 * Reference to IFLARSource instance from which the tracker gets
		 * the BitmapData object to analyze for object tracking.
		 */
		public function get trackerSource () :IFLARSource {
			return this.flarSource;
		}
		public function set trackerSource (flarSource:IFLARSource) :void {
			this.flarSource = flarSource;
		}
		
		/**
		 * Flare handles thresholding natively;
		 * methods here for IFLARTrackerManager compliance only.
		 */
		public function get thresholdAdapter () :IThresholdAdapter { return null; }
		public function set thresholdAdapter (thresholdAdapter:IThresholdAdapter) :void { }
		
		/**
		 * Flare handles thresholding natively;
		 * methods here for IFLARTrackerManager compliance only.
		 */
		public function get threshold () :Number { return -1; }
		public function set threshold (threshold:Number) :void { }
		
		/**
		 * Flare handles thresholding natively;
		 * methods here for IFLARTrackerManager compliance only.
		 */
		public function get thresholdSourceDisplay () :Boolean { return false; }
		public function set thresholdSourceDisplay (val:Boolean) :void { }
		
		/**
		 * Flare handles thresholding natively;
		 * methods here for IFLARTrackerManager compliance only.
		 */
		public function get thresholdSourceBitmap () :Bitmap { return null; }
		
		/**
		 * Set log level for FlareTracker / FlareNFT.
		 * Set to <code>0</code> to disable.
		 * Defaults to 1; disabling is not recommended as it may suppress important error messages. 
		 */
		public function get logLevel () :int {
			return this._logLevel;
		}
		public function set logLevel (val:int) :void {
			this._logLevel = val;
			if (!this.markerDetector) { return; }
			
			if (val <= 0) {
				this.markerDetector.setLogger(null, null, 0);
			} else {
				this.markerDetector.setLogger(this, this.onFlareLog, this._logLevel);
			}
		}
		
		/**
		 * add a marker detector to flare*tracker.
		 * flare*tracker supports markers of multiple types.
		 * FlareManager defaults to SIMPLE_ID type markers.
		 * 
		 * @param	markerType	marker type id, enumerated in FlareTracker.
		 * @param	param1		optional additional parameter; @see FlareTracker.addMarkerDetector for more information.
		 * @param	param2		optional additional parameter; @see FlareTracker.addMarkerDetector for more information.
		 * 
		 * @return				true if marker detector successfully added.
		 */
		public function addMarkerDetector (markerType:int, param1:Number=NaN, param2:Number=NaN) :Boolean {
			// add in onTrackerComplete if tracker not yet inited.
			if (!this.bTrackerInited) {
				// do not add if already pending
				for each (var mt:int in this.pendingMarkerTypes) {
					if (mt == markerType) { return false; }
				}
				
				this.pendingMarkerTypes.push(markerType);
				return true;
			}
			
			try {
				if (!isNaN(param1)) {
					if (!isNaN(param2)) {
						return FlareTracker(this.markerDetector).addMarkerDetector(markerType, param1, param2);
					}
					return FlareTracker(this.markerDetector).addMarkerDetector(markerType, param1);
				}
				return FlareTracker(this.markerDetector).addMarkerDetector(markerType);
			} catch (e:Error) {
				//
			}
			return false;
		}
		//-----<END ACCESSORS>---------------------------------------//
		
		
		
		//-----<INITIALIZATION>--------------------------------------//
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
		public function getProjectionMatrix (frameworkId:int, viewportSize:Rectangle) :Matrix3D {
			var projectionMatrix:Matrix3D = FlareGeomUtils.convertFlareMatrixToFlashMatrix(this.markerDetector.getProjectionMatrix(), false);
			
			switch (frameworkId) {
				case FLARManager.FRAMEWORK_ID_FLASH :
					return FlareGeomUtils.calcProjectionMatrix_Flash(projectionMatrix, viewportSize);
				case FLARManager.FRAMEWORK_ID_ALTERNATIVA :
					return FlareGeomUtils.calcProjectionMatrix_Alternativa(projectionMatrix, viewportSize);
				case FLARManager.FRAMEWORK_ID_AWAY :
					return FlareGeomUtils.calcProjectionMatrix_Away(projectionMatrix, viewportSize);
				case FLARManager.FRAMEWORK_ID_AWAY_LITE :
					return FlareGeomUtils.calcProjectionMatrix_AwayLite(projectionMatrix, viewportSize);
				case FLARManager.FRAMEWORK_ID_PAPERVISION :
					return FlareGeomUtils.calcProjectionMatrix_Papervision(projectionMatrix, viewportSize);
				case FLARManager.FRAMEWORK_ID_SANDY :
					return FlareGeomUtils.calcProjectionMatrix_Sandy(projectionMatrix, viewportSize);
				default :
					return null;
			}
		}
		
		/**
		 * Load configuration data for the tracker, including camera parameters.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	configLoader	The FLARManagerConfigLoader instance with loaded configuration data.
		 */
		public function loadTrackerConfig (configLoader:FLARManagerConfigLoader) :void {
			this.resourcesPath = configLoader.flare_resourcesPath;
			this.cameraParamsFile = configLoader.flare_cameraParamsFile;
			
			var timeout:Timeout = new Timeout(this.onInited, 1);
		}
		
		/**
		 * Initialize the tracker.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	stage	A reference to the application's Stage.
		 */
		public function initTracker (stage:Stage=null) :void {
			if (!stage) {
				throw new Error("Flare requires a Stage reference.");
			}
			
			this.markerDetector = new FlareTracker();
			
			if (this._logLevel > 0) {
				this.logLevel = this._logLevel;
			}
			
			FlareTracker(this.markerDetector).init(
				stage, this.resourcesPath, this.cameraParamsFile,
				this.flarSource.sourceSize.width, this.flarSource.sourceSize.height, this.onTrackerComplete)
		}
		
		private function onInited () :void {
			this.dispatchEvent(new Event(Event.INIT));
		}
		
		/**
		 * @private
		 */
		public function onTrackerComplete () :void {
			this.bTrackerInited = true;
			
			// if no pending marker types, init with DEFAULT_MARKER_TYPE
			if (this.pendingMarkerTypes.length == 0) {
				this.pendingMarkerTypes.push(DEFAULT_MARKER_TYPE);
			}
			
			for each (var markerType:int in this.pendingMarkerTypes) {
				this.addMarkerDetector(markerType);
			}
			this.pendingMarkerTypes = null;
			
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		//-----<END INITIALIZATION>----------------------------------//
		
		
		/**
		 * Flare handles thresholding natively,
		 * and therefore no source adjustments are required;
		 * methods here for IFLARTrackerManager compliance only.
		 */
		public function performSourceAdjustments () :void { }
		
		/**
		 * Instruct the tracker to detect objects (e.g. markers, patterns, images).
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 */
		public function detectMarkers () :Vector.<FLARMarker> {
			var numFoundMarkers:uint = this.markerDetector.update(this.flarSource.source);
			if (numFoundMarkers == 0) {
				return new Vector.<FLARMarker>();
			}
			
			return this.parseMarkers(numFoundMarkers);
		}
		
		protected function parseMarkers (numMarkers:uint) :Vector.<FLARMarker> {
			var i:uint;
			var markerData:ByteArray;
			var corners:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>(numMarkers, true);
			var patternType:int;
			var patternId:int;
			var transformMatrix:Matrix3D = new Matrix3D();
			var dataMatrixMessage:String;
			var detectedMarkers:Vector.<FLARMarker> = new Vector.<FLARMarker>();
			
			// since getTrackerResults() and getTrackerResults2D() return the same ByteArray (at a different .position),
			// parse 2D data first (if not using NFT)...
			if (this.markerDetector is FlareTracker) {
				markerData = FlareTracker(this.markerDetector).getTrackerResults2D();
				for (i=0; i<numMarkers; i++) {
					// burn off pattern type and id; will be harvested from 3D data.
					markerData.readInt();
					markerData.readInt();
					
					corners[i] = FlareGeomUtils.convertFlareData2D(markerData, this.flarSource.mirrored ? this.flarSource.sourceSize.width : 0);
				}
			}
			
			// ...then parse 3D data.
			markerData = this.markerDetector.getTrackerResults();
			for (i=0; i<numMarkers; i++) {
				patternType = markerData.readInt();
				patternId = markerData.readInt();
				transformMatrix = FlareGeomUtils.convertFlareMatrixToFlashMatrix(markerData, this.flarSource.mirrored);
				
				if (patternType == FlareTracker.MARKER_DATAMATRIX) {
					dataMatrixMessage = FlareTracker(this.markerDetector).getDataMatrixMessage(patternId);
				} else {
					dataMatrixMessage = null;
				}
				
				var marker:FlareMarker = new FlareMarker(patternId, transformMatrix, this.flarSource, corners[i], patternType, dataMatrixMessage);
				detectedMarkers.push(marker);
			}
			
			return detectedMarkers;
		}
		
		/**
		 * @private
		 */
		public function onFlareLog (level:int, message:String) :void {
			trace("[FlareManager (level "+ level +")] "+ message);
			
			if (message.indexOf(".lic") != -1) {
				// missing .lic file -- .lic file must live in same folder as .swf
				message = "[FLARManager] flare*tracker and flare*NFT require that a valid .lic file be in the same folder as the application .swf.\n"+ message;
				this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, message));
			}
		}
		
		/**
		 * Halts all processes and frees the tracker for garbage collection.
		 */
		public function dispose () :void {
			// NOTE: Flare classes do not implement any disposal functionality,
			//		 and will likely not be removed from memory on Flare disposal.
			//this.markerDetector.dispose();
			this.markerDetector = null;
			
			this.trackerSource.dispose();
			this.trackerSource = null;
		}
	}
}