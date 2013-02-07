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
	import __AS3__.vec.Vector;
	
	import flash.geom.Matrix3D;
	
	/**
	 * Interface that defines how classes used to smooth transformation matrices will interface with FLARManager. 
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public interface IFLARMatrixSmoother {
		/**
		 * Init from a name-value paired object that contains parameters parsed from XML.
		 */
		function initFromXML (paramsObj:Object) :void;
		
		/**
		 * Returns a Matrix3D that is the average of the last @numFrames Matrix3D instances.
		 * @param	matrixHistory	Vector of previous matrices to average.
		 */
		function smoothMatrices (storedMatrices:Vector.<Matrix3D>) :Matrix3D;
		
		/**
		 * Halts all processes and frees this instance for garbage collection.
		 */
		function dispose () :void;
	}
}