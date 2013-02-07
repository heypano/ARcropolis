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
	import at.imagination.flare.FlareNFT;
	
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.flarManagerInternal;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.utils.FLARManagerConfigLoader;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	use namespace flarManagerInternal;
	
	/**
	 * Tracker library manager for use with FlareNFT.
	 * Pass a FlareNFTManager instance into the FLARManager constructor
	 * in order to use FLARManager with FlareNFT.
	 *  
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FlareNFTManager extends FlareManager {
		private var featureSetFile:String;
		private var framerate:Number = 30;
		private var multiTargets:Boolean;
		
		public function FlareNFTManager () {
			super();
		}
		
		/**
		 * The string id of this tracker manager.
		 * All tracker manager ids are enumerated in FLARManager.as.
		 */
		public override function get id () :String {
			return FLARManager.TRACKER_ID_FLARE_NFT;
		}
		
		/**
		 * flare*NFT does not support multiple marker types.
		 */
		public override function addMarkerDetector (markerType:int, param1:Number=NaN, param2:Number=NaN) :Boolean {
			trace("flareNFT does not support multiple tracker types.");
			return false;
		}
		
		/*
		// not yet implemented by flare.
		public override function removeMarkerDetector (markerType:int) :void {
			trace("flareNFT does not support multiple tracker types.");
			return false;
		}
		*/
		
		/**
		 * Load configuration data for the tracker, including camera parameters.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	configLoader	The FLARManagerConfigLoader instance with loaded configuration data.
		 */
		public override function loadTrackerConfig (configLoader:FLARManagerConfigLoader) :void {
			super.loadTrackerConfig(configLoader);
			
			this.featureSetFile = configLoader.flareNFT_featureSetFile;
			if (configLoader.flareNFT_framerate) {
				this.framerate = configLoader.flareNFT_framerate;
			}
			this.multiTargets = configLoader.flareNFT_multiTargets;
		}
		
		/**
		 * Initialize the tracker.
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 * 
		 * @param	stage	A reference to the application's Stage.
		 */
		public override function initTracker (stage:Stage=null) :void {
			if (!stage) {
				throw new Error("FlareNFT requires a Stage reference.");
			}
			
			this.markerDetector = new FlareNFT();
			FlareNFT(this.markerDetector).init(
				stage, this.resourcesPath, this.cameraParamsFile,
				this.flarSource.sourceSize.width, this.flarSource.sourceSize.height,
				this.framerate, this.featureSetFile, this.multiTargets, this.onTrackerComplete)
		}
		
		/**
		 * @private
		 */
		public override function onTrackerComplete () :void {
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * Instruct the tracker to detect objects (e.g. markers, patterns, images).
		 * This method is called automatically by FLARManager;
		 * application developers should not call this method.
		 */
		public override function detectMarkers () :Vector.<FLARMarker> {
			var numFoundMarkers:uint = this.markerDetector.update(this.flarSource.source);
			if (numFoundMarkers == 0) {
				return new Vector.<FLARMarker>();
			}
			
			return this.parseMarkers(numFoundMarkers);
		}
	}
}