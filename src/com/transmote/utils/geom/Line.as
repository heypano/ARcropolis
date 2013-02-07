package com.transmote.utils.geom {
	import com.transmote.utils.geom.Line;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Represents a 2D line segment.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/
	 */
	public class Line {
		public var x1:Number;
		public var x2:Number;
		public var y1:Number;
		public var y2:Number;
		
		
		/**
		 * constructs and initializes a Line from the specified coordinates.
		 */
		public function Line (x1:Number=0.0, y1:Number=0.0, x2:Number=0.0, y2:Number=0.0) {
			this.x1 = x1;
			this.x2 = x2;
			this.y1 = y1;
			this.y2 = y2;
		}
		
		/**
		 * returns the Line defined by two Points.
		 * @param	pt1		line startpoint.
		 * @param	pt2		line endpoint.
		 * @return			calculated Line.
		 */
		public static function createLineByPoints (pt1:Point, pt2:Point) :Line {
			return new Line(pt1.x, pt1.y, pt2.x, pt2.y);
		}
		
		/**
		 * returns the Line from a starting point, of a given angle and length.
		 * @param	point		line startpont. 
		 * @param	angle		angle in radians.
		 * @param	length		line length.
		 * @return				calculated Line.
		 * 
		 * TODO: not yet tested.
		 */
		public static function createLineByPointAngleLength (pt:Point, angleInRadians:Number, length:Number) :Line {
			var endX:Number = length * Math.cos(angleInRadians);
			var endY:Number = length * Math.sin(angleInRadians);
			return new Line(pt.x, pt.y, endX, endY);
		}
		
		/**
		 * returns the Point of intersection of this and another Line.
		 * if Lines are parallel, returns null.
		 * @param	line	other Line with which to find intersection.
		 * @param	bWithinSegmentBounds	if true, returns intersections only with Line.getBounds of each Line.
		 */
		public function getIntersection (line:Line, bWithinSegmentBounds:Boolean=false) :Point {
			var mA:Number = this.getSlope();
			var mB:Number = line.getSlope();
			var intX:Number, intY:Number;
			
			if (mA == Number.POSITIVE_INFINITY || mA == Number.NEGATIVE_INFINITY) {
				if (mB == Number.POSITIVE_INFINITY || mB == Number.NEGATIVE_INFINITY) {
					// both vertical
					return null;
				}
				// this Line is vertical
				intX = this.x1;
				intY = mB * (intX - line.x1) + line.y1;
			} else if (mB == Number.POSITIVE_INFINITY || mB == Number.NEGATIVE_INFINITY) {
				// other Line is vertical
				intX = line.x1;
				intY = mA * (intX - this.x1) + this.y1;
			} else {
				// neither line is vertical
				var bA:Number = this.y1 - mA * this.x1;
				var bB:Number = line.y1 - mB * line.x1;
				intX = (bB - bA) / (mA - mB);
				intY = mB*intX + bB;
			}
				
			var intersectionPt:Point = new Point(intX, intY);
			if (bWithinSegmentBounds) {
				if (this.getBounds().contains(intersectionPt.x,intersectionPt.y) && line.getBounds().contains(intersectionPt.x,intersectionPt.y)) {
					return intersectionPt;
				} else {
					return null;
				}
			} else {
				return intersectionPt;
			}
		}
		
		/**
		 * retrieve Line startpoint.
		 */
		public function getPt1 () :Point {
			return new Point(x1, y1);
		}
		
		/**
		 * retrieve Line endpoint.
		 */
		public function getPt2 () :Point {
			return new Point(x2, y2);
		}
		
		/**
		 * angle of this Line (in radians).
		 */
		public function getAngle () :Number {
			return Math.atan2(this.y2-this.y1, this.x2-this.x1);
		}
		
		public function getSlope () :Number {
			return (this.y2-this.y1) / (this.x2-this.x1);
		}
		
		public function getYIntercept () :Number {
			return (this.y1 - this.getSlope() * this.x1);
		}
		
		public function getBounds () :Rectangle {
			return new Rectangle(Math.min(this.x1, this.x2), Math.min(this.y1, this.y2), Math.abs(this.x2-this.x1), Math.abs(this.y2-this.y1));
		}
	}
}