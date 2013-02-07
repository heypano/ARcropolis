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
package com.transmote.flar.utils.geom {
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	import jp.nyatla.nyartoolkit.as3.core.NyARMat;
	import jp.nyatla.nyartoolkit.as3.core.param.NyARPerspectiveProjectionMatrix;
	import jp.nyatla.nyartoolkit.as3.core.transmat.NyARTransMatResult;
	import jp.nyatla.nyartoolkit.as3.core.types.NyARIntSize;
	import jp.nyatla.nyartoolkit.as3.core.types.matrix.NyARDoubleMatrix34;
	
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.utils.ArrayUtil;
	
	/**
	 * Collection of FLARToolkit-specific matrix transformation / conversion utils.
	 * Includes methods to transform projection matrices for camera/scene setup
	 * from a generic Matrix3D to a Matrix3D with data useful for each 3D framework.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARToolkitGeomUtils {
		private static const RADIANS_TO_DEGREES:Number = 180 / Math.PI;
		private static const DEGREES_TO_RADIANS:Number = Math.PI / 180;
		
		
		/**
		 * Convert a FLAR matrix to a Flash Matrix3D.
		 */
		public static function convertNyARMatrixToFlashMatrix3D (mat:NyARDoubleMatrix34, bMirror:Boolean=true) :Matrix3D {
			/*
			// TODO: these conversions give correct axis orientation both when mirrored and when not.
			// however, they screw up all other conversions for other 3D frameworks.
			// need to work out correct conversions for other 3D frameworks, based on these base Matrix3D conversions.
			if (bMirror) {
				return new Matrix3D (Vector.<Number>([
					-mat.m00,	mat.m10,		mat.m20,		0,
					-mat.m01,	mat.m11,		mat.m21,		0,
					mat.m02,	-mat.m12,		mat.m22,		0,
					-mat.m03,	mat.m13,		mat.m23,		1
				]));
			} else {
				return new Matrix3D (Vector.<Number>([
					mat.m00,		mat.m10,		mat.m20,		0,
					mat.m01,		mat.m11,		mat.m21,		0,
					-mat.m02,		-mat.m12,		mat.m22,		0,
					mat.m03,		mat.m13,		mat.m23,		1
				]));
			}
			*/
			if (bMirror) {
				return new Matrix3D (Vector.<Number>([
					-mat.m00,	mat.m10,		mat.m20,		0,
					-mat.m01,	mat.m11,		mat.m21,		0,
					mat.m02,	-mat.m12,		-mat.m22,		0,
					-mat.m03,	mat.m13,		mat.m23,		1
					]));
			} else {
				return new Matrix3D (Vector.<Number>([
					mat.m00,		mat.m10,		mat.m20,		0,
					-mat.m01,		-mat.m11,		-mat.m21,		0,
					-mat.m02,		-mat.m12,		-mat.m22,		0,
					mat.m03,		mat.m13,		mat.m23,		1
					]));
			}
		}
		
		/**
		 * Calculate rotation around X, Y, and Z axes,
		 * and return stored in a Vector3D instance.
		 * NOTE: does not account for scale, as FLARToolkit matrices always scale equally in all three dimensons.
		 */
		public static function calcNyARMatrixRotations (mat:NyARDoubleMatrix34, bInDegrees:Boolean=true) :Vector3D {
			var rotations:Vector3D = new Vector3D();
			
			rotations.x = Math.atan2(mat.m20, mat.m22);
			rotations.y = Math.asin(-mat.m21);
			rotations.z = Math.atan2(mat.m01, -mat.m11);
			
			if (bInDegrees) {
				rotations.x *= RADIANS_TO_DEGREES;
				rotations.y *= RADIANS_TO_DEGREES;
				rotations.z *= RADIANS_TO_DEGREES;
			}
			
			return rotations;
		}
		
		/**
		 * Calculate scale in X, Y, and Z dimensions,
		 * and return stored in a Vector3D instance.
		 * NOTE: FLARToolkit matrices should always scale equally in all three dimensions,
		 * 		 so this method is not likely to be useful.  but, it's here now, so here it stays.
		 */
		public static function calcNyARMatrixScales (mat:NyARDoubleMatrix34) :Vector3D {
			var scales:Vector3D = new Vector3D();
			
			scales.x = Math.sqrt(mat.m01*mat.m01 + mat.m11*mat.m11 + mat.m21*mat.m21);
			scales.y = Math.sqrt(mat.m00*mat.m00 + mat.m10*mat.m10 + mat.m20*mat.m20);
			scales.z = Math.sqrt(mat.m02*mat.m02 + mat.m12*mat.m12 + mat.m22*mat.m22);
			
			return scales;
		}
				
		/**
		 * Format a FLAR matrix as a String.
		 * 
		 * @param	fm		FLAR matrix to return as a String.
		 * @param	sd		Number of significant digits to display.
		 */
		public static function dumpNyARMatrix (mat:NyARDoubleMatrix34, sd:int=4) :String {
			return (mat.m00.toFixed(sd) +"\u0009"+ mat.m01.toFixed(sd) +"\u0009"+ mat.m02.toFixed(sd) +"\u0009"+ mat.m03.toFixed(sd) +"\n"+
					mat.m10.toFixed(sd) +"\u0009"+ mat.m11.toFixed(sd) +"\u0009"+ mat.m12.toFixed(sd) +"\u0009"+ mat.m13.toFixed(sd) +"\n"+
					mat.m20.toFixed(sd) +"\u0009"+ mat.m21.toFixed(sd) +"\u0009"+ mat.m22.toFixed(sd) +"\u0009"+ mat.m23.toFixed(sd));
		}
		
		/**
		 * Convert FLARToolkit projection matrix to data that can be used
		 * by native Flash 3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * Thanks to <a href="http://wonderfl.net/c/ztdH">Nutsu</a> for the matrix conversion.
		 */
		public static function calcProjectionMatrix_Flash (cameraParams:FLARParam, viewportSize:Rectangle) :Matrix3D {
			var trans_mat:NyARMat = new NyARMat(3,4);
			var icpara_mat:NyARMat = new NyARMat(3,4);
			var i:int;
			const size:NyARIntSize = cameraParams.getScreenSize();
			const width:int  = size.w;
			const height:int = size.h;
			
			cameraParams.getPerspectiveProjectionMatrix().decompMat(icpara_mat, trans_mat);
			
			var icpara:Vector.<Vector.<Number>> = icpara_mat.getArray();
			var trans:Vector.<Vector.<Number>> = trans_mat.getArray();
			for (i = 0; i < 4; i++) {
				icpara[1][i] = (height - 1) * (icpara[2][i]) - icpara[1][i];
			}
			
			var projectionMatrix:Matrix3D = new Matrix3D(Vector.<Number>([
				icpara[0][0],	icpara[0][1],	icpara[0][2],	icpara[0][3],
				icpara[1][0],	icpara[1][1],	icpara[1][2],	icpara[1][3],
				icpara[2][0],	icpara[2][1],	icpara[2][2],	icpara[2][3],
				0,				0,				0,				1
			]));
			return projectionMatrix;
		}
		
		/**
		 * Convert FLARToolkit projection matrix to data that can be used
		 * by Alternativa to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * Thanks to <a href="http://makc3d.wordpress.com/">Makc</a> for the matrix conversion.
		 */
		public static function calcProjectionMatrix_Alternativa (cameraParams:FLARParam, viewportSize:Rectangle) :Matrix3D {
			var trans_mat:NyARMat = new NyARMat(3,4);
			var icpara_mat:NyARMat = new NyARMat(3,4);
			const size:NyARIntSize = cameraParams.getScreenSize();
			
			cameraParams.getPerspectiveProjectionMatrix().decompMat(icpara_mat, trans_mat);
			var icpara:Vector.<Vector.<Number>> = icpara_mat.getArray();
			var trans:Vector.<Vector.<Number>> = trans_mat.getArray();
			
			const h1:Number = size.h - 1;
			const p11:Number = (h1 * icpara[2][1] - icpara[1][1]) / icpara[2][2];
			const p12:Number = (h1 * icpara[2][2] - icpara[1][2]) / icpara[2][2];
			const q11:Number = -(2 * p11 / h1);
			const q12:Number = -(2 * p12 / h1) + 1.0;
			const mp5:Number = q11 * trans[1][1] + q12 * trans[2][1];
			const tan:Number = 1 / mp5 * Math.sqrt (size.w * size.w + size.h * size.h) / size.h;
			
			// pass tan back in Matrix3D to comply with projectionMatrix calculation methods;
			// FLARCamera_Alternativa3D will extract and consume only the first value in mat.rawData.
			var mat:Matrix3D = new Matrix3D();
			mat.prependScale(tan, tan, tan);
			return mat;
		}
		
		/**
		 * Convert FLARToolkit projection matrix to data that can be used
		 * by Away3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * Thanks to <a href="http://www.infiniteturtles.co.uk/blog/away3d-the-flartoolkit">Rob Bateman</a> for the matrix conversion.
		 */
		public static function calcProjectionMatrix_Away (cameraParams:FLARParam, viewportSize:Rectangle, zoom:Number=10, focus:Number=100) :Matrix3D {
			var m_projection:Array = new Array(16);
			var trans_mat:NyARMat = new NyARMat(3,4);
			var icpara_mat:NyARMat = new NyARMat(3,4);
			var p:Array = ArrayUtil.createJaggedArray(3, 3);
			var q:Array = ArrayUtil.createJaggedArray(4, 4);
			var i:int;
			var j:int;
			const size:NyARIntSize = cameraParams.getScreenSize();
			const width:int  = size.w;
			const height:int = size.h;
			
			cameraParams.getPerspectiveProjectionMatrix().decompMat(icpara_mat, trans_mat);
			
			// convert first to Away3D MatrixAway3D format...
			var icpara:Vector.<Vector.<Number>> = icpara_mat.getArray();
			var trans:Vector.<Vector.<Number>> = trans_mat.getArray();
			for (i = 0; i < 4; i++) {
				icpara[1][i] = (height - 1) * (icpara[2][i]) - icpara[1][i];
			}
			
			for(i = 0; i < 3; i++) {
				for(j = 0; j < 3; j++) {
					p[i][j] = icpara[i][j] / icpara[2][2];
				}
			}
			
			var div:Number = zoom*focus;
			
			q[0][0] = 2.0 * p[0][0]/div;
			q[0][1] = 2.0 * p[0][1]/div;
			q[0][2] = -(2.0 * p[0][2]  - (width - 1))/div;
			q[0][3] = 0.0;
			 
			q[1][0] = 0.0;
			q[1][1] = 2.0 * p[1][1]/div;
			q[1][2] = -(2.0 * p[1][2] - (height - 1))/div;
			q[1][3] = 0.0;
			
			q[2][0] = 0.0;
			q[2][1] = 0.0;
			q[2][2] = 1.0;
			q[2][3] = 0.0;
			
			q[3][0] = 0.0;
			q[3][1] = 0.0;
			q[3][2] = 0.0;
			q[3][3] = 1.0;
			
			for (i = 0; i < 4; i++) { // Row.
				// First 3 columns of the current row.
				for (j = 0; j < 3; j++) { // Column.
					m_projection[i*4 + j] = q[i][0] * trans[0][j] + q[i][1] * trans[1][j] + q[i][2] * trans[2][j];
				}
				// Fourth column of the current row.
				m_projection[i*4 + 3] = q[i][0] * trans[0][3] + q[i][1] * trans[1][3] + q[i][2] * trans[2][3] + q[i][3];
			}
			
			// ...then convert to flash.geom.Matrix3D.
			var mat:Matrix3D = new Matrix3D(Vector.<Number>([
				-m_projection[0],	-m_projection[4],	m_projection[8],	0,
				-m_projection[2],	-m_projection[6],	m_projection[10],	0,
				m_projection[1],	m_projection[5],	-m_projection[9],	0,
				-m_projection[3],	-m_projection[7],	m_projection[11],	1
			]));
			return mat;
		}
		
		/**
		 * Convert FLARToolkit projection matrix to data that can be used
		 * by Away3D Lite to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * Thanks to <a href="http://twitter.com/mikaelemtinger">Mikael Emtinger</a> for the matrix conversion.
		 */
		public static function calcProjectionMatrix_AwayLite (cameraParams:FLARParam, viewportSize:Rectangle) :Matrix3D {
			var fm:NyARPerspectiveProjectionMatrix = cameraParams.getPerspectiveProjectionMatrix();
			var viewportToSourceWidthRatio:Number = viewportSize.width / cameraParams.getScreenSize().w;
			
			return new Matrix3D(Vector.<Number>([
				fm.m00*viewportToSourceWidthRatio,	fm.m01,	0,	fm.m03,
				fm.m10,	fm.m11*viewportToSourceWidthRatio,	0,	fm.m13,
				fm.m20,	fm.m21,	fm.m22,	1,
				0,		0,		0,		0
			]));
			
		}
		
		/**
		 * Convert FLARToolkit projection matrix to data that can be used
		 * by Papervision3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 */
		public static function calcProjectionMatrix_Papervision (cameraParams:FLARParam, viewportSize:Rectangle) :Matrix3D {
			const NEAR_CLIP:Number = 10;
			const FAR_CLIP:Number = 10000;
			var m_projection:Vector.<Number> = new Vector.<Number>(16, true);
			var trans_mat:NyARMat = new NyARMat(3,4);
			var icpara_mat:NyARMat = new NyARMat(3,4);
			var p:Array = ArrayUtil.createJaggedArray(3, 3);
			var q:Array = ArrayUtil.createJaggedArray(4, 4);
			var i:int;
			var j:int;
			const size:NyARIntSize = cameraParams.getScreenSize();
			const width:int  = size.w;
			const height:int = size.h;
			
			cameraParams.getPerspectiveProjectionMatrix().decompMat(icpara_mat, trans_mat);
			
			// convert first to Papervision3D Matrix3D format...
			var icpara:Vector.<Vector.<Number>> = icpara_mat.getArray();
			var trans:Vector.<Vector.<Number>> = trans_mat.getArray();
			for (i = 0; i < 4; i++) {
				icpara[1][i] = (height - 1) * (icpara[2][i]) - icpara[1][i];
			}
			
			for(i = 0; i < 3; i++) {
				for(j = 0; j < 3; j++) {
					p[i][j] = icpara[i][j] / icpara[2][2];
				}
			}
			q[0][0] = (2.0 * p[0][0] / (width - 1));
			q[0][1] = (2.0 * p[0][1] / (width - 1));
			q[0][2] = -((2.0 * p[0][2] / (width - 1))  - 1.0);
			q[0][3] = 0.0;
			
			q[1][0] = 0.0;
			q[1][1] = -(2.0 * p[1][1] / (height - 1));
			q[1][2] = -((2.0 * p[1][2] / (height - 1)) - 1.0);
			q[1][3] = 0.0;
			
			q[2][0] = 0.0;
			q[2][1] = 0.0;
			q[2][2] = -(FAR_CLIP + NEAR_CLIP) / (NEAR_CLIP - FAR_CLIP);
			q[2][3] = 2.0 * FAR_CLIP * NEAR_CLIP / (NEAR_CLIP - FAR_CLIP);
			
			q[3][0] = 0.0;
			q[3][1] = 0.0;
			q[3][2] = 1.0;
			q[3][3] = 0.0;
			
			for (i = 0; i < 4; i++) { // Row.
				// First 3 columns of the current row.
				for (j = 0; j < 3; j++) { // Column.
					m_projection[i*4 + j] =
						q[i][0] * trans[0][j] +
						q[i][1] * trans[1][j] +
						q[i][2] * trans[2][j];
				}
				// Fourth column of the current row.
				m_projection[i*4 + 3]=
					q[i][0] * trans[0][3] +
					q[i][1] * trans[1][3] +
					q[i][2] * trans[2][3] +
					q[i][3];
			}
			
			// ...then convert to flash.geom.Matrix3D.
			var mat:Matrix3D = new Matrix3D(Vector.<Number>([
				m_projection[1],	m_projection[5],	-m_projection[9],	m_projection[13],
				m_projection[0],	m_projection[4],	-m_projection[8],	m_projection[12],
				m_projection[2],	m_projection[6],	-m_projection[10],	m_projection[14],
				-m_projection[3],	-m_projection[7],	m_projection[11],	m_projection[15]
			]));
			
			return mat;
		}
		
		/**
		 * Convert FLARToolkit projection matrix to data that can be used
		 * by Sandy3D to determine scene projection,
		 * in order to draw 3D models in correct perspective.
		 * 
		 * Thanks to <a href="http://makc3d.wordpress.com/">Makc</a> for the matrix conversion.
		 */
		public static function calcProjectionMatrix_Sandy (cameraParams:FLARParam, viewportSize:Rectangle, NEAR_CLIP:Number=50, FAR_CLIP:Number=10000) :Matrix3D {
			const size:NyARIntSize = cameraParams.getScreenSize();
			const width:int  = size.w;
			const height:int = size.h;
			
			var m_projection:Vector.<Number> = new Vector.<Number>(16, true);
			var trans_mat:NyARMat = new NyARMat(3,4);
			var icpara_mat:NyARMat = new NyARMat(3,4);
			var p:Array = ArrayUtil.createJaggedArray(3, 3);
			var q:Array = ArrayUtil.createJaggedArray(4, 4);
			var i:int;
			var j:int;
			
			cameraParams.getPerspectiveProjectionMatrix().decompMat(icpara_mat, trans_mat);
			
			var icpara:Vector.<Vector.<Number>> = icpara_mat.getArray();
			var trans:Vector.<Vector.<Number>> = trans_mat.getArray();
			for (i = 0; i < 4; i++) {
				icpara[1][i] = (height - 1) * (icpara[2][i]) - icpara[1][i];
			}
			
			for(i = 0; i < 3; i++) {
				for(j = 0; j < 3; j++) {
					p[i][j] = icpara[i][j] / icpara[2][2];
				}
			}
			q[0][0] = (2.0 * p[0][0] / (width - 1));
			q[0][1] = (2.0 * p[0][1] / (width - 1));
			q[0][2] = -((2.0 * p[0][2] / (width - 1))  - 1.0);
			q[0][3] = 0.0;
			
			q[1][0] = 0.0;
			q[1][1] = -(2.0 * p[1][1] / (height - 1));
			q[1][2] = -((2.0 * p[1][2] / (height - 1)) - 1.0);
			q[1][3] = 0.0;
			
			q[2][0] = 0.0;
			q[2][1] = 0.0;
			q[2][2] = -(FAR_CLIP + NEAR_CLIP) / (NEAR_CLIP - FAR_CLIP);
			q[2][3] = 2.0 * FAR_CLIP * NEAR_CLIP / (NEAR_CLIP - FAR_CLIP);
			
			q[3][0] = 0.0;
			q[3][1] = 0.0;
			q[3][2] = 1.0;
			q[3][3] = 0.0;
			
			for (i = 0; i < 4; i++) { // Row.
				// First 3 columns of the current row.
				for (j = 0; j < 3; j++) { // Column.
					m_projection[i*4 + j] =
						q[i][0] * trans[0][j] +
						q[i][1] * trans[1][j] +
						q[i][2] * trans[2][j];
				}
				// Fourth column of the current row.
				m_projection[i*4 + 3]=
					q[i][0] * trans[0][3] +
					q[i][1] * trans[1][3] +
					q[i][2] * trans[2][3] +
					q[i][3];
			}
			
			// TODO: format as a Flash Matrix3D, and change mapping to Sandy Matrix3D in FLARCamera_Sandy.
			// NOTE: this Matrix3D is formatted as a FLARToolkit matrix, not a Flash Matrix3D.
			return new Matrix3D(m_projection);
		}	
		
		public function FLARToolkitGeomUtils () {}
	}
}