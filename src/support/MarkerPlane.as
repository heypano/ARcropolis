package support {
	import __AS3__.vec.Vector;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.net.URLRequest;
	
	/**
	 * simple class to align a plane with the plane of a detected marker.
	 * MarkerPlane loads a jpg and maps that to the marker.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class MarkerPlane extends Sprite {
		
		public function MarkerPlane (path:String="") {
			if (path != "") {
				this.load(path);
			}
		}
		
		public function load (path:String) :void {
			var loader:Loader = new Loader();
			loader.load(new URLRequest(path));
			loader.contentLoaderInfo.addEventListener(ErrorEvent.ERROR, this.onLoadError);
			loader.contentLoaderInfo.addEventListener(Event.INIT, this.onLoaded);
		}
		
		private function onLoadError (evt:ErrorEvent) :void {
			trace("error loading image...");
			var loaderInfo:LoaderInfo = evt.target as LoaderInfo;
			if (!loaderInfo) { return; }
			
			loaderInfo.removeEventListener(ErrorEvent.ERROR, this.onLoadError);
			loaderInfo.removeEventListener(Event.INIT, this.onLoaded);
		}
		
		private function onLoaded (evt:Event) :void {
			var loaderInfo:LoaderInfo = evt.target as LoaderInfo;
			if (!loaderInfo) { return; }
			
			loaderInfo.removeEventListener(ErrorEvent.ERROR, this.onLoadError);
			loaderInfo.removeEventListener(Event.INIT, this.onLoaded);
			
			var loader:Loader = loaderInfo.loader;
			
			// set loader width/height to match pattern size on-screen (FLARPattern.DEFAULT_UNSCALED_MARKER_WIDTH).
			// alternatively, match pattern size to loader size by setting size in flarConfig.xml:
			// <pattern path="..." size="300" />
			loader.width = 80;
			loader.height = 80;
			loader.x = -0.5 * loader.width;
			loader.y = -0.5 * loader.height;
			
			this.addChild(loader);
			//this.drawAxes();
		}
		
		private function drawAxes () :void {
			var axes:Sprite = new Sprite();
			this.addChild(axes);
			
			axes.graphics.lineStyle(2, 0xFF0000);
			axes.graphics.moveTo(0, 0);
			axes.graphics.lineTo(40, 0);
			
			axes.graphics.lineStyle(2, 0x00FF00);
			axes.graphics.moveTo(0, 0);
			axes.graphics.lineTo(0, 40);
			
			var zAxis:Shape = new Shape();
			zAxis.rotationX = -90;
			axes.addChild(zAxis);
			zAxis.graphics.lineStyle(2, 0x0000FF);
			zAxis.graphics.moveTo(0, 0);
			zAxis.graphics.lineTo(0, 40);
		}
	}
}