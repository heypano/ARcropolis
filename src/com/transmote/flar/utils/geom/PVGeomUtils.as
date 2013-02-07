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
	
	import org.papervision3d.core.math.Matrix3D;
	
	
	/**
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class PVGeomUtils {
		
		/**
		 * Convert a native flash Matrix3D to a Papvervision3D matrix.
		 * 
		 * @param	mat			Matrix3D to convert.
		 * @param	bMirror		If <code>true</code>, this method will flip the resultant matrix horizontally (around the y-axis).
		 * @return				Papervision Matrix3D generated from the Matrix3D.
		 */
		public static function convertMatrixToPVMatrix (mat:flash.geom.Matrix3D, bMirror:Boolean=true) :org.papervision3d.core.math.Matrix3D {
			var raw:Vector.<Number> = mat.rawData;
			if (bMirror) {
				return new org.papervision3d.core.math.Matrix3D ([
					-raw[4],	raw[0],		-raw[8],	raw[12],
					raw[5],		-raw[1],	raw[9],		-raw[13],
					-raw[6],	raw[2],		-raw[10],	raw[14],
					raw[7],		raw[3],		raw[11],	raw[15]
				]);
			} else {
				return new org.papervision3d.core.math.Matrix3D ([
					raw[4],		raw[0],		raw[8],		-raw[12],
					raw[5],		raw[1],		raw[9],		-raw[13],
					-raw[6],	-raw[2],	-raw[10],	raw[14],
					raw[7],		raw[3],		raw[11],	raw[15]
				]);
			}
		}
		
		public static function dumpPVMatrix3D (m:org.papervision3d.core.math.Matrix3D, sd:int=4) :String {
			return (m.n11.toFixed(sd) +"\u0009"+"\u0009"+ m.n12.toFixed(sd) +"\u0009"+"\u0009"+ m.n13.toFixed(sd) +"\u0009"+"\u0009"+ m.n14.toFixed(sd) +"\n"+
					m.n21.toFixed(sd) +"\u0009"+"\u0009"+ m.n22.toFixed(sd) +"\u0009"+"\u0009"+ m.n23.toFixed(sd) +"\u0009"+"\u0009"+ m.n24.toFixed(sd) +"\n"+
					m.n31.toFixed(sd) +"\u0009"+"\u0009"+ m.n32.toFixed(sd) +"\u0009"+"\u0009"+ m.n33.toFixed(sd) +"\u0009"+"\u0009"+ m.n34.toFixed(sd) +"\n"+
					m.n41.toFixed(sd) +"\u0009"+"\u0009"+ m.n42.toFixed(sd) +"\u0009"+"\u0009"+ m.n43.toFixed(sd) +"\u0009"+"\u0009"+ m.n44.toFixed(sd));
		}
		
		public function PVGeomUtils () {}
	}
}