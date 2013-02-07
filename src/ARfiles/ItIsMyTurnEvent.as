package ARfiles
{
	import flash.events.*;
	public class ItIsMyTurnEvent extends Event
	{
		public static  const MYTURN:String="My_Turn";
		public var markerId:int;
		
		public function ItIsMyTurnEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false){
			super(type);
		}
		public override function clone():Event
		{
			return new ItIsMyTurnEvent(type, bubbles, cancelable);
		}
	}
}