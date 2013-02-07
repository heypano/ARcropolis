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
	import com.transmote.flar.source.IFLARSource;
	
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	
	/**
	 * Container for information about a marker detected by flare* or flare*NFT, including:
	 * <p>
	 * <ul>
	 * <li>pattern and session ids</li>
	 * <li>centerpoint of marker</li>
	 * <li>corners of marker outline</li>
	 * <li>Vector3D instance that describes x, y, and z location, and rotation (in the z-axis) of marker</li>
	 * <li>rotation of marker around x, y, and z axes</li>
	 * </ul>
	 * </p>
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar/
	 * @see		com.transmote.flar.marker.FLARMarkerEvent
	 */
	public class FlareMarker extends FLARMarker {
		private var _markerType:uint;
		private var _dataMatrixMessage:String;
		
		public function FlareMarker (patternId:int, transformMatrix:Matrix3D, flarSource:IFLARSource, corners:Vector.<Point>, markerType:uint, dataMatrixMessage:String) {
			super(patternId, transformMatrix, flarSource);
			this.calcCorners(corners);
			this._markerType = markerType;
			this._dataMatrixMessage = dataMatrixMessage;
		}
		
		/**
		 * The marker type, as enumerated by FlareDetector.
		 * 
		 * @see com.transmote.flar.tracker.FlareTracker#addMarkerDetector()
		 */
		public function get markerType () :uint {
			return this._markerType;
		}
		
		/**
		 * The string embedded within a DataMatrix marker.
		 * If the marker is not a DataMatrix marker, returns null.
		 * 
		 * @see com.transmote.flar.tracker.FlareTracker#dataMatrixMessage()
		 */
		public function get dataMatrixMessage () :String {
			return this._dataMatrixMessage;
		}
		
		private function calcCorners (corners:Vector.<Point>) :void {
			this._corners = new Vector.<Point>(4, true);
			if (corners) {
				// corners reported by FlareTracker.getTrackerResults2D()
				for (var i:int=0; i<4; i++) {
					this._corners[i] = new Point(corners[i].x / this._flarSource.trackerToDisplayRatio, corners[i].y / this._flarSource.trackerToDisplayRatio);
				}
			} else {
				// no 2D results, so create dummy corners
				for (i=0; i<4; i++) {
					this._corners[i] = new Point();
				}
			}
		}
	}
}