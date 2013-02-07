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
package com.transmote.flar.marker {
	import flash.events.Event;

	/**
	 * FLARMarkerEvents contain detected FLARManager markers,
	 * and are dispatched by FLARManager.
	 *  
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARMarkerEvent extends Event {
		public static const MARKER_ADDED:String = "markerAdded";
		public static const MARKER_UPDATED:String = "markerUpdated";
		public static const MARKER_REMOVED:String = "markerRemoved";
		
		private var _marker:FLARMarker;
		
		/**
		 * Constructor.
		 * @param	type	Event type.
		 * @param	marker	A reference to the detected marker.
		 */
		public function FLARMarkerEvent (type:String, marker:FLARMarker, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
			this._marker = marker;
		}
		
		/**
		 * A reference to the detected marker.
		 */
		public function get marker () :FLARMarker {
			return this._marker;
		}
		
		public override function clone () :Event {
			return new FLARMarkerEvent(this.type, this.marker, this.bubbles, this.cancelable);
		}
	}
}