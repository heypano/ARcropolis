package examples.support {
	import away3dlite.containers.ObjectContainer3D;
	import away3dlite.containers.Scene3D;
	import away3dlite.containers.View3D;
	import away3dlite.materials.WireColorMaterial;
	import away3dlite.primitives.Cube6;
	
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.camera.FLARCamera_Away3DLite;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.utils.geom.FLARGeomUtils;
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.support.away3d_lite.FLARCamera3D;
	
	
	/**
	 * standard FLARToolkit Away3D Lite example, with our friends the Cubes.
	 * couldn't have done it without Mikael Emtinger's help.  muchas gracias, Mikael.
	 * 
	 * the Away3D Lite platform can be found here:
	 * http://away3d.com/
	 * please note, usage of the Away3D platform is subject to Away3D's licensing.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class SimpleCubes_Away3DLite extends Sprite {
		private static const CUBE_SIZE:Number = 40;
		
		private var view:View3D;
		private var camera3D:FLARCamera_Away3DLite;
		private var scene3D:Scene3D;
		
		private var bMirrorDisplay:Boolean;
		private var markersByPatternId:Vector.<Vector.<FLARMarker>>;	// FLARMarkers, arranged by patternId
		private var activePatternIds:Vector.<int>;						// list of patternIds of active markers
		private var containersByMarker:Dictionary;						// Cube containers, hashed by corresponding FLARMarker
		
		
		public function SimpleCubes_Away3DLite (flarManager:FLARManager, viewportSize:Rectangle) {
			this.bMirrorDisplay = flarManager.mirrorDisplay;
			
			this.init();
			this.initEnvironment(flarManager, viewportSize);
		}

		public function addMarker (marker:FLARMarker) :void {
			this.storeMarker(marker);
			
			// create a new Cube, and place it inside a container (ObjectContainer3D) for manipulation
			var container:ObjectContainer3D = new ObjectContainer3D();
			var mat:WireColorMaterial = this.getMaterialByPatternId(marker.patternId);
			var cube:Cube6 = new Cube6(mat, CUBE_SIZE, CUBE_SIZE, CUBE_SIZE);
			cube.z = -0.5 * CUBE_SIZE;
			container.addChild(cube);
			this.scene3D.addChild(container);
			
			// associate container with corresponding marker
			this.containersByMarker[marker] = container;
		}
		
		public function removeMarker (marker:FLARMarker) :void {
			if (!this.disposeMarker(marker)) { return; }
			
			// find and remove corresponding container
			var container:ObjectContainer3D = this.containersByMarker[marker];
			if (container) {
				this.scene3D.removeChild(container);
			}
			
			delete this.containersByMarker[marker]
		}
		
		private function init () :void {
			// set up lists (Vectors) of FLARMarkers, arranged by patternId
			this.markersByPatternId = new Vector.<Vector.<FLARMarker>>();
			
			// keep track of active patternIds
			this.activePatternIds = new Vector.<int>();
			
			// prepare hashtable for associating Cube containers with FLARMarkers
			this.containersByMarker = new Dictionary(true);
		}
		
		private function initEnvironment (flarManager:FLARManager, viewportSize:Rectangle) :void {
			this.scene3D = new Scene3D();
			this.camera3D = new FLARCamera_Away3DLite(flarManager, viewportSize);
			
			this.view = new View3D(this.scene3D, this.camera3D);
			this.view.x = 0.5 * viewportSize.width;
			this.view.y = 0.5 * viewportSize.height;
			this.view.z = 0;
			this.addChild(this.view);
			
			this.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		
		private function onEnterFrame (evt:Event) :void {
			this.updateCubes();
			this.view.render();
		}
		
		private function updateCubes () :void {
			// update all Cube containers according to the transformation matrix in their associated FLARMarkers
			var i:int = this.activePatternIds.length;
			var markerList:Vector.<FLARMarker>;
			var marker:FLARMarker;
			var container:ObjectContainer3D;
			var j:int;
			while (i--) {
				markerList = this.markersByPatternId[this.activePatternIds[i]];
				j = markerList.length;
				while (j--) {
					marker = markerList[j];
					container = this.containersByMarker[marker];
					container.transform.matrix3D = marker.transformMatrix;
				}
			}
		}
		
		private function storeMarker (marker:FLARMarker) :void {
			// store newly-detected marker.
			
			var markerList:Vector.<FLARMarker>;
			if (marker.patternId < this.markersByPatternId.length) {
				// check for existing list of markers of this patternId...
				markerList = this.markersByPatternId[marker.patternId];
			} else {
				this.markersByPatternId.length = marker.patternId + 1;
			}
			if (!markerList) {
				// if no existing list, make one and store it...
				markerList = new Vector.<FLARMarker>();
				this.markersByPatternId[marker.patternId] = markerList;
				this.activePatternIds.push(marker.patternId);
			}
			// ...add the new marker to the list.
			markerList.push(marker);
		}
		
		private function disposeMarker (marker:FLARMarker) :Boolean {
			// find and remove marker.
			// returns false if marker's patternId is not currently active.
			
			var markerList:Vector.<FLARMarker>;
			if (marker.patternId < this.markersByPatternId.length) {
				// get list of markers of this patternId
				markerList = this.markersByPatternId[marker.patternId];
			}
			if (!markerList) {
				// patternId is not currently active; something is wrong, so exit.
				return false;
			}
			
			var markerIndex:uint = markerList.indexOf(marker);
			if (markerIndex != -1) {
				markerList.splice(markerIndex, 1);
				if (markerList.length == 0) {
					this.markersByPatternId[marker.patternId] = null;
					var patternIdIndex:int = this.activePatternIds.indexOf(marker.patternId);
					if (patternIdIndex != -1) {
						this.activePatternIds.splice(patternIdIndex, 1);
					}
				}
			}
			
			return true;
		}
		
		private function getMaterialByPatternId (patternId:int) :WireColorMaterial {
			switch (patternId) {
				case 0:
					return new WireColorMaterial(0xFF1919, 1, 0x730000);
				case 1:
					return new WireColorMaterial(0xFF19E8, 1, 0x730067);
				case 2:
					return new WireColorMaterial(0x9E19FF, 1, 0x420073);
				case 3:
					return new WireColorMaterial(0x192EFF, 1, 0x000A73);
				case 4:
					return new WireColorMaterial(0x1996FF, 1, 0x003E73);
				case 5:
					return new WireColorMaterial(0x19FDFF, 1, 0x007273);
				case 6:
					return new WireColorMaterial(0x19FF5A, 1, 0x007320);
				case 7:
					return new WireColorMaterial(0x19FFAA, 1, 0x007348);
				case 8:
					return new WireColorMaterial(0x6CFF19, 1, 0x297300);
				case 9:
					return new WireColorMaterial(0xF9FF19, 1, 0x707300);
				case 10:
					return new WireColorMaterial(0xFFCE19, 1, 0x735A00);
				case 11:
					return new WireColorMaterial(0xFF9A19, 1, 0x734000);
				case 12:
					return new WireColorMaterial(0xFF6119, 1, 0x732400);
				default:
					return new WireColorMaterial(0xCCCCCC, 1, 0x666666);
			}
		}
	}
}