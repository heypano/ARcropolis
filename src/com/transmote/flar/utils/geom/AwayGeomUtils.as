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
	import away3d.core.math.MatrixAway3D;
	
	import flash.geom.Matrix3D;
	
	/**
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class AwayGeomUtils {
		
		/**
		 * Convert a native flash Matrix3D to an Away3D matrix.
		 * 
		 * @param	mat			Matrix3D to convert.
		 * @param	bMirror		If <code>true</code>, this method will flip the resultant matrix horizontally (around the y-axis).
		 * @return				MatrixAway3D generated from the Matrix3D.
		 */
		public static function convertMatrixToAwayMatrix (mat:Matrix3D, bMirror:Boolean=true) :MatrixAway3D {
			var raw:Vector.<Number> = mat.rawData;
			var m:MatrixAway3D = new MatrixAway3D();
			if (bMirror) {
				m.sxx = raw[0];		m.sxy = -raw[8];	m.sxz = -raw[4];	m.tx = raw[12];
				m.syx = -raw[1];	m.syy = raw[9];		m.syz = raw[5];		m.ty = -raw[13];
				m.szx = raw[2];		m.szy = -raw[10];	m.szz = -raw[6];	m.tz = raw[14];
				return m;
			} else {
				m.sxx = -raw[0];	m.sxy = raw[8];		m.sxz = -raw[4];	m.tx = -raw[12];
				m.syx = -raw[1];	m.syy = raw[9];		m.syz = -raw[5];	m.ty = -raw[13];
				m.szx = raw[2];		m.szy = -raw[10];	m.szz = raw[6];	m.tz = raw[14];
				return m;
			}
		}
		
		/**
		 * Format Away3D matrix as a String.
		 * @param	matrix	MatrixAway3D to return as a String.
		 * @param	sd		number of significant digits to display.
		 */
		public static function dumpMatrix3D (m:MatrixAway3D, sd:int=4) :String {
			return (m.sxx.toFixed(sd) +"\u0009"+"\u0009"+ m.sxy.toFixed(sd) +"\u0009"+"\u0009"+ m.sxz.toFixed(sd) +"\u0009"+"\u0009"+ m.tx.toFixed(sd) +"\n"+
				m.syx.toFixed(sd) +"\u0009"+"\u0009"+ m.syy.toFixed(sd) +"\u0009"+"\u0009"+ m.syz.toFixed(sd) +"\u0009"+"\u0009"+ m.ty.toFixed(sd) +"\n"+
				m.szx.toFixed(sd) +"\u0009"+"\u0009"+ m.szy.toFixed(sd) +"\u0009"+"\u0009"+ m.szz.toFixed(sd) +"\u0009"+"\u0009"+ m.tz.toFixed(sd) +"\n"+
				m.swx.toFixed(sd) +"\u0009"+"\u0009"+ m.swy.toFixed(sd) +"\u0009"+"\u0009"+ m.swz.toFixed(sd) +"\u0009"+"\u0009"+ m.tw.toFixed(sd));
		}
		
		public function AwayGeomUtils () {}
	}
}