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
	import alternativa.types.Matrix3D;
	
	import flash.geom.Matrix3D;
	
	/**
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class AlternativaGeomUtils {
		
		/**
		 * Convert a native flash Matrix3D to an Alternativa3D matrix.
		 * 
		 * @param	mat			Matrix3D to convert.
		 * @param	bMirror		If <code>true</code>, this method will flip the resultant matrix horizontally (around the y-axis).
		 * @return				Alternativa3D Matrix3D generated from the Matrix3D.
		 */
		public static function convertMatrixToAlternativaMatrix (mat:flash.geom.Matrix3D, bMirror:Boolean=true) :alternativa.types.Matrix3D {
			var raw:Vector.<Number> = mat.rawData;
			if (bMirror) {
				return new alternativa.types.Matrix3D(
					raw[0],		-raw[4],	-raw[8],	raw[12],
					raw[1],		-raw[5],	-raw[9],	raw[13],
					raw[2],		-raw[6],	-raw[10],	raw[14]
				);
			} else {
				return new alternativa.types.Matrix3D(
					-raw[0],	-raw[4],	raw[8],		-raw[12],
					raw[1],		raw[5],		-raw[9],	raw[13],
					raw[2],		raw[6],		-raw[10],	raw[14]
				);
			}
		}
		
		public function AlternativaGeomUtils () {}
	}
}