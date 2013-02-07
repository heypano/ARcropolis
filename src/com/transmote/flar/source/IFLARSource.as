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
package com.transmote.flar.source {
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	/**
	 * Interface that defines a means of updating and accessing a
	 * BitmapData instance to be analyzed by a tracking engine.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public interface IFLARSource {
		/**
		 * Update the BitmapData source.
		 */
		function update () :void;
		
		/**
		 * Retrieve the BitmapData source used for analysis.
		 * NOTE: returns the actual BitmapData object, not a clone.
		 */
		function get source () :BitmapData;
		
		/**
		 * Size of BitmapData source used for analysis.
		 */
		function get sourceSize () :Rectangle;
		
		/**
		 * Ratio of area of tracker's reported results to display size.
		 * Use to scale (multiply) results of tracker analysis to correctly fit display area.
		 */
		function get trackerToDisplayRatio () :Number;
		
		/**
		 * Set to <code>true</code> to flip the camera image horizontally.
		 */
		function get mirrored () :Boolean;
		function set mirrored (val:Boolean) :void;
		
		/**
		 * Returns <code>true</code> if initialization is complete.
		 */
		function get inited () :Boolean;
		
		/**
		 * Halts all processes and frees this instance for garbage collection.
		 */
		function dispose () :void;
	}
}