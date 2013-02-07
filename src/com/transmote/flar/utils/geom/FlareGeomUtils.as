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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	/**
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FlareGeomUtils {
		
		/**
		 * Convert Flare matrix data (ByteArray) to a Flash Matrix3D.
		 * 
		 * @param	matDataOut		Flare matrix data to convert.
		 * @param	bMirror			If <code>true</code>, this method will flip the resultant matrix horizontally (along the x-axis).
		 * @return					Matrix3D generated from the Flare matrix data.
		 */
		public static function convertFlareMatrixToFlashMatrix (matDataIn:ByteArray, bMirror:Boolean=true) :Matrix3D {
			var matrix:Matrix3D = new Matrix3D();
			var matDataOut:Vector.<Number> = new Vector.<Number>(16, true);
			
			if (bMirror) {
				matDataOut[0] = -matDataIn.readFloat();
				matDataOut[1] = matDataIn.readFloat();
				matDataOut[2] = matDataIn.readFloat();
				matDataOut[3] = matDataIn.readFloat();
				
				matDataOut[4] = -matDataIn.readFloat();
				matDataOut[5] = matDataIn.readFloat();
				matDataOut[6] = matDataIn.readFloat();
				matDataOut[7] = -matDataIn.readFloat();
				
				matDataOut[8] = matDataIn.readFloat();
				matDataOut[9] = -matDataIn.readFloat();
				matDataOut[10] = -matDataIn.readFloat();
				matDataOut[11] = -matDataIn.readFloat();
				
				matDataOut[12] = -matDataIn.readFloat();
				matDataOut[13] = matDataIn.readFloat();
				matDataOut[14] = matDataIn.readFloat();
				matDataOut[15] = matDataIn.readFloat();
			} else {
				matDataOut[0] = matDataIn.readFloat();
				matDataOut[1] = matDataIn.readFloat();
				matDataOut[2] = matDataIn.readFloat();
				matDataOut[3] = matDataIn.readFloat();
				
				matDataOut[4] = -matDataIn.readFloat();
				matDataOut[5] = -matDataIn.readFloat();
				matDataOut[6] = -matDataIn.readFloat();
				matDataOut[7] = -matDataIn.readFloat();
				
				matDataOut[8] = -matDataIn.readFloat();
				matDataOut[9] = -matDataIn.readFloat();
				matDataOut[10] = -matDataIn.readFloat();
				matDataOut[11] = -matDataIn.readFloat();
				
				matDataOut[12] = matDataIn.readFloat();
				matDataOut[13] = matDataIn.readFloat();
				matDataOut[14] = matDataIn.readFloat();
				matDataOut[15] = matDataIn.readFloat();
			}
			matrix.rawData = matDataOut;
			return matrix;
		}
		
		/**
		 * Convert Flare corner data (from FlareTracker.getTrackerResults2D)
		 * into a Vector of four Points.
		 * 
		 * @param	data2D					Flare corner data, with markerType and targetID removed
		 * @param	mirroredSourceWidth		Specify source width to perform mirroring. 
		 */
		public static function convertFlareData2D (data2D:ByteArray, mirroredSourceWidth:Number=0) :Vector.<Point> {
			var corners:Vector.<Point> = new Vector.<Point>(4, true);
			if (mirroredSourceWidth != 0) {
				corners[0] = new Point(mirroredSourceWidth-data2D.readFloat(), data2D.readFloat());
				corners[1] = new Point(mirroredSourceWidth-data2D.readFloat(), data2D.readFloat());
				corners[2] = new Point(mirroredSourceWidth-data2D.readFloat(), data2D.readFloat());
				corners[3] = new Point(mirroredSourceWidth-data2D.readFloat(), data2D.readFloat());
			} else {
				corners[0] = new Point(data2D.readFloat(), data2D.readFloat());
				corners[1] = new Point(data2D.readFloat(), data2D.readFloat());
				corners[2] = new Point(data2D.readFloat(), data2D.readFloat());
				corners[3] = new Point(data2D.readFloat(), data2D.readFloat());
			}
			return corners;
		}
		
		/**
		 * Convert Flare projection matrix to data that can be used
		 * by native Flash 3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 */
		public static function calcProjectionMatrix_Flash (projectionMatrix:Matrix3D, viewportSize:Rectangle) :Matrix3D {
			return projectionMatrix;
		}
		
		/**
		 * Convert Flare projection matrix to data that can be used
		 * by Alternativa to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * @throws	Error	Alternativa3D + flare* not yet supported as of FLARManager v1.0.
		 */
		public static function calcProjectionMatrix_Alternativa (projectionMatrix:Matrix3D, viewportSize:Rectangle) :Matrix3D {
			throw new Error("Alternativa3D not yet supported for Flare/NFT.");
		}
		
		/**
		 * Convert Flare projection matrix to data that can be used
		 * by Away3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * @throws	Error	Away3D + flare* not yet supported as of FLARManager v1.0.
		 */
		public static function calcProjectionMatrix_Away (projectionMatrix:Matrix3D, viewportSize:Rectangle, zoom:Number=10, focus:Number=100) :Matrix3D {
			throw new Error("Away3D not yet supported for Flare/NFT.");
		}
		
		/**
		 * Convert Flare projection matrix to data that can be used
		 * by Away3D Lite to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * @throws	Error	Away3D Lite + flare* not yet supported as of FLARManager v1.0.
		 */
		public static function calcProjectionMatrix_AwayLite (projectionMatrix:Matrix3D, viewportSize:Rectangle) :Matrix3D {
			throw new Error("Away3D Lite not yet supported for Flare/NFT.");
		}
		
		/**
		 * Convert Flare projection matrix to data that can be used
		 * by Papervision3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 */
		public static function calcProjectionMatrix_Papervision (projectionMatrix:Matrix3D, viewportSize:Rectangle) :Matrix3D {
			var raw:Vector.<Number> = projectionMatrix.rawData;
			var out:Matrix3D = new Matrix3D(Vector.<Number>([
				raw[4], raw[5], raw[6], raw[7],
				raw[0], raw[1], raw[2], raw[3],
				raw[8], raw[9], raw[10], raw[11],
				raw[12], raw[13], raw[14], raw[15]
			]));
			return out;
		}
		
		/**
		 * Convert Flare projection matrix to data that can be used
		 * by Sandy3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * @throws	Error	Sandy3D + flare* not yet supported as of FLARManager v1.0.
		 */
		public static function calcProjectionMatrix_Sandy (projectionMatrix:Matrix3D, viewportSize:Rectangle, NEAR_CLIP:Number=50, FAR_CLIP:Number=10000) :Matrix3D {
			throw new Error("Sandy3D not yet supported for Flare/NFT.");
		}
		
		public function FlareGeomUtils () {}

	}
}