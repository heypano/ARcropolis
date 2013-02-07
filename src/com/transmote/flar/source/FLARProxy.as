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
	import com.transmote.flar.flarManagerInternal;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FLARMarkerEvent;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	use namespace flarManagerInternal;
	
	/**
	 * FLARProxy provides a way to test FLARToolkit applications with a mouse and keyboard.
	 * To use, add <code>useProxy='true'</code> to the <code>flarSourceSettings</code> node in your configuration XML file.
	 * Since FLARProxy responds to mouse interaction, it must be added to the display list
	 * in order to capture mouse interaction and dispatch FLARMarkerEvents.
	 * <p>
	 * Clicking the mouse sends a <code>MARKER_ADDED</code> event,
	 * dragging the mouse sends a <code>MARKER_UPDATED</code> event,
	 * and releasing the mouse sends a <code>MARKER_REMOVED</code> event.
	 * These events can be handled exactly as if they were dispatched by FLARManager.
	 * </p>
	 * <p>
	 * Press keys 0-9 to specify a <code>patternId</code>.
	 * FLARProxy only supports <code>patternIds</code> 0 through 9.
	 * </p>
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */ 
	public class FLARProxy extends Sprite implements IFLARSource {
		private static const MAX_NUMBER_MARKERS:uint = 10;
		
		private var mouseArea:Sprite;
		private var mouseIsDown:Boolean;
		private var activePatternId:uint = 0;
		private var activeMarkers:Vector.<FLARMarker>;
		
		private var bLoadingCameraParams:Boolean = false;
		private var bActivatePending:Boolean = false;
		
		
		/**
		 * Constructor.
		 * 
		 * @param	displayWidth			Width of active area.
		 * @param	displayHeight			Height of active area.
		 */
		public function FLARProxy (displayWidth:Number, displayHeight:Number) {
			this.initMouseArea(displayWidth, displayHeight);
			this.activeMarkers = new Vector.<FLARMarker>(MAX_NUMBER_MARKERS, true);
		}
		
		/**
		 * Activate marker simulation.
		 */
		public function activate () :void {
			if (this.stage) {
				this.mouseArea.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown, false, 0, true);
				this.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown, false, 0, true);
				this.mouseArea.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp, false, 0, true);
			} else {
				this.addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage, false, 0, true);
			}
		}
		
		/**
		 * Deactivate marker simulation.
		 */
		public function deactivate () :void {
			if (this.stage) {
				this.mouseArea.removeEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
				this.mouseArea.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
				this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
			}
			
			if (this.activeMarkers) {
				var i:int = this.activeMarkers.length;
				while (i--) {
					// remove all active markers
					this.activeMarkers[i].dispose();
				}
				this.activeMarkers = null;
			}
		}
		
		/**
		 * FLARProxy updates on mouse interaction;
		 * method is here only for compliance with IFLARSource.
		 */
		public function update () :void {}
		
		/**
		 * FLARProxy has no BitmapData source;
		 * method is here only for compliance with IFLARSource.
		 */
		public function get source () :BitmapData {
			return null;
		}
		
		/**
		 * Size of BitmapData source used for analysis.
		 */
		public function get sourceSize () :Rectangle {
			return new Rectangle(0, 0, this.mouseArea.width, this.mouseArea.height);
		}
		
		/**
		 * Ratio of area of tracker's reported results to display size.
		 * Use to scale (multiply) results of tracker analysis to correctly fit display area.
		 * FLARProxy always uses the whole screen size, so this method returns 1.0.
		 */
		public function get trackerToDisplayRatio () :Number {
			return 1.0;
		}
		
		/**
		 * FLARProxy cannot be mirrored;
		 * method is here only for compliance with IFLARSource.
		 */
		public function get mirrored () :Boolean {
			return false;
		}
		public function set mirrored (val:Boolean) :void {}
		
		/**
		 * Returns <code>true</code> if initialization is complete.
		 * FLARProxy is inited automatically in constructor.
		 */
		public function get inited () :Boolean {
			return true;
		}
		
		/**
		 * Halts all processes and frees this instance for garbage collection.
		 */
		public function dispose () :void {
			this.deactivate();
		}
		
		private function initMouseArea (displayWidth:Number, displayHeight:Number) :void {
			this.mouseArea = new Sprite();
			this.mouseArea.graphics.beginFill(0, 0);
			this.mouseArea.graphics.drawRect(0, 0, displayWidth, displayHeight);
			this.mouseArea.graphics.endFill();
			this.addChild(this.mouseArea);
		}
		
		private function onAddedToStage (evt:Event) :void {
			this.removeEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
			this.addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage, false, 0, true);
			this.activate();
		}
		
		private function onRemovedFromStage (evt:Event) :void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
			this.deactivate();
		}
		
		private function addMarker (patternId:uint, x:Number, y:Number) :void {
			var proxyResult:ProxyResult = new ProxyResult(patternId, x, y, this.mouseArea);
			var proxyMarker:FLARMarker = new FLARMarker(proxyResult.patternId, proxyResult.transformMatrix, this);
			proxyMarker.setSessionId();
			this.activeMarkers[patternId] = proxyMarker;
			this.dispatchEvent(new FLARMarkerEvent(FLARMarkerEvent.MARKER_ADDED, proxyMarker));
		}
		
		private function updateMarker (patternId:uint, x:Number, y:Number) :void {
			var proxyMarker:FLARMarker = this.activeMarkers[patternId];
			if (!proxyMarker) { return; }
			
			var proxyResult:ProxyResult = new ProxyResult(patternId, x, y, this.mouseArea);
			var updatedMarker:FLARMarker = new FLARMarker(proxyResult.patternId, proxyResult.transformMatrix, null);
			proxyMarker.copy(updatedMarker);
			this.dispatchEvent(new FLARMarkerEvent(FLARMarkerEvent.MARKER_UPDATED, proxyMarker));
		}
		
		private function removeMarker (patternId:uint, x:Number, y:Number) :void {
			var proxyMarker:FLARMarker = this.activeMarkers[patternId];
			if (!proxyMarker) { return; }
			
			var proxyResult:ProxyResult = new ProxyResult(patternId, x, y, this.mouseArea);
			var removedMarker:FLARMarker = new FLARMarker(proxyResult.patternId, proxyResult.transformMatrix, null);
			proxyMarker.copy(removedMarker);
			this.activeMarkers[patternId] = null;
			this.dispatchEvent(new FLARMarkerEvent(FLARMarkerEvent.MARKER_REMOVED, proxyMarker));
		}
		
		private function onMouseDown (evt:MouseEvent) :void {
			this.mouseArea.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove);
			this.mouseIsDown = true;
			this.addMarker(this.activePatternId, evt.localX, evt.localY);
		}
		
		private function onMouseMove (evt:MouseEvent) :void {
			this.updateMarker(this.activePatternId, evt.localX, evt.localY);
		}
		
		private function onMouseUp (evt:MouseEvent) :void {
			this.mouseArea.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove);
			this.mouseIsDown = false;
			this.removeMarker(this.activePatternId, evt.localX, evt.localY);
		}
		
		private function onKeyDown (evt:KeyboardEvent) :void {
			var newPatternId:uint = evt.keyCode - 48;
			if (newPatternId == this.activePatternId || newPatternId < 0 || newPatternId > 9) { return; }
			
			trace("FLARProxy active patternId: "+ newPatternId);
			var lastPatternId:uint = this.activePatternId;
			this.activePatternId = newPatternId;
			
			if (this.mouseIsDown) {
				this.removeMarker(lastPatternId, this.mouseArea.mouseX, this.mouseArea.mouseY);
				this.addMarker(this.activePatternId, this.mouseArea.mouseX, this.mouseArea.mouseY);
			}
		}
	}
}


import com.transmote.flar.pattern.FLARPattern;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import com.transmote.flar.marker.FLARMarker;
	
class ProxyResult {
	private static const MARKER_CORNER_VAL:Number = 0.5 * FLARMarker.DEFAULT_UNSCALED_MARKER_WIDTH;
	private static const DEFAULT_MARKER_Z:Number = 400;
	
	public var patternId:int;
	public var corners:Vector.<Point>;
	public var transformMatrix:Matrix3D;
	
	public function ProxyResult (patternId:int, x:Number, y:Number, mouseArea:Sprite) {
		this.patternId = patternId;
		
		this.corners = Vector.<Point>([
			new Point(x-MARKER_CORNER_VAL, y-MARKER_CORNER_VAL),
			new Point(x+MARKER_CORNER_VAL, y-MARKER_CORNER_VAL),
			new Point(x+MARKER_CORNER_VAL, y+MARKER_CORNER_VAL),
			new Point(x-MARKER_CORNER_VAL, y+MARKER_CORNER_VAL)]);
		
		this.transformMatrix = new Matrix3D();
		this.transformMatrix.position = new Vector3D(x-0.5*mouseArea.width, y-0.5*mouseArea.height, DEFAULT_MARKER_Z);
	}
}