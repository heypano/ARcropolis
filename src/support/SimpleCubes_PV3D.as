package examples.support {
	import __AS3__.vec.Vector;
	
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.camera.FLARCamera_PV3D;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.utils.geom.FLARGeomUtils;
	import com.transmote.flar.utils.geom.PVGeomUtils;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.math.Matrix3D;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cube;
	import org.papervision3d.render.LazyRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	
	
	/**
	 * standard FLARToolkit Papervision3D example, with our friends the Cubes.
	 * code is borrowed heavily from Saqoosha, Mikko Haapoja, and Squidder.
	 * http://saqoosha.net/en/flartoolkit/start-up-guide/
	 * http://www.mikkoh.com/blog/?p=182
	 * http://www.squidder.com/2009/03/06/flar-how-to-multiple-instances-of-multiple-markers/#more-285
	 * 
	 * the Papervision3D platform can be found here:
	 * http://code.google.com/p/papervision3d/
	 * please note, usage of the Papervision3D platform is subject to Papervision3D's licensing.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class SimpleCubes_PV3D extends Sprite {
		private static const CUBE_SIZE:Number = 40;
		
		private var viewport3D:Viewport3D;
		private var camera3D:FLARCamera_PV3D;
		private var scene3D:Scene3D;
		private var renderEngine:LazyRenderEngine;
		private var pointLight3D:PointLight3D;
		
		private var bMirrorDisplay:Boolean;
		private var markersByPatternId:Vector.<Vector.<FLARMarker>>;	// FLARMarkers, arranged by patternId
		private var activePatternIds:Vector.<int>;						// list of patternIds of active markers
		private var containersByMarker:Dictionary;						// Cube containers, hashed by corresponding FLARMarker
		
		
		public function SimpleCubes_PV3D (flarManager:FLARManager, viewportSize:Rectangle) {
			this.bMirrorDisplay = flarManager.mirrorDisplay;
			
			this.init();
			this.initEnvironment(flarManager, viewportSize);
		}

		public function addMarker (marker:FLARMarker) :void {
			this.storeMarker(marker);
			
			// create a new Cube, and place it inside a container (DisplayObject3D) for manipulation
			var container:DisplayObject3D = new DisplayObject3D();
			var materialsList:MaterialsList = new MaterialsList({all: this.getMaterialByPatternId(marker.patternId)});
			var cube:Cube = new Cube(materialsList, CUBE_SIZE, CUBE_SIZE, CUBE_SIZE);
			cube.z = 0.5 * CUBE_SIZE;
			container.addChild(cube);
			this.scene3D.addChild(container);
			
			// associate container with corresponding marker
			this.containersByMarker[marker] = container;
		}
		
		public function removeMarker (marker:FLARMarker) :void {
			if (!this.disposeMarker(marker)) { return; }
			
			// find and remove corresponding container
			var container:DisplayObject3D = this.containersByMarker[marker];
			if (container) {
				this.scene3D.removeChild(container);
			}
			delete this.containersByMarker[marker];
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
			this.viewport3D = new Viewport3D(viewportSize.width, viewportSize.height);
			this.addChild(this.viewport3D);
			
			this.camera3D = new FLARCamera_PV3D(flarManager, viewportSize);
			
			this.renderEngine = new LazyRenderEngine(this.scene3D, this.camera3D, this.viewport3D);
			
			this.pointLight3D = new PointLight3D();
			this.pointLight3D.x = 1000;
			this.pointLight3D.y = 1000;
			this.pointLight3D.z = -1000;
			
			this.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		
		private function onEnterFrame (evt:Event) :void {
			this.updateCubes();
			this.renderEngine.render();
		}
		
		private function updateCubes () :void {
			// update all Cube containers according to the transformation matrix in their associated FLARMarkers
			var i:int = this.activePatternIds.length;
			var markerList:Vector.<FLARMarker>;
			var marker:FLARMarker;
			var container:DisplayObject3D;
			var j:int;
			while (i--) {
				markerList = this.markersByPatternId[this.activePatternIds[i]];
				j = markerList.length;
				while (j--) {
					marker = markerList[j];
					container = this.containersByMarker[marker];
					container.transform = PVGeomUtils.convertMatrixToPVMatrix(marker.transformMatrix, this.bMirrorDisplay);
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
		
		private function getMaterialByPatternId (patternId:int) :FlatShadeMaterial {
			switch (patternId % 12) {
				case 0:
					return new FlatShadeMaterial(this.pointLight3D, 0xFF1919, 0x730000);
				case 1:
					return new FlatShadeMaterial(this.pointLight3D, 0xFF19E8, 0x730067);
				case 2:
					return new FlatShadeMaterial(this.pointLight3D, 0x9E19FF, 0x420073);
				case 3:
					return new FlatShadeMaterial(this.pointLight3D, 0x192EFF, 0x000A73);
				case 4:
					return new FlatShadeMaterial(this.pointLight3D, 0x1996FF, 0x003E73);
				case 5:
					return new FlatShadeMaterial(this.pointLight3D, 0x19FDFF, 0x007273);
				case 6:
					return new FlatShadeMaterial(this.pointLight3D, 0x19FF5A, 0x007320);
				case 7:
					return new FlatShadeMaterial(this.pointLight3D, 0x19FFAA, 0x007348);
				case 8:
					return new FlatShadeMaterial(this.pointLight3D, 0x6CFF19, 0x297300);
				case 9:
					return new FlatShadeMaterial(this.pointLight3D, 0xF9FF19, 0x707300);
				case 10:
					return new FlatShadeMaterial(this.pointLight3D, 0xFFCE19, 0x735A00);
				case 11:
					return new FlatShadeMaterial(this.pointLight3D, 0xFF9A19, 0x734000);
				case 12:
					return new FlatShadeMaterial(this.pointLight3D, 0xFF6119, 0x732400);
				default:
					return new FlatShadeMaterial(this.pointLight3D, 0xCCCCCC, 0x666666);
			}
		}
	}
}