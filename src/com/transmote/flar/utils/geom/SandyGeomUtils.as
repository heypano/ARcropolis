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
	
	import sandy.core.data.Matrix4;
	
	/**
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class SandyGeomUtils {
		
		/**
		 * Convert a native flash Matrix3D to a Sandy3D matrix.
		 * Matrix conversion courtesy of <a href="http://makc3d.wordpress.com/2009/03/17/sandy-augmented-reality/">Makc</a>.
		 * 
		 * @param	mat			Matrix3D to convert.
		 * @param	bMirror		If <code>true</code>, this method will flip the resultant matrix horizontally (around the y-axis).
		 * @return				Sandy3D Matrix4 generated from the Matrix3D.
		 */
		public static function convertMatrixToSandyMatrix (mat:Matrix3D, bMirror:Boolean=true) :Matrix4 {
			var raw:Vector.<Number> = mat.rawData;
			if (bMirror) {
				return new sandy.core.data.Matrix4(
					-raw[4],	raw[0],		-raw[8],	raw[12],
					raw[5],		-raw[1],	raw[9],		-raw[13],
					-raw[6],		raw[2],		-raw[10],	raw[14]
					);
			} else {
				return new sandy.core.data.Matrix4(
					-raw[4],	-raw[0],	raw[8],		-raw[12],
					-raw[5],	-raw[1],	raw[9],		-raw[13],
					raw[6],		raw[2],		-raw[10],	raw[14]
					);
			}
		}
		
		public function SandyGeomUtils () {}
	}
}