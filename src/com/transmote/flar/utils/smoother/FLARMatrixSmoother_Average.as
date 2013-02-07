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
package com.transmote.flar.utils.smoother {
	import com.transmote.flar.utils.geom.FLARGeomUtils;
	
	import flash.geom.Matrix3D;
	
	/**
	 * Averages a number of previous matrices to smooth motion of a model.
	 * Angle and position can be smoothed different amounts,
	 * by setting positionToRotationRatio.
	 * 
	 * Includes code based on <a href="http://www.moment77.se/dagbok/alchemy-and-flarmanager/">work by Anders Gunnarsson</a>.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARMatrixSmoother_Average implements IFLARMatrixSmoother {
		private var _positionToRotationRatio:Number = 0.5;
		
		
		public function FLARMatrixSmoother_Average() {}
		
		/**
		 * Init from a name-value paired object that contains parameters parsed from XML.
		 */
		public function initFromXML (paramsObj:Object) :void {
			if (!isNaN(paramsObj.positionToRotationRatio)) {
				this.positionToRotationRatio = parseFloat(paramsObj.positionToRotationRatio);
			}
		}
		
		/**
		 * Amount of position (x,y,z) smoothing relative to the
		 * amount of rotation (x,y,z axes) smoothing.
		 * Set either via ActionScript or flarConfig.xml.
		 * Defaults to 0.5 (position is smoothed half as much as rotation).
		 */
		public function get positionToRotationRatio () :Number {
			return this._positionToRotationRatio;
		}
		public function set positionToRotationRatio (val:Number) :void {
			this._positionToRotationRatio = Math.max(0, Math.min(val, 1));
		}
		
		/**
		 * Returns a Matrix3D that is the average of a Vector of Matrix3D instances.
		 * 
		 * @param	storedMatrices	Vector of stored matrices to average.  (<code>storedMatrices</code> is not modified.)
		 */
		public function smoothMatrices (storedMatrices:Vector.<Matrix3D>) :Matrix3D {
			var smoothedMatrix:Matrix3D = new Matrix3D();
			var storedMatrix:Matrix3D;
			var smoothedRawData:Vector.<Number> = Vector.<Number>([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
			var storedRawData:Vector.<Number>;
			
			var numStoredMatrices:int = 0;	// number of non-null matrices in storedMatrices
			var i:int = storedMatrices.length;
			
			// smooth angles
			while (i--) {
				storedMatrix = storedMatrices[i];
				if (!storedMatrix) { continue; }
				storedRawData = storedMatrix.rawData;
				
				smoothedRawData[0] += storedRawData[0];
				smoothedRawData[1] += storedRawData[1];
				smoothedRawData[2] += storedRawData[2];
				smoothedRawData[3] += storedRawData[3];
				smoothedRawData[4] += storedRawData[4];
				smoothedRawData[5] += storedRawData[5];
				smoothedRawData[6] += storedRawData[6];
				smoothedRawData[7] += storedRawData[7];
				smoothedRawData[8] += storedRawData[8];
				smoothedRawData[9] += storedRawData[9];
				smoothedRawData[10] += storedRawData[10];
				smoothedRawData[11] += storedRawData[11];
				
				numStoredMatrices++;
			}
			
			// smooth positions (after determining how many valid matrices are available)
			var numPositionsToAverage:int = Math.floor(numStoredMatrices * this._positionToRotationRatio) + 1;
			numPositionsToAverage = Math.min(1, numPositionsToAverage);		// always add in at least one position
			var numPositionsAveraged:int = 0;
			i = storedMatrices.length;
			while (i--) {
				storedMatrix = storedMatrices[i];
				if (!storedMatrix) { continue; }
				storedRawData = storedMatrix.rawData;
				
				smoothedRawData[12] += storedRawData[12];
				smoothedRawData[13] += storedRawData[13];
				smoothedRawData[14] += storedRawData[14];
				smoothedRawData[15] += storedRawData[15];
				
				if (++numPositionsAveraged >= numPositionsToAverage) {
					break;
				}
			}
			
			if (numStoredMatrices == 0) {
				return new Matrix3D();
			}
			
			smoothedRawData[0] /= numStoredMatrices;
			smoothedRawData[1] /= numStoredMatrices;
			smoothedRawData[2] /= numStoredMatrices;
			smoothedRawData[3] /= numStoredMatrices;
			smoothedRawData[4] /= numStoredMatrices;
			smoothedRawData[5] /= numStoredMatrices;
			smoothedRawData[6] /= numStoredMatrices;
			smoothedRawData[7] /= numStoredMatrices;
			smoothedRawData[8] /= numStoredMatrices;
			smoothedRawData[9] /= numStoredMatrices;
			smoothedRawData[10] /= numStoredMatrices;
			smoothedRawData[11] /= numStoredMatrices;
			smoothedRawData[12] /= numPositionsAveraged;
			smoothedRawData[13] /= numPositionsAveraged;
			smoothedRawData[14] /= numPositionsAveraged;
			smoothedRawData[15] /= numPositionsAveraged;
			
			smoothedMatrix.rawData = smoothedRawData;
			
			return smoothedMatrix;
		}
		
		/**
		 * Halts all processes and frees this instance for garbage collection.
		 */
		public function dispose () :void {
			//
		}
	}
}