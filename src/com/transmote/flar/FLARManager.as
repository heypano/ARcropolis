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
package com.transmote.flar {
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FLARMarkerEvent;
	import com.transmote.flar.source.FLARCameraSource;
	import com.transmote.flar.source.FLARLoaderSource;
	import com.transmote.flar.source.FLARProxy;
	import com.transmote.flar.source.IFLARSource;
	import com.transmote.flar.tracker.IFLARTrackerManager;
	import com.transmote.flar.utils.FLARManagerConfigLoader;
	import com.transmote.flar.utils.smoother.FLARMatrixSmoother_Average;
	import com.transmote.flar.utils.smoother.IFLARMatrixSmoother;
	import com.transmote.flar.utils.threshold.DefaultThresholdAdapter;
	import com.transmote.flar.utils.threshold.DrunkHistogramThresholdAdapter;
	import com.transmote.flar.utils.threshold.IThresholdAdapter;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.filters.BlurFilter;
	import flash.filters.ShaderFilter;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	
	use namespace flarManagerInternal;
	
	/**
	 * Manager for computer vision applications using object-tracking / augmented reality
	 * libraries like <a href="http://www.libspark.org/wiki/saqoosha/FLARToolKit/en">
	 * FLARToolkit</a> and <a href="http://imagination.at/en/">Flare/NFT</a>.
	 * 
	 * <p>
	 * Basic usage is as follows:
	 * Instantiate an IFLARTrackerManager to communicate with the tracking library of your choice.
	 * Pass it into the FLARManager constructor, along with a reference to the application Stage
	 * and the path to the xml configuration file (by default, flarConfig.xml).
	 * For more information about the xml configuration file, please see
	 * <a href="http://words.transmote.com/wp/flarmanager/flarmanager-documentation/">the online documentation</a>.
	 * </p>
	 * <p>
	 * Assign event listeners to FLARManager for <code>MARKER_ADDED</code>,
	 * <code>MARKER_UPDATED</code>, and <code>MARKER_REMOVED</code> FLARMarkerEvents.
	 * These FLARMarkerEvents encapsulate the FLARMarker instances that they refer to.
	 * Alternatively, it is possible to retrieve all active markers
	 * directly from FLARManager, via <code>FLARManager.activeMarkers</code>.
	 * Use FLARMarker's properties along with the appropriate matrix conversion methods in the
	 * <code>com.transmote.flar.utils.geom</code> package to transform display objects to align with detected markers.
	 * </p>
	 * <p>
	 * FLARMarker instances contain information about objects detected by the
	 * selected tracking library.  FLARManager maintains a list of active markers,
	 * and updates the list and the markers within every frame.
	 * </p>
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 * @see		com.transmote.flar.marker.FLARMarkerEvent
	 * @see		com.transmote.flar.source.FLARCameraSource
	 * @see		com.transmote.flar.source.FLARProxy
	 */
	public class FLARManager extends EventDispatcher {
		public static const TRACKER_ID_FLARTOOLKIT:String = "FLARToolkitManager";
		public static const TRACKER_ID_FLARE:String = "FlareManager";
		public static const TRACKER_ID_FLARE_NFT:String = "FlareNFTManager";
		private static const TRACKER_CLASSPATH:String = "com.transmote.flar.";
		
		public static const FRAMEWORK_ID_FLASH:int = 1;
		public static const FRAMEWORK_ID_ALTERNATIVA:int = 2;
		public static const FRAMEWORK_ID_AWAY:int = 3;
		public static const FRAMEWORK_ID_AWAY_LITE:int = 4;
		public static const FRAMEWORK_ID_PAPERVISION:int = 5;
		public static const FRAMEWORK_ID_SANDY:int = 6;
		
		private static const ZERO_POINT:Point = new Point();
		
		// general management
		private var stage:Stage;
		private var configLoader:FLARManagerConfigLoader;
		private var _flarSource:IFLARSource;
		private var _trackerManager:IFLARTrackerManager;
		
		// source and detection adjustment
		private var _sampleBlurring:int = 1;
		private var _inverted:Boolean;
		private var _mirrorDisplay:Boolean = true;
		
		// marker adjustment
		private var _markerUpdateThreshold:Number = 80;
		private var _markerRemovalDelay:int = 1;
		private var _markerExtrapolation:Boolean = true;
		private var _smoothing:int = 3;
		private var _smoother:IFLARMatrixSmoother;
		private var _adaptiveSmoothingCenter:Number = 10;
		
		// pattern and marker management
		private var _activeMarkers:Vector.<FLARMarker>;
		private var markersPendingRemoval:Vector.<FLARMarker>;
		
		// marker adjustment (private)
		private var enterframer:Sprite;
		private var sampleBlurFilter:BlurFilter;
		private var inversionShaderFilter:ShaderFilter;
		
		// application state
		private var bInited:Boolean;
		private var bActive:Boolean;
		private var bVerbose:Boolean;
		
		
		
		/**
		 * Constructor.
		 * <p>
		 * Dispatches the following events:
		 * <code>Event.COMPLETE</code>: when the configuration xml is loaded and parsed.
		 * <code>Event.INIT</code>: when the <code>trackerManager</code> has initialized and FLARManager begins detecting markers.
		 * <code>ErrorEvent.ERROR</code>: in the case that configuration loading or parsing fails.
		 * <code>ErrorEvent.ERROR</code>: in the case that camera initialization fails.
		 * </p>
		 * 
		 * @param	flarConfig		Pass the path to the FLARManager configuration xml file as a String to load the file;
		 * 							or pass an XML instance to configure FLARManager directly.
		 * 							For more information about the xml configuration file, please see
		 * 							<a href="http://words.transmote.com/wp/flarmanager/flarmanager-documentation/">the online documentation</a>.
		 * @param	trackerManager	An IFLARTrackerManager instance that communicates with a tracking library.
		 * 							The IFLARTrackerManager selected specifies the tracking library that will be used.
		 * @param	stage			Reference to Stage. Required by some trackers.
		 */
		public function FLARManager (flarConfig:*, trackerManager:IFLARTrackerManager, stage:Stage) {
			this._flarSource = new FLARCameraSource();
			this.stage = stage;
			
			this._trackerManager = trackerManager;
			this.thresholdAdapter = new DefaultThresholdAdapter();
			
			this.initConfigLoader();
			if (flarConfig is XML) {
				this.configLoader.parseConfigFile(XML(flarConfig));
			} else {
				this.configLoader.loadConfigFile(String(flarConfig));
			}
		}
		
		
		
		//-----<CONFIG ACCESSORS>------------------------------------//
		/**
		 * Threshold applied to BitmapData before tracker analysis.
		 * Pixels in source image with a brightness &lt;= to <code>this.threshold</code>
		 * are candidates for marker outline detection.
		 * defaults to <code>80</code> (values can range from <code>0</code> to <code>255</code>).
		 */
		public function get threshold () :int {
			return this._trackerManager.threshold;
		}
		public function set threshold (val:int) :void {
			if (this.bVerbose && !this.thresholdAdapter) {
				trace("[FLARManager] threshold: "+ val);
			}
			this._trackerManager.threshold = val;
		}
		
		/**
		 * IFLARThresholdAdapter used to automate threshold changes.
		 * <p>
		 * Adaptive thresholding can result in better marker detection across a range of illumination.
		 * This is desirable for applications with low lighting, or in which the developer has little control
		 * over lighting conditions, such as with web applications.
		 * </p>
		 * <p>
		 * Note that when using FLARToolkit, adaptive thresholding may cause
		 * slower performance in very dark environments.
		 * This happens because a low threshold creates an image with large black areas,
		 * and images with a lot of black can cause slowdown in FLARToolkit's labeling process
		 * (<code>FLARLabeling_BitmapData.labeling()</code>).
		 * In this case, <code>thresholdAdapter</code> should be set to null.
		 * </p>
		 * <p>
		 * The default threshold adapter is DrunkHistogramThresholdAdapter, but developers can implement their own
		 * algorithms for adaptive thresholding.  To do so, implement the IThresholdAdapter interface.
		 * </p>
		 */
		public function get thresholdAdapter () :IThresholdAdapter {
			return this._trackerManager.thresholdAdapter;
		}
		public function set thresholdAdapter (val:IThresholdAdapter) :void {
			if (this.bVerbose) {
				trace("[FLARManager] threshold adapter: "+ flash.utils.getQualifiedClassName(val));
			}
			this._trackerManager.thresholdAdapter = val;
		}
		
		/**
		 * The amount of blur applied to the source image
		 * before sending to tracker for image analysis / object detection.
		 * Higher values may increase framerate, but may also reduce detection accuracy.
		 * <p>
		 * Value must be zero or greater.
		 * The default value is <code>2</code>.
		 * </p>
		 */
		public function get sampleBlurring () :int {
			return this._sampleBlurring;
		}
		public function set sampleBlurring (val:int) :void {
			if (!this.sampleBlurFilter) {
				this.sampleBlurFilter = new BlurFilter();
			}
			
			if (val <= 0) {
				val = 0;
				this.sampleBlurFilter.blurX = this.sampleBlurFilter.blurY = 0;
			} else {
				this.sampleBlurFilter.blurX = this.sampleBlurFilter.blurY = Math.pow(2, val-1);
			}
			
			this._sampleBlurring = val;
			
			if (this.bVerbose) {
				trace("[FLARManager] sample blurring: "+ val);
			}
		}
		
		/**
		 * Set to <code>true</code> to detect inverted (white border) markers.
		 * <p>
		 * If inverted has not yet been set to true in this session,
		 * there will be a slight delay before inverted becomes true,
		 * while the inversion shader is loaded.
		 * </p>
		 * <p>
		 * Thanks to <a href="http://jamesalliban.wordpress.com/">Jim Alliban</a>
		 * and <a href="http://theflashblog.com/">Lee Brimelow</a> for the inversion algorithm.
		 * </p>
		 */
		public function get inverted () :Boolean {
			return this._inverted;
		}
		public function set inverted (val:Boolean) :void {
			if (val && !this._inverted && !this.inversionShaderFilter) {
				this.initInversionShader();
				return;
			}
			
			if (this.bVerbose) {
				trace("[FLARManager] inverted: "+ val);
			}
			this._inverted = val;
		}
		
		/**
		 * Set to <code>true</code> to flip the camera image horizontally;
		 * this value is passed on to <code>this.flarSource</code>.
		 * <p>
		 * Note that if an IFLARSource is specified after mirrorDisplay is set,
		 * the <code>mirrored</code> property of the new IFLARSource will overwrite this value.
		 * </p> 
		 */
		public function get mirrorDisplay () :Boolean {
			return this._mirrorDisplay;
		}
		public function set mirrorDisplay (val:Boolean) :void {
			if (this.bVerbose) {
				trace("[FLARManager] mirror display: "+ val);
			}
			
			this._mirrorDisplay = val;
			if (this.flarSource) {
				this.flarSource.mirrored = this._mirrorDisplay;
			}
		}
		
		/**
		 * If a detected marker is within this distance (pixels) from an active marker,
		 * FLARManager considers the detected marker to be an update of the active marker.
		 * Else, the detected marker is a new marker.
		 * <p>
		 * Increase this value to accommodate faster-moving markers;
		 * Decrease it to accommodate more markers on-screen at once.
		 * </p>
		 */
		public function get markerUpdateThreshold () :Number {
			return this._markerUpdateThreshold;
		}
		public function set markerUpdateThreshold (val:Number) :void {
			if (this.bVerbose) {
				trace("[FLARManager] marker update threshold: "+ val);
			}
			this._markerUpdateThreshold = val;
		}
		
		/**
		 * Number of frames after removal that a marker will persist before dispatching a <code>MARKER_REMOVED</code> event.
		 * <p>
		 * If a marker of the same pattern appears within <code>markerUpdateThreshold</code> pixels
		 * of the point of removal, before <code>markerRemovalDelay</code> frames have elapsed,
		 * the marker will be reinstated as if it was never removed.
		 * </p>
		 * <p>
		 * The default value is <code>1</code>.
		 * </p>
		 */
		public function get markerRemovalDelay () :int {
			return this._markerRemovalDelay;
		}
		public function set markerRemovalDelay (val:int) :void {
			if (this.bVerbose) {
				trace("[FLARManager] marker removal delay: "+ val);
			}
			this._markerRemovalDelay = val;
		}
		
		/**
		 * If <code>true</code>, FLARManager will extrapolate the position of a FLARMarker from its velocity when last detected.
		 * <p>
		 * Extrapolation continues until markerRemovalDelay frames after <code>trackerManager</code> reports a marker removed.
		 * </p>
		 * <p>
		 * Enabling <code>markerExtrapolation</code> can sometimes improve tracking during fast marker motion.
		 * </p>
		 */
		public function get markerExtrapolation () :Boolean {
			return this._markerExtrapolation;
		}
		public function set markerExtrapolation (val:Boolean) :void {
			if (this.bVerbose) {
				trace("[FLARManager] marker extrapolation: "+ (val ? "ON" : "OFF"));
			}
			this._markerExtrapolation = val;
		}
		
		/**
		 * Apply a smoothing algorithm to transformation matrices generated by <code>trackerManager</code>.
		 * <p>
		 * <code>smoothing</code> is equal to the number of frames over which FLARManager
		 * will average transformation matrices; the larger the number, the smoother the animation,
		 * and the slower the response time between marker position/orientation changes.
		 * </p>
		 * <p>
		 * A value of <code>0</code> turns smoothing off.
		 * </p>
		 */ 
		public function get smoothing () :int {
			return this._smoothing;
		}
		public function set smoothing (val:int) :void {
			if (this.bVerbose) {
				trace("[FLARManager] smoothing: "+ val);
			}
			this._smoothing = val;
		}
		
		/**
		 * IFLARMatrixSmoother to use to apply smoothing to transformation matrices generated by <code>trackerManager</code>.
		 */
		public function get smoother () :IFLARMatrixSmoother {
			return this._smoother;
		}
		public function set smoother (val:IFLARMatrixSmoother) :void {
			if (this.bVerbose) {
				trace("[FLARManager] smoother "+ flash.utils.getQualifiedClassName(val));
			}
			this._smoother = val;
		}
		
		/**
		 * Adaptive smoothing reduces jitter in marker transformation matrices for markers with
		 * little motion, while maintaining responsiveness for markers with fast motion.
		 * <p>
		 * <code>adaptiveSmoothingCenter</code> is the marker motion distance (between current and last frame)
		 * at which the actual applied smoothing is equal to <code>FLARManager.smoothing</code>.
		 * </p>
		 * <p>
		 * When a marker has moved less than <code>adaptiveSmoothingCenter</code>, smoothing increases;
		 * When a marker has moved more than <code>adaptiveSmoothingCenter</code>, smoothing decreases.
		 * </p> 
		 */
		public function get adaptiveSmoothingCenter () :Number {
			return this._adaptiveSmoothingCenter;
		}
		public function set adaptiveSmoothingCenter (val:Number) :void {
			if (this.bVerbose) {
				trace("[FLARManager] adaptive smoothing center: "+ val);
			}
			this._adaptiveSmoothingCenter = val;
		}
		//-----<END CONFIG ACCESSORS>--------------------------------//
		
		
		
		//-----<OTHER ACCESSORS>-------------------------------------//
		/**
		 * String id of layer of FLARManager that interfaces with the selected tracking library.
		 */  
		public function get trackerId () :String {
			return this._trackerManager.id;
		}
		/**
		 * The layer of FLARManager that interfaces with the selected tracking library.
		 * Exposed here to grant developers access to more control over tracker library parameters.
		 */  
		public function get trackerManager () :IFLARTrackerManager {
			return this._trackerManager;
		}
		
		/**
		 * Get tracker projection matrix.
		 * Used to init cameras for 3D frameworks.
		 * 
		 * @param	frameworkId		ID of the selected 3D framework, enumerated in FLARManager.
		 * @param	viewportSize	Rectangle that describes bounds of 3D viewport.
		 */
		public function getProjectionMatrix (frameworkId:int, viewportSize:Rectangle) :Matrix3D {
			return this._trackerManager.getProjectionMatrix(frameworkId, viewportSize);
		}
		
		/**
		 * IFLARSource instance FLARManager is using as the source image for marker detection.
		 */
		public function get flarSource () :IFLARSource {
			return this._flarSource;
		}
		
		/**
		 * Reference to FLARCameraSource used in this application.
		 * If this application does not use a camera, returns null.
		 */
		public function get flarCameraSource () :FLARCameraSource {
			return this._flarSource as FLARCameraSource;
		}
		
		/**
		 * Vector of all currently-active markers.
		 */
		public function get activeMarkers () :Vector.<FLARMarker> {
			return this._activeMarkers;
		}
		
		/**
		 * <code>true</code> if this FLARManager instance is active and currently performing marker detection.
		 */
		public function get isActive () :Boolean {
			return this.bActive;
		}
		public function set isActive (val:Boolean) :void {
			trace("[FLARManager] "+ (val ? "activated" : "deactivated"));
			
			if (val) {
				this.activate();
			} else {
				this.deactivate();
			}
		}
		
		/**
		 * If <code>true</code>, FLARManager will output configuration changes to the console.
		 */
		public function get verbose () :Boolean {
			return this.bVerbose;
		}
		public function set verbose (val:Boolean) :void {
			this.bVerbose = val;
			trace("[FLARManager] verbosity "+ (val ? "ON" : "OFF"));
		}
		
		/**
		 * Current version of FLARManager.
		 */
		public function get version () :String {
			return "1.0.0";
		}
		//-----<END OTHER ACCESSORS>---------------------------------//
		
		
		
		//-----<PUBLIC METHODS>----------------------------//
		/**
		 * Begin detecting markers once per frame.
		 * This method is called automatically on initialization.
		 * 
		 * @return	<code>false</code> if FLARManager is not yet initialized; else <code>true</code>.
		 */
		public function activate () :Boolean {
			if (!this.bInited) { return false; }
			if (this.bActive) { return true; }
			this.bActive = true;
			
			if (this._flarSource is FLARProxy) {
				// activate FLARProxy
				var flarProxy:FLARProxy = this._flarSource as FLARProxy;
				flarProxy.activate();
				flarProxy.addEventListener(FLARMarkerEvent.MARKER_ADDED, this.onProxyMarkerAdded);
				flarProxy.addEventListener(FLARMarkerEvent.MARKER_UPDATED, this.onProxyMarkerUpdated);
				flarProxy.addEventListener(FLARMarkerEvent.MARKER_REMOVED, this.onProxyMarkerRemoved);
			} else {
				// activate normally
				if (!this.enterframer) {
					this.enterframer = new Sprite();
				}
				this.enterframer.removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
				this.enterframer.addEventListener(Event.ENTER_FRAME, this.onEnterFrame, false, 0, true);
			}
			
			this._activeMarkers = new Vector.<FLARMarker>();
			this.markersPendingRemoval = new Vector.<FLARMarker>();
			
			if (Sprite(this._flarSource).stage) {
				Sprite(this._flarSource).stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onDebugKeyDown);
			}
			
			return true;
		}
		
		/**
		 * Stop detecting markers.
		 * Removes all currently-active markers.
		 * <code>ENTER_FRAME</code> loop continues, to update video.
		 */
		public function deactivate () :void {
			if (!this.bActive) {
				return;
			}
			this.bActive = false;
			
			if (this._flarSource is FLARProxy) {
				// deactivate FLARProxy
				var flarProxy:FLARProxy = this._flarSource as FLARProxy;
				flarProxy.deactivate();
				flarProxy.addEventListener(FLARMarkerEvent.MARKER_ADDED, this.onProxyMarkerAdded);
				flarProxy.addEventListener(FLARMarkerEvent.MARKER_UPDATED, this.onProxyMarkerUpdated);
				flarProxy.addEventListener(FLARMarkerEvent.MARKER_REMOVED, this.onProxyMarkerRemoved);
			}
			
			if (this._activeMarkers) {
				var i:int = this._activeMarkers.length;
				while (i--) {
					// remove all active markers
					this.removeMarker(this._activeMarkers[i]);
				}
				this._activeMarkers = null;
			}
			
			if (this.markersPendingRemoval) {
				i = this.markersPendingRemoval.length;
				while (i--) {
					this.markersPendingRemoval[i].dispose();
				}
				this.markersPendingRemoval = null;
			}
			
			if (Sprite(this._flarSource).stage) {
				Sprite(this._flarSource).stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onDebugKeyDown);
			}
		}
		
		/**
		 * Halts all processes and frees this instance for garbage collection.
		 */
		public function dispose () :void {
			this.deactivate();
			
			this.disposeConfigLoader();
			
			this.enterframer.removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
			this.enterframer = null;
			
			this._flarSource.dispose();
			var flarSourceDO:DisplayObject = this._flarSource as DisplayObject;
			if (flarSourceDO && flarSourceDO.parent) {
				flarSourceDO.parent.removeChild(flarSourceDO);
			}
			this._flarSource = null;
			
			this._smoother = null;
			
			this.sampleBlurFilter = null;
			
			this._trackerManager.dispose();
			this._trackerManager = null;
		}
		//-----<END PUBLIC METHODS>---------------------------//
		
		
		
		//-----<MARKER DETECTION>----------------------------//
		private function onEnterFrame (evt:Event) :void {
			if (!this.updateSource()) { return; }
			
			if (!this.bActive) { return; }
			
			this.ageRemovedMarkers();
			this.performSourceAdjustments();
			this.detectMarkers();
		}
		
		private function updateSource () :Boolean {
			// TODO: _trackerManager must check that BitmapData source is instantiated...
			if (!this.flarSource.source) {
				return false;
			}
			
			// update source image
			this.flarSource.update();
			return true;
		}
		
		private function ageRemovedMarkers () :void {
			// remove all markers older than this.markerRemovalDelay.
			var i:uint = this.markersPendingRemoval.length;
			var removedMarker:FLARMarker;
			while (i--) {
				removedMarker = this.markersPendingRemoval[i];
				if (removedMarker.ageAfterRemoval() > this.markerRemovalDelay) {
					this.removeMarker(removedMarker);
				}
			}
		}
		
		private function performSourceAdjustments () :void {
			this._trackerManager.performSourceAdjustments();
			
			if (this.sampleBlurring > 0) {
				// apply blur filter to combine and reduce number of black areas in image to be labeled.
				this.flarSource.source.applyFilter(this.flarSource.source, this.flarSource.sourceSize, ZERO_POINT, this.sampleBlurFilter);
			}
			
			if (this._inverted) {
				this.flarSource.source.applyFilter(this.flarSource.source, this.flarSource.sourceSize, ZERO_POINT, this.inversionShaderFilter);
			}
		}
		
		private function detectMarkers () :void {
			var detectedMarkers:Vector.<FLARMarker> = this._trackerManager.detectMarkers();
			if (!detectedMarkers) {
				// error in processing
				return;
			}
			
			var i:uint;
			if (detectedMarkers.length == 0) {
				// if no markers found, remove any existing markers and exit
				i = this._activeMarkers.length;
				while (i--) {
					this.queueMarkerForRemoval(this._activeMarkers[i]);
				}
				return;
			}
			
			// compare detected markers against active markers
			i = detectedMarkers.length;
			var j:uint, k:uint;
			var activeMarker:FLARMarker;
			var detectedMarker:FLARMarker;
			var closestMarker:FLARMarker;
			var closestDist:Number = Number.POSITIVE_INFINITY;
			var dist:Number;
			var updatedMarkers:Vector.<FLARMarker> = new Vector.<FLARMarker>();
			var newMarkers:Vector.<FLARMarker> = new Vector.<FLARMarker>();
			var removedMarker:FLARMarker;
			var bRemovedMarkerMatched:Boolean = false;
			while (i--) {
				j = this._activeMarkers.length;
				detectedMarker = detectedMarkers[i];
				closestMarker = null;
				closestDist = Number.POSITIVE_INFINITY;
				while (j--) {
					activeMarker = this._activeMarkers[j];
					if (detectedMarker.patternId == activeMarker.patternId) {
						dist = Point.distance(detectedMarker.centerpoint3D, activeMarker.targetCenterpoint3D);
						if (dist < closestDist && dist < this._markerUpdateThreshold) {
							closestMarker = activeMarker;
							closestDist = dist;
						}
					}
				}
				
				if (closestMarker) {
					// updated marker
					closestMarker.copy(detectedMarker);
					detectedMarker.dispose();
					if (this._smoothing) {
						if (!this._smoother) {
							// TODO: log as a WARN-level error
							trace("no smoother set; specify FLARManager.smoother to enable smoothing."); 
						} else {
							closestMarker.applySmoothing(this._smoother, this._smoothing, this._adaptiveSmoothingCenter);
						}
					}
					updatedMarkers.push(closestMarker);
					
					// if closestMarker is pending removal, restore it.
					k = this.markersPendingRemoval.length;
					while (k--) {
						if (this.markersPendingRemoval[k] == closestMarker) {
							closestMarker.resetRemovalAge();
							this.markersPendingRemoval.splice(k, 1);
						}
					}
					
					this.dispatchEvent(new FLARMarkerEvent(FLARMarkerEvent.MARKER_UPDATED, closestMarker));
				} else {
					// new marker
					newMarkers.push(detectedMarker);
					detectedMarker.setSessionId();
					this.dispatchEvent(new FLARMarkerEvent(FLARMarkerEvent.MARKER_ADDED, detectedMarker));
				}
			}
			
			i = this._activeMarkers.length;
			while (i--) {
				activeMarker = this._activeMarkers[i];
				if (updatedMarkers.indexOf(activeMarker) == -1) {
					// if activeMarker was not updated, queue it for removal.
					this.queueMarkerForRemoval(activeMarker);
				}
			}
			
			this._activeMarkers = this._activeMarkers.concat(newMarkers);
		}
		
		private function queueMarkerForRemoval (marker:FLARMarker) :void {
			if (this.markersPendingRemoval.indexOf(marker) == -1) {
				this.markersPendingRemoval.push(marker);
			}
		}
		
		private function removeMarker (marker:FLARMarker) :void {
			var i:uint = this._activeMarkers.indexOf(marker);
			if (i >= 0) {
				this._activeMarkers.splice(i, 1);
			}
			
			i = this.markersPendingRemoval.indexOf(marker);
			if (i >= 0) {
				this.markersPendingRemoval.splice(i, 1);
			}
			
			this.dispatchEvent(new FLARMarkerEvent(FLARMarkerEvent.MARKER_REMOVED, marker));
			marker.dispose();
		}
		
		private function onProxyMarkerAdded (evt:FLARMarkerEvent) :void {
			this.dispatchEvent(evt);
		}
		
		private function onProxyMarkerUpdated (evt:FLARMarkerEvent) :void {
			this.dispatchEvent(evt);
		}
		
		private function onProxyMarkerRemoved (evt:FLARMarkerEvent) :void {
			this.dispatchEvent(evt);
		}
		//-----<END MARKER DETECTION>---------------------------//
		
		
		
		//-----<INITIALIZATION>----------------------------//
		private function initConfigLoader () :void {
			this.configLoader = new FLARManagerConfigLoader();
			this.configLoader.addEventListener(ErrorEvent.ERROR, this.onConfigLoadError);
			this.configLoader.addEventListener(FLARManagerConfigLoader.CONFIG_FILE_LOADED, this.onConfigLoaded);
			this.configLoader.addEventListener(FLARManagerConfigLoader.CONFIG_FILE_PARSED, this.onConfigParsed);
		}
		
		private function disposeConfigLoader () :void {
			if (!this.configLoader) { return; }
			
			this.configLoader.removeEventListener(ErrorEvent.ERROR, this.onConfigLoadError);
			this.configLoader.removeEventListener(FLARManagerConfigLoader.CONFIG_FILE_LOADED, this.onConfigLoaded);
			this.configLoader.removeEventListener(FLARManagerConfigLoader.CONFIG_FILE_PARSED, this.onConfigParsed);
			
			this.configLoader.dispose();
			this.configLoader = null;
		}
		
		private function onConfigLoaded (evt:Event) :void {
			if (this.bVerbose) {
				trace("[FLARManager] config file loaded.");
			}
		}
		
		private function onConfigLoadError (evt:ErrorEvent) :void {
			this.dispatchEvent(evt);
		}
		
		private function onConfigParsed (evt:Event) :void {
			if (this.bVerbose) {
				trace("[FLARManager] config file parsed.");
			}
			
			this.configLoader.harvestConfig(this);
			this.init();
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function init () :void {
			this.initFlarSource();
			
			this._trackerManager.addEventListener(Event.INIT, this.onTrackerInited);
			this._trackerManager.loadTrackerConfig(this.configLoader);
			
			// initialize sampleBlurFilter
			this.sampleBlurring = this.sampleBlurring;
		}
		
		private function initFlarSource () :void {
			var sourceParent:DisplayObjectContainer;
			var sourceAsSprite:Sprite;
			var sourceIndex:int;
			if (this._flarSource) {
				if (this._flarSource.inited) {
					// do not attempt to init if source was inited before passing into FLARManager ctor.
					return;
				}
				
				sourceAsSprite = this._flarSource as Sprite;
				sourceParent = sourceAsSprite.parent;
			}
			
			if (this.configLoader.useProxy) {
				if (sourceParent) {
					// if placeholder IFLARSource was already added to the display list, remove it...
					sourceIndex = sourceParent.getChildIndex(sourceAsSprite);
					sourceParent.removeChild(sourceAsSprite);
				}
				
				this._flarSource = new FLARProxy(this.configLoader.displayWidth, this.configLoader.displayHeight);
				
				if (sourceParent) {
					// ...and replace it with the new FLARLoaderSource.
					sourceParent.addChildAt(Sprite(this._flarSource), sourceIndex);
				}
			} else if (this.configLoader.loaderPath) {
				if (sourceParent) {
					// if placeholder IFLARSource was already added to the display list, remove it...
					sourceIndex = sourceParent.getChildIndex(sourceAsSprite);
					sourceParent.removeChild(sourceAsSprite);
				}
				
				this._flarSource = new FLARLoaderSource(
					this.configLoader.loaderPath, this.configLoader.sourceWidth,
					this.configLoader.sourceHeight, this.configLoader.trackerToSourceRatio);
				
				if (sourceParent) {
					// ...and replace it with the new FLARLoaderSource.
					sourceParent.addChildAt(Sprite(this._flarSource), sourceIndex);
				}
			} else {
				FLARCameraSource(this._flarSource).addEventListener(ErrorEvent.ERROR, this.onCameraSourceError);
				FLARCameraSource(this._flarSource).init(
					this.configLoader.sourceWidth, this.configLoader.sourceHeight,
					this.configLoader.framerate, this._mirrorDisplay,
					this.configLoader.displayWidth, this.configLoader.displayHeight,
					this.configLoader.trackerToSourceRatio);
			}
		}
		
		private function onCameraSourceError (evt:ErrorEvent) :void {
			this.deactivate();
			this.dispatchEvent(evt);
		}
		
		private function onTrackerInited (evt:Event) :void {
			this.trackerManager.removeEventListener(Event.INIT, this.onTrackerInited);
			this.trackerManager.addEventListener(Event.COMPLETE, this.onTrackerComplete);
			this.trackerManager.addEventListener(ErrorEvent.ERROR, this.onTrackerComplete);
			
			this._trackerManager.trackerSource = this.flarSource;
			this._trackerManager.initTracker(this.stage);
		}
		
		private function onTrackerComplete (evt:Event) :void {
			this.trackerManager.removeEventListener(Event.COMPLETE, this.onTrackerComplete);
			this.trackerManager.removeEventListener(ErrorEvent.ERROR, this.onTrackerComplete);
			
			if (evt is ErrorEvent) {
				throw new Error(ErrorEvent(evt).text);
			}
			
			if (!this.smoother) {
				this.smoother = new FLARMatrixSmoother_Average();
			}
			
			this.bInited = true;
			this.activate();
			
			this.dispatchEvent(new Event(Event.INIT));
		}
		
		private function onDebugKeyDown (evt:KeyboardEvent) :void {
			if (evt.altKey && evt.ctrlKey && evt.keyCode == 86) {
				Sprite(this._flarSource).contextMenu = new ContextMenu();
				ContextMenu(Sprite(this._flarSource).contextMenu).customItems.push(new ContextMenuItem("[FLARManager "+ this.version +"]", true, false, true));
				trace("[FLARManager "+ this.version +"]");
			}
		}
		
		private function initInversionShader () :void {
			var inversionShaderLoader:URLLoader = new URLLoader();
			inversionShaderLoader.dataFormat = URLLoaderDataFormat.BINARY;
			inversionShaderLoader.addEventListener(Event.COMPLETE, this.onInversionShaderLoaded);
			inversionShaderLoader.addEventListener(ErrorEvent.ERROR, this.onInversionShaderLoadError);
			inversionShaderLoader.load(new URLRequest("../resources/flar/invert.pbj"));
		}
		
		private function onInversionShaderLoadError (evt:ErrorEvent) :void {
			this.onInversionShaderLoaded(evt);
		}
		
		private function onInversionShaderLoaded (evt:Event, errorEvent:ErrorEvent=null) :void {
			var inversionShaderLoader:URLLoader = URLLoader(evt.target);
			if (!inversionShaderLoader) { return; }
			inversionShaderLoader.removeEventListener(Event.COMPLETE, this.onInversionShaderLoaded);
			inversionShaderLoader.removeEventListener(ErrorEvent.ERROR, this.onInversionShaderLoadError);
			
			if (errorEvent) {
				throw new Error("invert.pbj not found in ../resources/flar/.");
			}
			
			var inversionShader:Shader = new Shader(inversionShaderLoader.data);
			this.inversionShaderFilter = new ShaderFilter(inversionShader);
			
			this.inverted = true;
		}
		//-----<END INITIALIZATION>---------------------------//
	}
}