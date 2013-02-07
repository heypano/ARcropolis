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
	import __AS3__.vec.Vector;
	
	import com.transmote.flar.flarManagerInternal;
	import com.transmote.flar.source.IFLARSource;
	import com.transmote.flar.utils.geom.FLARGeomUtils;
	import com.transmote.flar.utils.smoother.IFLARMatrixSmoother;
	
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	/**
	 * Container for information about a detected marker, including:
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
	public class FLARMarker {
		public static const DEFAULT_UNSCALED_MARKER_WIDTH:Number = 80;
		private static const MAX_ADAPTIVE_SMOOTHING:Number = 15;
		private static const LOW_SPEED_EXPONENT:Number = 1.25;
		private static const HIGH_SPEED_EXPONENT:Number = 0.75;
		private static var sessionIdCounter:uint = 0;
		
		internal var _sessionId:int = -1;
		internal var _patternId:int;
		internal var _flarSource:IFLARSource;
		internal var _transformMatrix:Matrix3D;
		
		internal var _centerpoint2D:Point = null;
		internal var _centerpoint3D:Point = null;
		internal var _vector3D:Vector3D = null;
		
		protected var _corners:Vector.<Point>;
		private var _velocity:Vector3D;
		private var rotations:Vector3D;
		private var rotationSpeeds:Vector3D;
		
		private var removalAge:uint = 0;
		private var screenCenter:Point;
		private var matrixHistory:Vector.<Matrix3D>;
		
		/**
		 * Constructor.
		 * @param	patternId			ID of the pattern of the detected marker.
		 * @param	transformMatrix		A Matrix3D object that describes the orientation of the detected marker relative to the viewer.
		 * 								Apply this Matrix3D to a 3D model to make it appear tethered to the marker.
		 * @param	flarSource			The IFLARSource from which the marker's image was extracted by the current tracker.
		 */
		public function FLARMarker (patternId:int, transformMatrix:Matrix3D, flarSource:IFLARSource) {
			this._patternId = patternId;
			this._transformMatrix = transformMatrix;
			this._flarSource = flarSource;
			this._velocity = new Vector3D();
			
			if (this._flarSource.mirrored) {
				this.mirror();
			}
			
			this.screenCenter = new Point(0.5*this._flarSource.sourceSize.width, 0.5*this._flarSource.sourceSize.height);
		}
		
		
		//-----<ACCESSORS: MARKER METADATA>--------------------------//
		/**
		 * ID unique to this FLARMarker in this session.
		 * No two FLARMarker in a session share the same sessionId.
		 */
		public function get sessionId () :uint {
			return this._sessionId;
		}
		
		/**
		 * ID of this FLARMarker's pattern.
		 */
		public function get patternId () :int {
			return this._patternId;
		}
		//-----<END ACCESSORS: MARKER METADATA>----------------------//
		
		
		
		//-----<ACCESSORS: MARKER POSITION AND ORIENTATION>----------//
		/**
		 * A Matrix3D object that describes the orientation of the detected marker relative to the viewer.
		 * Apply this Matrix3D to a 3D model to make it appear tethered to the marker.
		 */
		public function get transformMatrix () :Matrix3D {
			return this._transformMatrix;
		}
		
		/**
		 * Return the transformation matrix of this FLARMarker as a Flash Matrix object,
		 * for applying 2D transformations to Flash DisplayObject instances.
		 * To apply to a DisplayObject, set <code>displayObject.transform.matrix = flarMarker.matrix2D</code>.
		 */
		public function get matrix2D () :Matrix {
			var matrix:Matrix = new Matrix();
			var rotation:Number = Math.atan2(this.transformMatrix.rawData[4], this.transformMatrix.rawData[5]);
			if (this._flarSource.mirrored) { rotation = 2*Math.PI - rotation; }
			
			matrix.translate(-0.5*DEFAULT_UNSCALED_MARKER_WIDTH, -0.5*DEFAULT_UNSCALED_MARKER_WIDTH);
			matrix.rotate(rotation);
			matrix.scale(this.scale2D, this.scale2D);
			matrix.translate(this.x, this.y);
			
			return matrix;
		}
		
		/**
		 * Return this.transformMatrix, adjusted for application directly to a DisplayObject
		 * (by setting <code>displayObject.transform.matrix3D = flarMarker.matrix3D</code>).
		 */
		public function get matrix3D () :Matrix3D {
			var matrix3D:Matrix3D = this.transformMatrix.clone();
			matrix3D.prependTranslation(-0.5*DEFAULT_UNSCALED_MARKER_WIDTH, -0.5*DEFAULT_UNSCALED_MARKER_WIDTH, 0);
			matrix3D.appendTranslation(this.x, this.y, 0);
			return matrix3D;
		}
		
		/**
		 * The 2D X coordinate of the marker.
		 */
		public function get x () :Number {
			return this.centerpoint.x;
			
			// x position reported by this._transformMatrix is subject to z position
			// (distance from camera) and is relative to (0,0) instead of screen center.
			//return this._transformMatrix.rawData[12];
		}
		
		/**
		 * The 2D Y coordinate of the marker.
		 */
		public function get y () :Number {
			return this.centerpoint.y;
			
			// y position reported by this._transformMatrix is subject to z position
			// (distance from camera) and is relative to (0,0) instead of screen center.
			//return this._transformMatrix.rawData[13];
		}
		
		/**
		 * The Z coordinate of the marker.
		 */
		public function get z () :Number {
			return this._transformMatrix.rawData[14];
		}
		
		/**
		 * The centerpoint of the marker outline in the 2D space of the screen,
		 * calculated as the average of the outline's four corner points.
		 * To access the centerpoint reported by the tracker in three dimensions,
		 * use <code>FLARMarker.centerpoint3D</code>.
		 */
		public function get centerpoint () :Point {
			if (!this._centerpoint2D) {
				this._centerpoint2D = this.calcCenterpoint2D();
			}
			return this._centerpoint2D;
		}
		
		/**
		 * Centerpoint of marker outline extracted from the tracker transformation matrix.
		 * This centerpoint is determined based on the 3D location of the detected marker,
		 * and is used by FLARManager in 3D calculations.
		 * To avoid having to correct for Z location, use <code>centerpoint2D</code>.
		 * 
		 * TODO: return a Vector3D with (x,y,z) coords.
		 * 		 update accordingly in FLARManager.
		 */
		public function get centerpoint3D () :Point {
			if (!this._centerpoint3D) {
				this._centerpoint3D = this.calcCenterpoint3D(this._transformMatrix);
			}
			return this._centerpoint3D;
		}
		
		/**
		 * The centerpoint at the location toward which this FLARMarker is moving
		 * (target location at end of smoothing animation).
		 * 
		 * TODO: return a Vector3D with (x,y,z) coords.
		 * 		 update accordingly in FLARManager.
		 */
		public function get targetCenterpoint3D () :Point {
			if (!this.matrixHistory) {
				return this.centerpoint3D;
			}
			
			// find most recent stored transformation matrix
			var i:int = this.matrixHistory.length - 1;
			while (this.matrixHistory[i] == null) {
				i--;
				if (i == -1) {
					return this.centerpoint3D;
				}
			}
						
			return this.calcCenterpoint3D(this.matrixHistory[i]);
		}
		
		/**
		 * A Vector3D instance that describes x, y, and z coordinates,
		 * as well as rotationZ (stored as <code>position.w</code>).
		 */
		public function get position () :Vector3D {
			if (!this.rotations) {
				this.rotations = FLARGeomUtils.calcMatrix3DRotations(this._transformMatrix, true, this._flarSource.mirrored);
			}
			var position:Vector3D = this._transformMatrix.position.clone();
			position.w = this.rotations.z;
			return position;
		}
		
		/**
		 * The rotation of the marker along X axis.
		 */
		public function get rotationX () :Number {
			if (!this.rotations) {
				this.rotations = FLARGeomUtils.calcMatrix3DRotations(this._transformMatrix, true, this._flarSource.mirrored);
			}
			return this.rotations.x;
		}
		
		/**
		 * The rotation of the marker along Y axis.
		 */
		public function get rotationY () :Number {
			if (!this.rotations) {
				this.rotations = FLARGeomUtils.calcMatrix3DRotations(this._transformMatrix, true, this._flarSource.mirrored);
			}
			return this.rotations.y;
		}
		
		/**
		 * The rotation of the marker along Z axis.
		 */
		public function get rotationZ () :Number {
			if (!this.rotations) {
				this.rotations = FLARGeomUtils.calcMatrix3DRotations(this._transformMatrix, true, this._flarSource.mirrored);
			}
			return this.rotations.z;
		}
		
		/**
		 * A Vector of four Points that describe the four points of the detected marker's outline.
		 */
		public function get corners () :Vector.<Point> {
			return this._corners;
		}
		
		/**
		 * The scale of the marker for use in 2D applications.
		 */
		public function get scale2D () :Number {
			var diag1:Number = Point.distance(this.corners[0], this.corners[2]);
			var diag2:Number = Point.distance(this.corners[1], this.corners[3]);
			var size:Number = Math.sqrt(0.25 * (diag1*diag1 + diag2*diag2));
			return (size / DEFAULT_UNSCALED_MARKER_WIDTH);
		}
		
		/**
		 * The position toward which this FLARMarker is moving
		 * (target position at end of smoothing animation).
		 */
		public function get targetPosition () :Vector3D {
			if (!this.matrixHistory) {
				return this._transformMatrix.position;
			}
			
			// find most recent stored transform matrix
			var i:int = this.matrixHistory.length - 1;
			while (this.matrixHistory[i] == null) {
				i--;
				if (i == -1) {
					return this._transformMatrix.position;
				}
			}
						
			return this.matrixHistory[i].position;
		}
		//-----<ACCESSORS: MARKER POSITION AND ORIENTATION>----------//
		
		
		
		//-----<ACCESSORS: MARKER MOTION>----------------------------//
		/**
		 * A Vector3D instance that describes change between the previous and current frames
		 * in x, y, and z coordinates, as well as change in rotationZ (stored as <code>velocity.w</code>).
		 */
		public function get velocity () :Vector3D {
			return this._velocity;
		}
		
		/**
		 * The length of the marker's (x,y) motion vector
		 * between the previous and current frames.
		 */
		public function get motionSpeed2D () :Number {
			return Math.sqrt(this._velocity.x*this._velocity.x + this._velocity.y*this._velocity.y);
		}
		
		/**
		 * The direction (in degrees) of the marker's (x,y) motion
		 * between the previous and current frames.
		 */
		public function get motionDirection2D () :Number {
			return 180 * Math.atan2(this._velocity.y, this._velocity.x) / Math.PI;
		}
		
		/**
		 * The amount of change (in degrees) in the marker's rotation along the x-axis
		 * between the previous and current frames.
		 */
		public function get rotationSpeedX () :Number {
			return this.rotationSpeeds.x;
		}
		
		/**
		 * The amount of change (in degrees) in the marker's rotation along the y-axis
		 * between the previous and current frames.
		 */
		public function get rotationSpeedY () :Number {
			return this.rotationSpeeds.y;
		}
		
		/**
		 * The amount of change (in degrees) in the marker's rotation along the z-axis
		 * between the previous and current frames.
		 */
		public function get rotationSpeedZ () :Number {
			return this.rotationSpeeds.z;
		}
		//-----<END ACCESSORS: MARKER MOTION>------------------------//
		
		
		
		//-----<PUBLIC METHODS>--------------------------------------//
		/**
		 * Copy the properties of a FLARMarker into this FLARMarker.
		 * FLARMarkers are updated across frames by copying the properties of newly-detected markers.
		 */
		public function copy (otherMarker:FLARMarker) :void {
			this.calcRotationSpeeds(otherMarker);
			this.calcVelocity(otherMarker);
			
			this._patternId = otherMarker._patternId;
			this._transformMatrix = otherMarker._transformMatrix;
			this._flarSource = otherMarker._flarSource;
			this._corners = otherMarker._corners;
			
			this.resetAllCalculations();
		}
		
		/**
		 * Free this FLARMarker instance for garbage collection.
		 */
		public function dispose () :void {
			this._transformMatrix = null;
			this._flarSource = null;
			this.matrixHistory = null;
			this._vector3D = null;
			this.rotations = null;
			this.rotationSpeeds = null;
			this._corners = null;
			this._velocity = null;
		}
		
		public function toString () :String {
			return ("FLARMarker [patternId:"+ this.patternId +", sessionId:"+ this.sessionId +"]");
		}
		//-----<END PUBLIC METHODS>----------------------------------//
		
		
		
		//-----<flarManagerInternal METHODS>-------------------------//
		/**
		 * apply smoothing algorithm over a number of frames.
		 * called by FLARManager as part of marker tracking/maintenance process.
		 * 
		 * @param	smoother	IFLARMatrixSmoother to use
		 * @param	numFrames	number of frames over which to smooth
		 * @param	adaptiveSmoothingCenter		@see com.transmote.flar.FLARManager#adaptiveSmoothingCenter
		 */
		flarManagerInternal function applySmoothing (smoother:IFLARMatrixSmoother, numFrames:int, adaptiveSmoothingCenter:Number) :void {
			if (adaptiveSmoothingCenter > 0) {
				numFrames = this.adaptSmoothing(numFrames, adaptiveSmoothingCenter);
			}
			
			if (numFrames == 0) {
				this.matrixHistory = null;
				return;
			}
			
			if (!this.matrixHistory) {
				this.matrixHistory = new Vector.<Matrix3D>(numFrames, false);
			} else if (this.matrixHistory.length != numFrames) {
				// remove null values from array before changing size,
				// to insure no information is lost.
				var i:int = this.matrixHistory.length;
				var j:int;
				while (i-- > 0) {
					if (this.matrixHistory[i] != null) { continue; }
					j = i;
					while (j--) {
						if (this.matrixHistory[j] != null || j==-1) { break; }
					}
					this.matrixHistory.splice(j+1, i-j);
					i = j;
				}
				
				this.matrixHistory.length = numFrames;
			}
			
			for (i=0; i<numFrames-1; i++) {
				if (this.matrixHistory[i+1]) {
					// only copy non-null matrices, to avoid discarding matrices with data.
					this.matrixHistory[i] = this.matrixHistory[i+1];
				}
			}
			this.matrixHistory[i] = this._transformMatrix;
			
			this._transformMatrix = smoother.smoothMatrices(this.matrixHistory);
		}
		
		flarManagerInternal function setSessionId () :void {
			// called only by FLARManager, when a new FLARMarker is detected.
			if (this._sessionId == -1) {
				this._sessionId = FLARMarker.sessionIdCounter++;
			}
		}
		
		flarManagerInternal function resetRemovalAge () :void {
			// removal age is the number of frames that have elapsed
			// since this FLARMarker was last detected by the tracker.
			this.removalAge = 0;
		}
		
		flarManagerInternal function ageAfterRemoval () :uint {
			// removal age is the number of frames that have elapsed
			// since this FLARMarker was last detected by the tracker.
			// also extrapolates marker velocity to approximate new location.
			this.removalAge++;
			this._transformMatrix.rawData[3] += this.velocity.x;
			this._transformMatrix.rawData[7] += this.velocity.y;
			this._transformMatrix.rawData[11] += this.velocity.z;
			return this.removalAge;
		}
		//-----<END flarManagerInternal METHODS>---------------------//
		
		
		
		//-----<PROTECTED/PRIVATE METHODS>---------------------------//
		protected function resetAllCalculations () :void {
			this._centerpoint2D = null;
			this._centerpoint3D = null;
			this._vector3D = null;
			this.rotations = null;
		}
		
		protected function mirror () :void {
			// TODO: this method currently has no effect.
			//		 however, should be able to mirror this.transformMatrix,
			//		 and never have to worry about mirroring in application code
			//		 or in XGeomUtils classes.
//			this._transformMatrix.rawData[3] = this._flarSource.sourceSize.width - this._transformMatrix.rawData[3];
		}
		
		private function adaptSmoothing (numFrames:int, adaptiveSmoothingCenter:Number) :int {
			// evaluate marker speeds ((x,y,z) and rotationX/Y/Z) against adaptiveSmoothingCenter.
			// if speed is less, apply more smoothing; if speed is more, apply less smoothing.
			// choose lowest amount smoothing from four results, to ensure responsiveness during motion.
			var speeds:Vector.<Number> = Vector.<Number>([this.motionSpeed2D, this.velocity.z, this.rotationSpeeds.x, this.rotationSpeeds.y, this.rotationSpeeds.z]);
			speeds.fixed = true;
			var speed:Number;
			var smoothing:Number;
			var leastSmoothing:Number = MAX_ADAPTIVE_SMOOTHING;
			for (var i:int=0; i<speeds.length; i++) {
				speed = Math.abs(speeds[i]);
				if (speed < adaptiveSmoothingCenter) {
					smoothing = numFrames + Math.pow((adaptiveSmoothingCenter-speed), LOW_SPEED_EXPONENT);
					smoothing = Math.min(MAX_ADAPTIVE_SMOOTHING, smoothing);
				} else {
					smoothing = numFrames - Math.pow((speed-adaptiveSmoothingCenter), HIGH_SPEED_EXPONENT);
					smoothing = Math.max(0, smoothing);
				}
				
				leastSmoothing = Math.min(smoothing, leastSmoothing);
			}
			/*
			var speedsStr:String = "";
			for (i=0; i<speeds.length; i++) { 
				speedsStr += Math.floor(Math.abs(speeds[i])) +" ";
			}
			trace("speeds:"+speedsStr+" | smoothing:"+Math.floor(leastSmoothing));
			*/
			return Math.floor(leastSmoothing);
		}
		
		private function calcCenterpoint2D () :Point {
			var x:Number = 0;
			var y:Number = 0;
			var i:int = 4;
			while (i--) {
				x += this.corners[i].x;
				y += this.corners[i].y;
			}
			return new Point(0.25*x, 0.25*y);
		}
		
		private function calcCenterpoint3D (matrix:Matrix3D) :Point {
			var centerPt:Point = new Point(this.screenCenter.x + matrix.rawData[12], this.screenCenter.y + matrix.rawData[13]);
			centerPt.x /= this._flarSource.trackerToDisplayRatio;
			centerPt.y /= this._flarSource.trackerToDisplayRatio;
			return centerPt;
		}
		
		private function calcRotationSpeeds (newMarker:FLARMarker) :void {
			var dRotX:Number = newMarker.rotationX - this.rotationX;
			if (dRotX > 180) { dRotX -= 360; }
			else if (dRotX < -180) { dRotX += 360; }
			var dRotY:Number = newMarker.rotationY - this.rotationY;
			if (dRotY > 180) { dRotY -= 360; }
			else if (dRotY < -180) { dRotY += 360; }
			var dRotZ:Number = newMarker.rotationZ - this.rotationZ;
			if (dRotZ > 180) { dRotZ -= 360; }
			else if (dRotZ < -180) { dRotZ += 360; }
			
			this.rotationSpeeds = new Vector3D(
				dRotX,
				dRotY,
				dRotZ,
				0
			);
		}
		
		private function calcVelocity (newMarker:FLARMarker) :void {
			this._velocity = new Vector3D(newMarker.x-this.x, newMarker.y-this.y, newMarker.z-this.z, this.rotationSpeeds.z);
		}
		//-----<END PROTECTED/PRIVATE METHODS>-----------------------//
	}
}