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
package com.transmote.flar.camera {
	import com.transmote.flar.FLARManager;
	
	import flash.geom.Rectangle;
	
	import sandy.core.data.*;
	import sandy.core.scenegraph.*;
	import sandy.core.scenegraph.Camera3D;
	
	/**
	 * Extends Sandy's Camera3D class to set up a scene correctly
	 * for projection of 3D objects transformed by a tracker managed by FLARManager.
	 *  
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class FLARCamera_Sandy extends Camera3D {
		
		/**
		 * Constructor.
		 * 
		 * @param	flarManager		A reference to the FLARManager instance used by this application.
		 * @param	viewportSize	A Rectangle that describes the viewport size for the application.
		 */
		public function FLARCamera_Sandy (flarManager:FLARManager, viewportSize:Rectangle) {
			const NEAR_CLIP:Number = 50;
			const FAR_CLIP:Number = 10000;
			
			//super(viewportSize.width, viewportSize.height, 0, 2*NEAR_CLIP, FAR_CLIP);
			super(flarManager.flarSource.source.width, flarManager.flarSource.source.height,
				0, 2 /* TODO find why 2 */ * NEAR_CLIP, FAR_CLIP);
			this.z = 0;
			
			var pMat:Vector.<Number>;
			switch (flarManager.trackerId) {
				case FLARManager.TRACKER_ID_FLARTOOLKIT :
					pMat = this.init_FLARToolkit(flarManager, viewportSize);
					break;
				case FLARManager.TRACKER_ID_FLARE :
					pMat = this.init_flare(flarManager, viewportSize);
					break;
			}
			
			// sandy's Camera3D is not designed to be extended, so we
			// will have to override each and every projection method
			m_nOffx = viewport.width2; 
			m_nOffy = viewport.height2;
			
			mp11 = pMat[0];  mp12 = pMat[1];  mp13 = pMat[2];  mp14 = pMat[3];
			mp21 = pMat[4];  mp22 = pMat[5];  mp23 = pMat[6];  mp24 = pMat[7];
			mp31 = pMat[8];  mp32 = pMat[9];  mp33 = pMat[10]; mp34 = pMat[11];
			mp41 = pMat[12]; mp42 = pMat[13]; mp43 = pMat[14]; mp44 = pMat[15];
		}
		
		private function init_FLARToolkit (flarManager:FLARManager, viewportSize:Rectangle) :Vector.<Number> {
			var pMat:flash.geom.Matrix3D = flarManager.getProjectionMatrix(FLARManager.FRAMEWORK_ID_SANDY, viewportSize);
			return pMat.rawData;
		}
		
		private function init_flare (flarManager:FLARManager, viewportSize:Rectangle) :Vector.<Number> {
			var pMat:flash.geom.Matrix3D = flarManager.getProjectionMatrix(FLARManager.FRAMEWORK_ID_SANDY, viewportSize);
			return pMat.rawData;
		}
		
		override public function projectArray( p_oList:Array ):void
		{
			const l_nX:Number = viewport.offset.x + m_nOffx;
			const l_nY:Number = viewport.offset.y + m_nOffy;
			var l_nCste:Number;
			var l_mp11_offx:Number = mp11 * m_nOffx;
			var l_mp22_offy:Number = mp22 * m_nOffy;
			for each( var l_oVertex:Vertex in p_oList )
			{
				if( l_oVertex.projected == false )//(l_oVertex.flags & SandyFlags.VERTEX_PROJECTED) == 0)
				{
					l_nCste = 	1 / l_oVertex.wz;
					l_oVertex.sx =  l_nCste * l_oVertex.wx * l_mp11_offx + l_nX;
					l_oVertex.sy = -l_nCste * l_oVertex.wy * l_mp22_offy + l_nY;
					//l_oVertex.flags |= SandyFlags.VERTEX_PROJECTED;
					l_oVertex.projected = true;
				}
			}
		}
		
		override public function projectVertex( p_oVertex:Vertex ):void
		{
			const l_nX:Number = (viewport.offset.x + m_nOffx);
			const l_nY:Number = (viewport.offset.y + m_nOffy);
			const l_nCste:Number = 	1 / p_oVertex.wz;
			p_oVertex.sx =  l_nCste * p_oVertex.wx * mp11 * m_nOffx + l_nX;
			p_oVertex.sy = -l_nCste * p_oVertex.wy * mp22 * m_nOffy + l_nY;
			//p_oVertex.flags |= SandyFlags.VERTEX_PROJECTED;
			//p_oVertex.projected = true;
		}
		
		override protected function setPerspectiveProjection(p_nFovY:Number, p_nAspectRatio:Number, p_nZNear:Number, p_nZFar:Number):void
		{
			changed = true;	
		}
		
		private var mp11:Number, mp21:Number, mp31:Number, mp41:Number,
		mp12:Number, mp22:Number, mp32:Number, mp42:Number,
		mp13:Number, mp23:Number, mp33:Number, mp43:Number,
		mp14:Number, mp24:Number, mp34:Number, mp44:Number,				
		m_nOffx:int, m_nOffy:int;
		
		override public function get projectionMatrix():Matrix4
		{
			return new Matrix4 (
				mp11, mp12, mp13, mp14,
				mp21, mp22, mp23, mp24,
				mp31, mp32, mp33, mp34,
				mp41, mp42, mp43, mp44 );
		}
		
		// getters for approximate values
		override public function set fov( p_nFov:Number ):void {}
		override public function get fov():Number { return Math.atan (1 / mp22) * 114.591559 /* 2 * 180 / Math.PI */; }
		
		override public function set focalLength( f:Number ):void {}
		override public function get focalLength():Number { return viewport.height2 / Math.tan (fov * 0.00872664626 /* 1 / 2 * (Math.PI / 180) */ ); }
		
		override public function set near( pNear:Number ):void {}
		override public function get near():Number { return -mp34 / mp33; }
		
		override public function set far( pFar:Number ):void {}
		override public function get far():Number { return near * mp33 / (mp33 - 1); }	}
}