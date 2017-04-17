package  {
	import flash.data.SQLStatement;
	
	public class LocalDataBaseCommand 
	{
		public var id						:int;
		public var sqlCommand				:SQLStatement;
		public var objectListener			:Object;
		public var objectListenerMethodName	:String;
		public var resultVectorClass		:Class;
		public var commandStarted			:Boolean = false;
		public var commandFinished			:Boolean = false;
		
		public function LocalDataBaseCommand() {}
		
		public function toString():String
		{
			return "LocalDataBaseCommand: id = " + id + "; sqlCommand = " + sqlCommand + "; ";
		}

	}
	
}
