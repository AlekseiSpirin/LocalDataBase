package  
{
	import flash.events.Event;
	
	public class FileManagerEvent extends Event
	{
		
		public static const EXISTS		:String = "EXISTS";
		public static const NOT_EXISTS	:String = "NOT_EXISTS";
		public var result				:Object;
		
		public function FileManagerEvent(type:String, result:Object, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
			this.result = result;
		}
		public override function clone():Event
		{
			return new FileManagerEvent(type, result, bubbles, cancelable);
		}

	}
	
}

