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
package com.transmote.flar.source {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	/**
	 * Use the contents of a <code>Loader</code> as a source image for tracker target detection.
	 * FLARLoaderSource samples the contents of a <code>Loader</code> against a white background,
	 * to provide maximum contrast for marker detection.
	 * This class can be used for testing marker detection without a camera,
	 * for example with a swf or jpeg with valid patterns within.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARLoaderSource extends Sprite implements IFLARSource {
		private var _trackerToDisplayRatio:Number;
		
		private var loader:Loader;
		private var trackerToSourceRatio:Number;
		
		private var displayWidth:Number;
		private var displayHeight:Number;
		private var displayBmpData:BitmapData;
		private var displayBitmap:Bitmap;
		private var displayMatrix:Matrix;
		
		private var sampleWidth:Number;
		private var sampleHeight:Number;
		private var sampleBmpData:BitmapData;
		private var sampleBitmap:Bitmap;
		private var sampleMatrix:Matrix;
		private var sampleMatRect:Rectangle;	// area of sampleBmpData to fill with a white background before sending to FLARToolkit 
		
		
		/**
		 * Constructor.
		 * 
		 * @param	contentPath				Filename to load.
		 * @param	displayWidth			Width at which to display video.
		 * @param	displayHeight			Height at which to display video.
		 * @param	trackerToSourceRatio	Amount to downsample camera input.
		 *									The captured video is scaled down by this value
		 * 									before being sent to tracker for analysis.  
		 * 									Trackers run faster with more downsampling,
		 * 									but also have more difficulty recognizing marker patterns and targets.
		 * 									A value of <code>1.0</code> results in no downsampling;
		 * 									A value of <code>0.5</code> (the default) downsamples the camera input by half.
		 */
		public function FLARLoaderSource (contentPath:String, displayWidth:Number, displayHeight:Number, trackerToSourceRatio:Number=0.5) {
			this.trackerToSourceRatio = trackerToSourceRatio;
			
			this.displayWidth = displayWidth;
			this.displayHeight = displayHeight;
			this.sampleWidth = this.displayWidth * this.trackerToSourceRatio;
			this.sampleHeight = this.displayHeight * this.trackerToSourceRatio;
			
			this._trackerToDisplayRatio = this.sampleWidth / this.displayWidth;
			this.sampleMatRect = new Rectangle(0, 0, this.sampleWidth, this.sampleHeight);
			
			this.loadContent(contentPath);
		}
		
		/**
		 * Update the <code>BitmapData</code> source used for analysis.
		 */
		public function update () :void {
			this.displayBmpData.draw(this.loader, this.displayMatrix);
			
			this.sampleBmpData.fillRect(this.sampleMatRect, 0xFFFFFFFF);
			this.sampleBmpData.draw(this.loader, this.sampleMatrix);
		}
		
		/**
		 * Retrieve the BitmapData source used for analysis.
		 * NOTE: returns the actual BitmapData object, not a clone.
		 */
		public function get source () :BitmapData {
			return this.sampleBmpData;
		}
		
		/**
		 * Size of BitmapData source used for analysis.
		 */
		public function get sourceSize () :Rectangle {
			return new Rectangle(0, 0, this.sampleWidth, this.sampleHeight);
		}
		
		/**
		 * Ratio of area of tracker's reported results to display size.
		 * Use to scale (multiply) results of tracker analysis to correctly fit display area.
		 */
		public function get trackerToDisplayRatio () :Number {
			return this._trackerToDisplayRatio;
		}
		
		/**
		 * FLARLoaderSource cannot be mirrored;
		 * method is here only for compliance with IFLARSource.
		 */
		public function get mirrored () :Boolean {
			return false;
		}
		public function set mirrored (val:Boolean) :void {}
		
		/**
		 * Returns <code>true</code> if initialization is complete.
		 * FLARLoaderSource is inited automatically in constructor.
		 */
		public function get inited () :Boolean {
			return true;
		}
		
		/**
		 * Halts all processes and frees this instance for garbage collection.
		 */
		public function dispose () :void {
			this.loader.unloadAndStop();
			
			this.displayBmpData.dispose();
			this.displayBmpData = null;
			this.displayBitmap = null;
			this.displayMatrix = null;
			
			this.sampleBmpData.dispose();
			this.sampleBmpData = null;
			this.sampleBitmap = null;
			this.sampleMatrix = null;
		}
		
		private function loadContent (path:String) :void {
			this.loader = new Loader();
			this.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.onLoadError, false, 0, true);
			this.loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onLoadError, false, 0, true);
			this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onLoaded, false, 0, true);
			this.loader.load(new URLRequest(path));
		}
		
		private function onLoadError (evt:Event) :void {
			var errorText:String = "FLARLoaderSource load error.";
			if (evt is IOErrorEvent) {
				errorText = IOErrorEvent(evt).text;
			} else if (evt is SecurityErrorEvent) {
				errorText = SecurityErrorEvent(evt).text;
			}
			
			this.onLoaded(evt, new Error(errorText));
		}
		
		private function onLoaded (evt:Event, error:Error=null) :void {
			var loaderInfo:LoaderInfo = evt.target as LoaderInfo;
			
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, this.onLoadError);
			loaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onLoadError);
			loaderInfo.removeEventListener(Event.COMPLETE, this.onLoaded);
			
			if (error) { throw error; }
			
			// BitmapData downsampled from source video, sent to FLARToolkit every frame
			this.sampleBmpData = new BitmapData(this.sampleWidth, this.sampleHeight, false, 0);
			this.sampleBitmap = new Bitmap(this.sampleBmpData);
			this.sampleBitmap.width = this.displayWidth;
			this.sampleBitmap.height = this.displayHeight;
			
			// cropped, full-res video displayed on-screen
			this.displayBmpData = new BitmapData(this.displayWidth, this.displayHeight, false, 0);
			this.displayBitmap = new Bitmap(this.displayBmpData);
			
			// full-res Bitmap for display
			this.addChild(this.displayBitmap);
			
			// uncomment to view downsampled BitmapData sent to FLARToolkit
//			this.addChild(this.sampleBitmap);
			
			this.buildSampleMatrices();
			
			this.dispatchEvent(new Event(Event.INIT));
		}
		
		private function buildSampleMatrices () :void {
			// construct transformation matrix used when updating displayed video
			// and when updating BitmapData source for FLARToolkit
			this.displayMatrix = new Matrix(1, 0, 0, 1);
			this.sampleMatrix = new Matrix(
				this._trackerToDisplayRatio, 0,
				0, this._trackerToDisplayRatio);
		}
	}
}