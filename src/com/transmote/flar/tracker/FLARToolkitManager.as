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
package com.transmote.flar.tracker {
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.flarManagerInternal;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FLARToolkitMarker;
	import com.transmote.flar.pattern.FLARPattern;
	import com.transmote.flar.pattern.FLARPatternLoader;
	import com.transmote.flar.source.IFLARSource;
	import com.transmote.flar.utils.FLARManagerConfigLoader;
	import com.transmote.flar.utils.geom.FLARGeomUtils;
	import com.transmote.flar.utils.geom.FLARToolkitGeomUtils;
	import com.transmote.flar.utils.threshold.IThresholdAdapter;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import jp.nyatla.nyartoolkit.as3.NyARException;
	import jp.nyatla.nyartoolkit.as3.core.NyARMat;
	import jp.nyatla.nyartoolkit.as3.core.param.NyARPerspectiveProjectionMatrix;
	import jp.nyatla.nyartoolkit.as3.core.squaredetect.NyARSquare;
	import jp.nyatla.nyartoolkit.as3.core.types.NyARIntSize;
	
	import org.libspark.flartoolkit.FLARException;
	import org.libspark.flartoolkit.core.labeling.fllabeling.FLARLabeling;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.core.types.FLARIntSize;
	import org.libspark.flartoolkit.detector.FLARMultiMarkerDetector;
	import org.libspark.flartoolkit.utils.ArrayUtil;
	
	use namespace flarManagerInternal;
	
	
	/**
	 * Tracker library manager for use with FLARToolkit.
	 * Pass a FLARToolkitManager instance into the FLARManager constructor
	 * in order to use FLARManager with FLARToolkit.
	 *  
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARToolkitManager extends EventDispatcher implements IFLARTrackerManager {
		private var bCameraParamsLoaded:Boolean = false;
		private var bPatternsLoaded:Boolean = false;
		
		private var allPatterns:Vector.<FLARPattern>;
		private var patternLoader:FLARPatternLoader;
		private var cameraParams:FLARParam;
		private var cameraSize:Rectangle;
		
		private var markerDetector:FLARMultiMarkerDetector;
		private var flarSource:IFLARSource;
		private var flarRaster:FLARRgbRaster_BitmapData;
		private var _thresholdSourceBitmap:Bitmap;
		private var _thresholdSourceDisplay:Boolean;
		
		private var _thresholdAdapter:IThresholdAdapter;
		private var _threshold:Number = 80;
		private var _labelAreaMin:Number = FLARLabeling.AR_AREA_MIN;
		private var _labelAreaMax:Number = FLARLabeling.AR_AREA_MAX;
		private var averageConfidence:Number = FLARPattern.DEFAULT_MIN_CONFIDENCE;
		private var averageMinConfidence:Number = FLARPattern.DEFAULT_MIN_CONFIDENCE;
		
		
		/**
		 * Constructor.
		 */
		public function FLARToolkitManager () {}
		
		
		//-----<ACCESSORS>-------------------------------------------//
		/**
		 * The string id of this tracker manager.
		 * All tracker manager ids are enumerated in FLARManager.as.
		 */
		public function get id () :String {
			return FLARManager.TRACKER_ID_FLARTOOLKIT;
		}
		
		/**
		 * Reference to IFLARSource instance from which the tracker gets
		 * the BitmapData object to analyze for object tracking.
		 */
		public function get trackerSource () :IFLARSource {
			return this.flarSource;
		}
		public function set trackerSource (flarSource:IFLARSource) :void {
			if (!this.cameraParams) {
				throw new Error("trackerSource cannot be set until cameraParams have loaded.");
			}
			if (!flarSource.source || !flarSource.source.width) {
				throw new Error("flarSource.source not yet inited.");
			}
			this.cameraParams.changeScreenSize(flarSource.source.width, flarSource.source.height);
			this.flarSource = flarSource;
			this.flarRaster = new FLARRgbRaster_BitmapData(flarSource.source);
		}
		
		/**
		 * IFLARThresholdAdapter instance used to automate threshold changes.
		 * 
		 * @see com.transmote.flar.FLARManager#thresholdAdapter
		 */
		public function get thresholdAdapter () :IThresholdAdapter {
			return this._thresholdAdapter;
		}
		public function set thresholdAdapter (thresholdAdapter:IThresholdAdapter) :void {
			this._thresholdAdapter = thresholdAdapter;
		}
		
		/**
		 * Threshold applied to BitmapData before tracker analysis.
		 * 
		 * @see com.transmote.flar.FLARManager#threshold
		 */
		public function get threshold () :Number {
			return this._threshold;
		}
		public function set threshold (threshold:Number) :void {
			this._threshold = threshold;
		}
		
		/**
		 * Set to <code>true</code> to display the source BitmapData used by the FLARToolkit post-thresholding.
		 * Displaying the thresholded source can be useful for debugging threshold changes.
		 */
		public function get thresholdSourceDisplay () :Boolean {
			return this._thresholdSourceDisplay;
		}
		public function set thresholdSourceDisplay (val:Boolean) :void {
			this._thresholdSourceDisplay = val;
			if (this._thresholdSourceDisplay) {
				try {
					if (!this._thresholdSourceBitmap) {
						if (!this.markerDetector.thresholdedBitmapData) {
							throw new Error("Error initializing FLARMultiMarkerDetector; thresholdedBitmapData not inited.");
						}
						this._thresholdSourceBitmap = new Bitmap(this.markerDetector.thresholdedBitmapData);
					}
				} catch (e:Error) {
					this._thresholdSourceBitmap = null;
					return;
				}
			}
			
			if (val) {
				Sprite(this.flarSource).addChild(this.thresholdSourceBitmap);
			}
		}
		
		/**
		 * Retrieve a Bitmap to display the source BitmapData analyzed by the tracker post-thresholding.
		 * Displaying the thresholded source can be useful for debugging threshold changes.
		 */ 
		public function get thresholdSourceBitmap () :Bitmap {
			return this._thresholdSourceBitmap;
		}
		
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
			switch (frameworkId) {
				case FLARManager.FRAMEWORK_ID_FLASH :
					return FLARToolkitGeomUtils.calcProjectionMatrix_Flash(this.cameraParams, viewportSize);
				case FLARManager.FRAMEWORK_ID_ALTERNATIVA :
					return FLARToolkitGeomUtils.calcProjectionMatrix_Alternativa(this.cameraParams, viewportSize);
				case FLARManager.FRAMEWORK_ID_AWAY :
					return FLARToolkitGeomUtils.calcProjectionMatrix_Away(this.cameraParams, viewportSize);
				case FLARManager.FRAMEWORK_ID_AWAY_LITE :
					return FLARToolkitGeomUtils.calcProjectionMatrix_AwayLite(this.cameraParams, viewportSize);
				case FLARManager.FRAMEWORK_ID_PAPERVISION :
					return FLARToolkitGeomUtils.calcProjectionMatrix_Papervision(this.cameraParams, viewportSize);
				case FLARManager.FRAMEWORK_ID_SANDY :
					return FLARToolkitGeomUtils.calcProjectionMatrix_Sandy(this.cameraParams, viewportSize);
				default :
					return null;
			}
		}
		
		/**
		 * Minimum size (<code>width*height</code>) a dark area of the source image must be
		 * in order to become a candidate for marker outline detection.
		 * <p>
		 * Higher values result in faster performance,
		 * but poorer marker detection at smaller on-screen sizes.
		 * </p>
		 * <p>
		 * Defaults to <code>FLARLabeling.AR_AREA_MIN</code>, which is <code>70</code> at the time of this writing.
		 * </p>
		 * <p>
		 * Can be set in flarConfig.xml, as an attribute of the <code>&lt;flarToolkitSettings&gt;</code> element.
		 * </p>
		 */
		public function get labelAreaMin () :Number {
			return this._labelAreaMin;
		}
		public function set labelAreaMin (val:Number) :void {
			this._labelAreaMin = val;
			this.markerDetector.setAreaRange(this._labelAreaMax, this._labelAreaMin);
		}
		
		/**
		 * Maximum size (<code>width*height</code>) a dark area of the source image can be
		 * in order to become a candidate for marker outline detection.
		 * <p>
		 * Lower values may result in faster performance,
		 * but poorer marker detection at larger on-screen sizes.
		 * </p>
		 * <p>
		 * Defaults to <code>FLARLabeling.AR_AREA_MAX</code>, which is <code>100000</code> at the time of this writing.
		 * </p>
		 * <p>
		 * Can be set in flarConfig.xml, as an attribute of the <code>&lt;flarToolkitSettings&gt;</code> element.
		 * </p>
		 */
		public function get labelAreaMax () :Number {
			return this._labelAreaMax;
		}
		public function set labelAreaMax (val:Number) :void {
			this._labelAreaMax = val;
			this.markerDetector.setAreaRange(this._labelAreaMax, this._labelAreaMin);
		}
		//-----<END ACCESSORS>---------------------------------------//
		
		
		
		//-----<INITIALIZATION>--------------------------------------//
		/**
		 * Load configuration data for the tracker, including camera parameters.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	configLoader	The FLARManagerConfigLoader instance with loaded configuration data.
		 */
		public function loadTrackerConfig (configLoader:FLARManagerConfigLoader) :void {
			// camera params
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(IOErrorEvent.IO_ERROR, this.onCameraParamsLoadError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onCameraParamsLoadError);
			loader.addEventListener(Event.COMPLETE, this.onCameraParamsLoaded);
			loader.load(new URLRequest(configLoader.flarToolkit_cameraParamsFile));
			
			// pattern files
			this.allPatterns = configLoader.patterns;
			this.patternLoader = new FLARPatternLoader();
			this.patternLoader.addEventListener(Event.INIT, this.onPatternsLoaded);
			this.patternLoader.loadTrackerConfig(this.allPatterns);
			
			// additional params
			if (!isNaN(configLoader.flarToolkit_labelAreaMin)) {
				this._labelAreaMin = configLoader.flarToolkit_labelAreaMin;
			}
			if (!isNaN(configLoader.flarToolkit_labelAreaMax)) {
				this._labelAreaMax = configLoader.flarToolkit_labelAreaMax;
			}
			
			if (configLoader.flarToolkit_thresholdSourceDisplayStr == "true") {
				this.thresholdSourceDisplay = true;
			} else if (configLoader.flarToolkit_thresholdSourceDisplayStr == "false") {
				this.thresholdSourceDisplay = false;
			}
		}
		
		/**
		 * Initialize the tracker.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	stage	A reference to the application's Stage.
		 */
		public function initTracker (stage:Stage=null) :void {
			this.markerDetector = new FLARMultiMarkerDetector(this.cameraParams, this.patternLoader.loadedPatterns, this.patternLoader.unscaledMarkerWidths, this.patternLoader.loadedPatterns.length);
			this.markerDetector.setAreaRange(this._labelAreaMax, this._labelAreaMin);
			
			// FLARMultiMarkerDetector 'continue mode' is, i believe, intended to extrapolate marker position between frames.
			// this should smooth reported marker positions across frames.
			// however, i don't notice much functional difference...
			this.markerDetector.setContinueMode(true);
			
			this.onTrackerComplete();
		}
		
		private function onCameraParamsLoadError (evt:Event) :void {
			var errorText:String = "Camera params load error.";
			if (evt is IOErrorEvent) {
				errorText = IOErrorEvent(evt).text;
			} else if (evt is SecurityErrorEvent) {
				errorText = SecurityErrorEvent(evt).text;
			}
			
			this.onCameraParamsLoaded(evt, new Error(errorText));
		}
		
		private function onCameraParamsLoaded (evt:Event, error:Error=null) :void {
			var loader:URLLoader = evt.target as URLLoader;
			loader.removeEventListener(IOErrorEvent.IO_ERROR, this.onCameraParamsLoadError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onCameraParamsLoadError);
			loader.removeEventListener(Event.COMPLETE, this.onCameraParamsLoaded);
			
			if (error) { throw error; }
			
			this.cameraParams = new FLARParam();
			this.cameraParams.loadARParam(ByteArray(loader.data));
			
			this.bCameraParamsLoaded = true;
			this.checkForInitComplete();
		}
		
		private function onPatternsLoaded (evt:Event) :void {
			this.patternLoader.removeEventListener(Event.INIT, this.onPatternsLoaded);
			this.bPatternsLoaded = true;
			this.checkForInitComplete();
		}
		
		private function checkForInitComplete () :void {
			if (!this.bCameraParamsLoaded || !this.bPatternsLoaded) { return; }
			
			if (this.patternLoader.loadedPatterns.length == 0) {
				throw new Error("no markers successfully loaded.");
			}
			
			this.dispatchEvent(new Event(Event.INIT));
		}
		
		private function onTrackerComplete () :void {
			// set up thresholdSourceDisplay
			if (this._thresholdSourceDisplay) {
				this._thresholdSourceDisplay = false;
				this.thresholdSourceDisplay = true;
			}
			
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		//-----<END INITIALIZATION>----------------------------------//
		
		
		
		/**
		 * Perform any adjustments, such as thresholding,
		 * to the source BitmapData before tracker analysis.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 */
		public function performSourceAdjustments () :void {
			if (this._thresholdAdapter) {
				if (this._thresholdAdapter.runsEveryFrame) {
					// adjust threshold every frame.
					this._threshold = this._thresholdAdapter.calculateThreshold(this.flarSource.source, this._threshold);
				} else {
					// adjust threshold only when confidence is low (poor marker detection).
					if (this.averageConfidence <= this.averageMinConfidence) {
						this._threshold = this._thresholdAdapter.calculateThreshold(this.flarSource.source, this._threshold);
					} else {
						this._thresholdAdapter.resetCalculations(this._threshold);
					}					
				}
				this.averageConfidence = this.averageMinConfidence = 0;
			}
		}
		
		/**
		 * Instruct the tracker to detect objects (e.g. markers, patterns, images).
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 */
		public function detectMarkers () :Vector.<FLARMarker> {
			var numFoundMarkers:int = 0;
			try {
				// detect marker(s)
				numFoundMarkers = this.markerDetector.detectMarkerLite(this.flarRaster, this.threshold);
			} catch (e:NyARException) {
				// error in FLARToolkit processing; send to console
				trace(e);
				return null;
			}
			
			// build list of detected markers
			var detectedMarkers:Vector.<FLARMarker> = new Vector.<FLARMarker>();
			
			if (numFoundMarkers == 0) {
				return detectedMarkers;
			}
			
			var patternId:int;
			var direction:int;
			var square:NyARSquare;
			
			var detectedPattern:FLARPattern;
			var confidence:Number;
			var confidenceSum:Number = 0;
			var minConfidenceSum:Number = 0;
			var transmat:FLARTransMatResult;
			var i:uint = numFoundMarkers;
			while (i--) {
				patternId = this.markerDetector.getARCodeIndex(i);
				direction = this.markerDetector.getDirection(i);
				square = this.markerDetector.getSquare(i);
				
				detectedPattern = this.allPatterns[patternId];
				confidence = this.markerDetector.getConfidence(i);
				confidenceSum += confidence;
				minConfidenceSum += detectedPattern.minConfidence;
				if (confidence < detectedPattern.minConfidence) {
					// detected marker's confidence is below the minimum required confidence for its pattern.
					continue;
				}
				
				transmat = new FLARTransMatResult();
				try {
					this.markerDetector.getTransformMatrix(i, transmat);
				} catch (e:Error) {
					// FLARException happens with rotationX of approx -60 and +60, and rotY&Z of 0.
					// not sure why...
					continue;
				}
				
				detectedMarkers.push(new FLARToolkitMarker(
					FLARToolkitGeomUtils.convertNyARMatrixToFlashMatrix3D(transmat, this.flarSource.mirrored),
					this.flarSource, detectedPattern, patternId, direction, square, confidence));
			}
			this.averageConfidence = confidenceSum / numFoundMarkers;
			this.averageMinConfidence = minConfidenceSum / numFoundMarkers;
			
			return detectedMarkers;
		}
		
		/**
		 * Halts all processes and frees the tracker for garbage collection.
		 */
		public function dispose () :void {
			this.patternLoader.dispose();
			this.patternLoader = null;
			this.allPatterns = null;
			
			this.cameraParams = null;
			if (this._thresholdAdapter) {
				this._thresholdAdapter.dispose();
				this._thresholdAdapter = null;
			}
			
			if (this._thresholdSourceBitmap) {
				this._thresholdSourceBitmap.bitmapData.dispose();
			}
			this._thresholdSourceBitmap = null;
			
			// NOTE: FLARToolkit classes do not implement any disposal functionality,
			//		 and will likely not be removed from memory on FLARManager disposal.
			//this.markerDetector.dispose();
			this.markerDetector = null;
			// this.trackerSource.dispose();	// already disposed by FLARManager.dispose
			this.flarSource = null;
			this.flarRaster = null;
		}
	}
}