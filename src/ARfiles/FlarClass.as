package ARfiles{
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.camera.FLARCamera_Flash3D;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FLARMarkerEvent;
	import com.transmote.flar.tracker.FLARToolkitManager;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	
	import org.osmf.events.AudioEvent;
	
	import spark.components.BorderContainer;
	import spark.components.Label;
	
	import support.MarkerPlane;
	
	[Bindable]
	public class FlarClass extends Sprite{
		private const imageNumber:int=24;
		
		private var upperLimit:int=4;
		private var lowerLimit:int=0;
		
		private var fm:FLARManager;
		private var camera:FLARCamera_Flash3D;
		private var activeMarker:FLARMarker;
		
		private var scene:Sprite;
		
		//http://www.adobe.com/support/flash/action_scripts/actionscript_dictionary/actionscript_dictionary059.html
		private var basicMarkerPlane:MarkerPlane;
		private var playerHeartsMarkerPlaneArray:Array;
		private var enemyHeartsMarkerPlaneArray:Array;
		
		private var nameArray:Array=new Array("Rock","Paper","Scissors","Lizard","Spock");//pinakas me ta onomata twn epilogwn
		private var defeatsArray:Array=new Array(new Array("Lizard","Scissors"),new Array("Rock","Spock"),new Array("Paper","Lizard"),new Array("Spock","Paper"),new Array("Scissors","Rock"));
		private var verbArray:Array=new Array(new Array("crushes","crushes"),new Array("covers","disproves"),new Array("cut","decapitate"),new Array("poisons","eats"),new Array("smashes","vaporizes"));
		private var ChoicesImagePathArray:Array;
		private var playerHeartImPath:String="./resources/images/pinkheart.png";
		private var enemyHeartImPath:String="./resources/images/cyanheart.png";
		
		public var choiceofplayer:int=-1;
		public var playerHeartNumber:int=0;
		public var enemyHeartNumber:int=0;
		private var previousMarkerID:int=-1;
		
		private var notMyTurn:Boolean=false;
			
		public var feedbackString:String;
		public var currentArray:ArrayCollection;//Xreiazetai se ola ta components gia to localization
		
		//private var timer:Timer = new Timer(5000);//Five seconds for this example  
		
		public function FlarClass(){
			this.x=20;
			this.y=20;
			this.addEventListener(Event.ADDED_TO_STAGE, this.initFLAR);
			this.initImageArray();
			this.basicMarkerPlane=new MarkerPlane("./resources/images/heart.png");
			this.basicMarkerPlane.visible=false;
		}
		
		public function initHeartsBar(heartNum:int,playerBorderWidth:int):void{
			var i:int;
			this.playerHeartNumber = heartNum;
			this.enemyHeartNumber = heartNum;
			
			this.playerHeartsMarkerPlaneArray=new Array(heartNum,MarkerPlane);
			this.enemyHeartsMarkerPlaneArray= new Array(heartNum,MarkerPlane);
			for(i=0;i<heartNum;i++){
				this.playerHeartsMarkerPlaneArray[i]=new MarkerPlane(playerHeartImPath);
				this.playerHeartsMarkerPlaneArray[i].x=playerBorderWidth+this.x+20*i;
				this.playerHeartsMarkerPlaneArray[i].y=this.y;
				this.playerHeartsMarkerPlaneArray[i].scaleX*=0.25;
				this.playerHeartsMarkerPlaneArray[i].scaleY*=0.25;
				this.scene.addChild(this.playerHeartsMarkerPlaneArray[i]);
				this.playerHeartsMarkerPlaneArray[i].visible = true;
			}
			
			for(i=0;i<heartNum;i++){
				this.enemyHeartsMarkerPlaneArray[i]=new MarkerPlane(enemyHeartImPath);
				this.enemyHeartsMarkerPlaneArray[i].x=this.fm.flarCameraSource.width-heartNum*20+20*i;
				this.enemyHeartsMarkerPlaneArray[i].y=this.y;
				this.enemyHeartsMarkerPlaneArray[i].scaleX*=0.25;
				this.enemyHeartsMarkerPlaneArray[i].scaleY*=0.25;
				this.scene.addChild(this.enemyHeartsMarkerPlaneArray[i]);
				this.enemyHeartsMarkerPlaneArray[i].visible = true;
			}
			
			//this.setEnemyHeart(3);
			
			this.lowerLimit=5;
			this.upperLimit=23;
		}
		
		public function deleteHeart():int{
			if(this.playerHeartNumber==0){
				return 0;
			}
			this.playerHeartNumber--;
			this.playerHeartsMarkerPlaneArray[this.playerHeartNumber].visible = false;
			this.playerHeartsMarkerPlaneArray.pop();
			return this.playerHeartNumber;
		}
		
		public function setEnemyHeart(hNumber:int):int{
			var i:int;
			this.enemyHeartNumber==hNumber;
			for(i=0;i<this.enemyHeartNumber;i++){
				if(i<hNumber){
					this.enemyHeartsMarkerPlaneArray[i].visible = true;
				}
				else{
					this.enemyHeartsMarkerPlaneArray[i].visible = false;
				}
			}
			
			this.enemyHeartNumber==hNumber;
			return this.enemyHeartNumber;
		}
		
		public function startDetection():void{
			this.notMyTurn=false;
		}
		
		public function stopDetection():void{
			this.notMyTurn=true;
		}
		
		public function decision(wechose:int,opponentchose:int):int{
			if(wechose==opponentchose){
				feedbackString="You both chose "+nameArray[wechose]+"! Try again!";
				return 0;
			}
			else{
				var position:int=searchArray(wechose,nameArray[opponentchose]);
				var position2:int=searchArray(opponentchose,nameArray[wechose]);
			}
			if(position!=-1){
				feedbackString=this.nameArray[wechose]+" "+this.verbArray[wechose][position]+" "+this.nameArray[opponentchose];
				return 1;
			}
			else{
				feedbackString=this.nameArray[opponentchose]+" "+this.verbArray[opponentchose][position2]+" "+this.nameArray[wechose];
				return 2;
			}
		} 
		
		private function initFLAR(evt:Event):void{
			this.removeEventListener(Event.ADDED_TO_STAGE, this.initFLAR);
			
			//arxikopoihsh tou flarmanager me to flartoolkit san tracking engine kai configuration file to prwto orisma
			try{
			this.fm = new FLARManager("./resources/configuration/flarConfig.xml", new FLARToolkitManager(),this.stage);
			}
			catch(error:Object){}
			// add FLARManager.flarSource to the display list to display the video capture.
			addChild(Sprite(this.fm.flarSource));
			
			this.fm.addEventListener(FLARMarkerEvent.MARKER_ADDED,this.onMarkerAdded);
			this.fm.addEventListener(FLARMarkerEvent.MARKER_UPDATED, this.onMarkerUpdated);
			this.fm.addEventListener(FLARMarkerEvent.MARKER_REMOVED,this.onMarkerRemoved);
			
			//timer.addEventListener(TimerEvent.TIMER, this.timerEventHandler);
			
			// wait for FLARManager to initialize before setting up Papervision3D environment.
			trace("event handlers ha been inited");
			this.fm.addEventListener(Event.INIT, this.onFlarManagerInited);
		}
		
		private function  initImageArray():void{
			var imPath:String="./resources/images/image";
			var tempString:String;
			var k:int=0;
			var i:int=0;
			this.ChoicesImagePathArray=new Array(this.imageNumber,String);
			for(i=0;i<this.imageNumber;i++){
				if(i<10){
					tempString=imPath+k+i;
				}
				else{
					tempString=imPath+i.toString();
				}
				tempString+=".jpg";
				trace("ImPath is:::"+tempString);
				this.ChoicesImagePathArray[i]=tempString;
			}
		}
		
		private function onFlarManagerInited (evt:Event) :void {
			this.fm.removeEventListener(Event.INIT, this.onFlarManagerInited);
			
			this.scene = new Sprite();
			this.addChild(this.scene);
			this.camera = new FLARCamera_Flash3D(this.fm, new Rectangle(0, 0, this.stage.stageWidth, this.stage.stageHeight));
			this.camera.scene = this.scene;
			//this.switchEventListeners();
			//this.timer.start();
		}
		
		//dispatchEvent(new ItIsMyTurnEvent("My_Turn",false,false));
		private function onMarkerAdded (evt:FLARMarkerEvent):void {//emfanisi neou marker		
			this.basicMarkerPlane.visible=false;
			if(this.notMyTurn && evt.marker.patternId!=this.previousMarkerID) return;
			var imagePath:String;
			//this.resetTimer();//this.wrongAnswer();
			trace("ARKROPOLIS: ["+evt.marker.patternId.toString()+"] has been added");
			this.activeMarker = evt.marker;
			this.previousMarkerID=evt.marker.patternId;
			
			if( evt.marker.patternId>=this.lowerLimit &&  evt.marker.patternId<=this.upperLimit){
				imagePath=this.ChoicesImagePathArray[evt.marker.patternId].toString();
			}
			else{
				imagePath=this.ChoicesImagePathArray[23].toString()
			}
			
			this.previousMarkerID=evt.marker.patternId;
			this.initMarkerPlane(imagePath);
			this.choiceofplayer = evt.marker.patternId;
			this.dispatchEvent(new AudioEvent(AudioEvent.VOLUME_CHANGE,true,false));	
		}
		
		private function onMarkerUpdated(evt:FLARMarkerEvent) :void {//ananewsi enos uparxontos marker			
			trace("ARKROPOLIS: ["+evt.marker.patternId.toString()+"] has been updated");
			this.activeMarker = evt.marker;
			this.updateMarkerPlane();
		}
		
		private function onMarkerRemoved(evt:FLARMarkerEvent): void {//afairesh enos marker
			trace("ARKROPOLIS: ["+evt.marker.patternId.toString()+"] has been removed");
			this.basicMarkerPlane.visible=false;//gia optimize tou kwdika
		}
		
		private function initMarkerPlane(imagePath:String):void{//h radom epistrefei ena arithmo metaksu tou 0 kai tou 1 //Math.round(Math.random()*(y-x))+x;, x=0, y=4 	//ref:http://www.actionscript.org/resources/articles/90/1/Maths-Functions-including-Random/Page1.html
			this.basicMarkerPlane=new MarkerPlane(imagePath);
			this.basicMarkerPlane.x=this.activeMarker.x;
			this.basicMarkerPlane.y=this.activeMarker.y;
			this.basicMarkerPlane.rotation=this.activeMarker.rotationZ;
			this.basicMarkerPlane.scaleX=2*this.activeMarker.scale2D;
			this.basicMarkerPlane.scaleY=(1.5)*this.activeMarker.scale2D;
			this.scene.addChild(this.basicMarkerPlane);
			this.basicMarkerPlane.visible = true;
		}
		
		private function updateMarkerPlane():void{
			this.basicMarkerPlane.x=this.activeMarker.x;
			this.basicMarkerPlane.y=this.activeMarker.y;
			this.basicMarkerPlane.rotation=this.activeMarker.rotationZ;
			this.basicMarkerPlane.scaleX=2*this.activeMarker.scale2D;
			this.basicMarkerPlane.scaleY=(1.5)*this.activeMarker.scale2D;
		}
		
		private function searchArray(pos1:int,playerB:String):int{
			var i:int;
			var pos2:int;
			trace("player b is "+ playerB);
			for(i=0;i<2;i++){
				if(this.defeatsArray[pos1][i].toString()==playerB)
					return i;
			}
			return -1;
		}	
		
		/*	private function timerEventHandler(e:TimerEvent):void {
		trace("INACTIVE!!!!!!");
		}
		
		private function resetTimer():void{
		this.timer.stop();
		this.timer.start();
		}*/
		
	}	
}