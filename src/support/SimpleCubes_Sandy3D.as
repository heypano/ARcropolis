package examples.support {
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.camera.FLARCamera_Sandy;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.utils.geom.SandyGeomUtils;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import sandy.core.Scene3D;
	import sandy.core.scenegraph.Group;
	import sandy.core.scenegraph.TransformGroup;
	import sandy.materials.Appearance;
	import sandy.materials.ColorMaterial;
	import sandy.materials.attributes.LightAttributes;
	import sandy.materials.attributes.MaterialAttributes;
	import sandy.primitive.Box;
	
	
	/**
	 * standard FLARToolkit Sandy3D example, with our friends the Cubes.
	 * code is borrowed heavily from Makc the Great:
	 * http://makc3d.wordpress.com/2009/03/17/sandy-augmented-reality/
	 * 
	 * the Sandy3D platform can be found here:
	 * http://www.flashsandy.org/
	 * please note, usage of the Sandy3D platform is subject to Sandy3D's licensing.
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/flar
	 */
	public class SimpleCubes_Sandy3D extends Sprite {
		private static const CUBE_SIZE:Number = 40;
		
		private var viewport:Sprite;
		private var camera3D:FLARCamera_Sandy;
		private var scene3D:Scene3D;
		
		private var bMirrorDisplay:Boolean;
		private var markersByPatternId:Vector.<Vector.<FLARMarker>>;	// FLARMarkers, arranged by patternId
		private var activePatternIds:Vector.<int>;						// list of patternIds of active markers
		private var containersByMarker:Dictionary;						// Cube containers, hashed by corresponding FLARMarker
		
		
		public function SimpleCubes_Sandy3D (flarManager:FLARManager, viewportSize:Rectangle) {
			this.bMirrorDisplay = flarManager.mirrorDisplay;
			
			this.init();
			this.initEnvironment(flarManager, viewportSize);
		}

		public function addMarker (marker:FLARMarker) :void {
			this.storeMarker(marker);
			
			// create a new Cube, and place it inside a container (TransformGroup) for manipulation
			var container:TransformGroup = new TransformGroup();
			var cube:Box = new Box("cube", CUBE_SIZE, CUBE_SIZE, CUBE_SIZE);
			cube.z = 0.5 * CUBE_SIZE;
			cube.appearance = new Appearance(this.getMaterialByPatternId(marker.patternId));
			container.addChild(cube);
			this.scene3D.root.addChild(container);
			
			// associate container with corresponding marker
			this.containersByMarker[marker] = container;
		}
		
		public function removeMarker (marker:FLARMarker) :void {
			if (!this.disposeMarker(marker)) { return; }
			
			// find and remove corresponding container
			var container:TransformGroup = this.containersByMarker[marker];
			if (container) {
				container.remove();
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
		
		/*
		private function initEnvironment (flarManager:FLARManager, viewportSize:Rectangle) :void {
			this.scene3D = new Scene3D();
			
			this.camera3D = new FLARCamera_Away3D(flarManager, viewportSize);
			
			this.view = new View3D({x:0.5*viewportSize.width, y:0.5*viewportSize.height, scene:this.scene3D, camera:this.camera3D});
			this.addChild(this.view);
			
			// thanks to holde from the FLARToolkit forums for help with Away3D lighting!
			this.light = new DirectionalLight3D({x:-1000, y:1000, z:-1000, brightness:1});
			this.scene3D.addChild(light);
			
			this.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		*/
		private function initEnvironment (flarManager:FLARManager, viewportSize:Rectangle) :void {
			this.viewport = new Sprite();
			this.viewport.scaleX = viewportSize.width / flarManager.flarSource.sourceSize.width;
			this.viewport.scaleY = viewportSize.height / flarManager.flarSource.sourceSize.height;
			
			this.camera3D = new FLARCamera_Sandy(flarManager, viewportSize);
			
			this.scene3D = new Scene3D("scene3D", this.viewport, this.camera3D, new Group());
			
			this.addChild(this.viewport);
			
			this.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		
		private function onEnterFrame (evt:Event) :void {
			this.updateCubes();
			this.scene3D.render();
		}
		
		private function updateCubes () :void {
			// update all Cube containers according to the transformation matrix in their associated FLARMarkers
			var i:int = this.activePatternIds.length;
			var markerList:Vector.<FLARMarker>;
			var marker:FLARMarker;
			var container:TransformGroup;
			var j:int;
			while (i--) {
				markerList = this.markersByPatternId[this.activePatternIds[i]];
				j = markerList.length;
				while (j--) {
					marker = markerList[j];
					container = this.containersByMarker[marker];
					container.resetCoords();
					container.matrix = SandyGeomUtils.convertMatrixToSandyMatrix(marker.transformMatrix, this.bMirrorDisplay);
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
		
		private function getMaterialByPatternId (patternId:int) :ColorMaterial {
			var attr:MaterialAttributes = new MaterialAttributes(new LightAttributes(true, 0.1));
			var material:ColorMaterial = new ColorMaterial(0xFFFFFF, 1.0, attr);
			material.lightingEnable = true;
			
			switch (patternId) {
				case 0:
					material.color = 0xFF1919;
					break;
				case 1:
					material.color = 0xFF19E8;
					break;
				case 2:
					material.color = 0x9E19FF;
					break;
				case 3:
					material.color = 0x192EFF;
					break;
				case 4:
					material.color = 0x1996FF;
					break;
				case 5:
					material.color = 0x19FDFF;
					break;
				case 6:
					material.color = 0x19FF5A;
					break;
				case 7:
					material.color = 0x19FFAA;
					break;
				case 8:
					material.color = 0x6CFF19;
					break;
				case 9:
					material.color = 0xF9FF19;
					break;
				case 10:
					material.color = 0xFFCE19;
					break;
				case 11:
					material.color = 0xFF9A19;
					break;
				case 12:
					material.color = 0xFF6119;
					break;
				default:
					material.color = 0x00CCCC;
			}
			
			return material;
		}
	}
}