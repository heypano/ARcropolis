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
package com.transmote.flar.utils.geom {
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	/**
	 * Collection of matrix transformation / conversion utils
	 * useful for object tracking and augmented reality applications.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARGeomUtils {
		private static const RADIANS_TO_DEGREES:Number = 180 / Math.PI;
		private static const DEGREES_TO_RADIANS:Number = Math.PI / 180;
		
		
		/**
		 * Calculate rotation around X, Y, and Z axes,
		 * and return stored in a Vector3D instance.
		 * NOTE: does not account for scale.
		 */
		public static function calcMatrix3DRotations (mat:Matrix3D, bInDegrees:Boolean=true, bMirrorHorizontal:Boolean=false) :Vector3D {
			const RADIANS_TO_DEGREES:Number = 180 / Math.PI;
			var rotations:Vector3D = new Vector3D();
			
			rotations.x = Math.asin(mat.rawData[6]);
			rotations.y = Math.atan2(-mat.rawData[2], mat.rawData[10]);
			rotations.z = Math.atan2(mat.rawData[4], mat.rawData[5]);
			if (bMirrorHorizontal) {
				rotations.z = 2*Math.PI - rotations.z;
			}
			
			if (bInDegrees) {
				rotations.x *= RADIANS_TO_DEGREES;
				rotations.y *= RADIANS_TO_DEGREES;
				rotations.z *= RADIANS_TO_DEGREES;
			}
			
			return rotations;
		}
		
		/**
		 * Format Flash matrix as a String.
		 * 
		 * @param	matrix	matrix to return as a String.
		 * @param	sd		number of significant digits to display.
		 */
		public static function dumpMatrix3D (matrix:Matrix3D, sd:int=4) :String {
			var m:Vector.<Number> = matrix.rawData;
			return (m[0].toFixed(sd) +"\u0009"+"\u0009"+ m[1].toFixed(sd) +"\u0009"+"\u0009"+ m[2].toFixed(sd) +"\u0009"+"\u0009"+ m[3].toFixed(sd) +"\n"+
					m[4].toFixed(sd) +"\u0009"+"\u0009"+ m[5].toFixed(sd) +"\u0009"+"\u0009"+ m[6].toFixed(sd) +"\u0009"+"\u0009"+ m[7].toFixed(sd) +"\n"+
					m[8].toFixed(sd) +"\u0009"+"\u0009"+ m[9].toFixed(sd) +"\u0009"+"\u0009"+ m[10].toFixed(sd) +"\u0009"+"\u0009"+ m[11].toFixed(sd) +"\n"+
					m[12].toFixed(sd) +"\u0009"+"\u0009"+ m[13].toFixed(sd) +"\u0009"+"\u0009"+ m[14].toFixed(sd) +"\u0009"+"\u0009"+ m[15].toFixed(sd));
		}
		
		public function FLARGeomUtils () {}
	}
}