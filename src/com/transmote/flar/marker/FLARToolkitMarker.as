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
package com.transmote.flar.marker {
	import __AS3__.vec.Vector;
	
	import com.transmote.flar.pattern.FLARPattern;
	import com.transmote.flar.source.IFLARSource;
	
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	
	import jp.nyatla.nyartoolkit.as3.core.squaredetect.NyARSquare;
	import jp.nyatla.nyartoolkit.as3.core.types.NyARDoublePoint2d;
	import jp.nyatla.nyartoolkit.as3.core.types.NyARLinear;
	
	/**
	 * Container for information about a marker detected by FLARToolkit, including:
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
	public class FLARToolkitMarker extends FLARMarker {
		internal var _confidence:Number;
		internal var _direction:int;
		internal var _flarSquare:NyARSquare;
		internal var _flarPattern:FLARPattern;
		
		/**
		 * Constructor.
		 * 
		 * @param	transformMatrix		A Matrix3D object that describes the orientation of the detected marker relative to the viewer.
		 * 								Apply this Matrix3D to a 3D model to make it appear tethered to the marker.
		 * @param	flarSource			The IFLARSource from which the marker's image was extracted by the current tracker.
		 * @param	flarPattern			The FLARPattern that represents the detected marker's pattern.
		 * @param	patternId			ID of the pattern of the detected marker.
		 * @param	direction			The closest orthographic orientation of detected marker (up/down/left/right).
		 * @param	square				The NyARSquare instance used to create this FLARMarker instance.
		 * @param	confidence			The value assigned by FLARToolkit to each detected marker.
		 */
		public function FLARToolkitMarker (
			transformMatrix:Matrix3D, flarSource:IFLARSource, flarPattern:FLARPattern,
			patternId:int, direction:int, square:NyARSquare, confidence:Number) {
			
			this._direction = direction;
			this._flarSquare = square;
			this._confidence = confidence;
			this._flarPattern = flarPattern;
			
			super(patternId, transformMatrix, flarSource);
			
			this.calcCorners();
		}
		
		
		//-----<ACCESSORS>-------------------------------------------//
		/**
		 * 'Confidence' is a value assigned by FLARToolkit to each detected marker,
		 * that describes the algorithm's perceived accuracy of the pattern match.
		 */
		public function get confidence () :Number {
			return this._confidence;
		}
	
		/**
		 * The closest orthographic orientation of detected marker.
		 * value between 0 and 3, inclusive:
		 * 0: up
		 * 1: left
		 * 2: down
		 * 3: right
		 */
		public function get direction () :int {
			return this._direction;
		}
		
		/**
		 * The NyARSquare instance used to create this FLARMarker instance.
		 * Can be accessed if direct access to FLARToolkit output is desired;
		 * no downsampling correction is applied.
		 */
		public function get flarSquare () :NyARSquare {
			return this._flarSquare;
		}
		//-----<END: ACCESSORS>--------------------------------------//
		
		
		
		//-----<PUBLIC METHODS>--------------------------------------//
		/**
		 * Copy the properties of a FLARMarker into this FLARMarker.
		 * FLARMarkers are updated across frames by
		 * copying the properties of newly-detected markers.
		 */
		public override function copy (otherMarker:FLARMarker) :void {
			super.copy(otherMarker);
			
			var otherFLARToolkitMarker:FLARToolkitMarker = otherMarker as FLARToolkitMarker;
			if (otherFLARToolkitMarker) {
				this._direction = otherFLARToolkitMarker._direction;
				this._flarSquare = otherFLARToolkitMarker._flarSquare;
				this._confidence = otherFLARToolkitMarker._confidence;
				this._flarPattern = otherFLARToolkitMarker._flarPattern;
				
			}
		}
		
		/**
		 * Free this FLARMarker instance up for garbage collection.
		 */
		public override function dispose () :void {
			super.dispose();
			this._flarSquare = null;
			this._flarPattern = null;
		}
		//-----<END PUBLIC METHODS>----------------------------------//
		
		
		
		//-----<PROTECTED/PRIVATE METHODS>---------------------------//
		protected override function resetAllCalculations () :void {
			super.resetAllCalculations();
			this.calcCorners();
		}
		
		protected override function mirror () :void {
			super.mirror();
			
			const sourceWidth:Number = this._flarSource.sourceSize.width;
			
			// mirror FLARSquare
			var i:int = 4;
			var flarCorner:NyARDoublePoint2d;
			var flarLine:NyARLinear;
			while (i--) {
				flarCorner = NyARDoublePoint2d(this.flarSquare.sqvertex[i]);
				flarCorner.x = sourceWidth - flarCorner.x;
				
				// NOTE: flarLine mirroring is untested.
				flarLine = NyARLinear(this.flarSquare.line[i]);
				flarLine.dx *= -1;
			}
		}
		
		private function calcCorners () :void {
			this._corners = new Vector.<Point>(4);
			var i:int = 4;
			var flarCorner:NyARDoublePoint2d;
			while (i--) {
				flarCorner = NyARDoublePoint2d(this.flarSquare.sqvertex[i]);
				this._corners[i] = new Point(flarCorner.x / this._flarSource.trackerToDisplayRatio, flarCorner.y / this._flarSource.trackerToDisplayRatio);
			}
		}
		//-----<END PROTECTED/PRIVATE METHODS>-----------------------//
	}
}