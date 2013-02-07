package com.transmote.utils.ui {
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.LoaderContext;
	
	/**
	 * An interface for accessing symbol definitions in the Library
	 * of a SWF embedded in the application.
	 * Modified from Grant Skinner's FlashLib class:
	 * http://www.gskinner.com/blog/archives/2007/03/using_flash_sym.html
	 * 
	 * To init, pass into the constructor a Class instance that refers to a SWF embedded via the Embed meta tag.
	 * Ensure embeddedLibrary is inited before attempting to access symbol classes/instances by handling an
	 * Event.INIT from this instance; failure to wait for init can result in runtime errors.
	 * 
	 * Symbol classes can be accessed via getSymbolDefinition().
	 * Symbol instances can be generated via getSymbolInstance().
	 * 
	 * @author	Eric Socolofsky
	 * @url		http://transmote.com/
	 */
	public class EmbeddedLibrary extends EventDispatcher {
		protected var embeddedLibrary:Class;
		private var loader:Loader;
		
		/**
		 * Constructor.
		 * 
		 * @param	embeddedLibrary		A Class instance that refers to a SWF embedded via the Embed meta tag.
		 */
		public function EmbeddedLibrary (embeddedLibrary:Class) {
			this.embeddedLibrary = embeddedLibrary;
			this.init();
		}
		
		/**
		 * Returns true if the EmbeddedLibrary is fully loaded and initialized,
		 * and the symbols within are prepared for access via Actionscript.
		 */
		public function get inited () :Boolean {
			return (this.loader.content != null);
		}
		
		/**
		 * Generate an instance of the library symbol.
		 * 
		 * @param	className	The symbol's Class name.
		 */
		public function getSymbolInstance (symbolClassName:String) :* {
			var symbolClass:Class = this.getSymbolDefinition(symbolClassName);
			return (symbolClass ? new symbolClass() : null);
		}
		
		/**
		 * Access the library symbol's Class,
		 * which can be used to instantiate symbol instances.
		 * 
		 * @param	className	The symbol's Class name.
		 */
		public function getSymbolDefinition (className:String) :Class {
			try {
				if (this.inited) {
					return (this.loader.contentLoaderInfo.applicationDomain.getDefinition(className) as Class);
				} else {
					return null;
				}
			} catch (e:ReferenceError) {
				//provide slightly more informative error
				throw new ReferenceError("No class '"+ className +"' exists in library swf.");
			}
			return null;
		}
		
		/**
		 * Free up the EmbeddedLibrary for garbage collection.
		 */
		public function dispose () :void {
			this.embeddedLibrary = null;
			if (this.loader) {
				this.loader.contentLoaderInfo.removeEventListener(Event.INIT, this.onInited);
				this.loader.unload();
			}
		}
		
		/**
		 * @private
		 * Must be inited at least one frame before any resources are available;
		 * be sure to call init() well in advance of any attempt to access library resources.
		 */
		private function init () :void {
			this.loader = new Loader();
			this.loader.contentLoaderInfo.addEventListener(Event.INIT, this.onInited);
			
			// AIR requires LoaderContext.allowLoadBytesCodeExecution;
			// but non-AIR applications do not support it.
			var loaderContext:LoaderContext = new LoaderContext();
			//loaderContext.allowLoadBytesCodeExecution = true;
			this.loader.loadBytes(new this.embeddedLibrary(), loaderContext);
		}
		
		private function onInited (evt:Event) :void {
			this.loader.contentLoaderInfo.removeEventListener(Event.INIT, this.onInited);
			this.dispatchEvent(new Event(Event.INIT));
		} 
	}
}