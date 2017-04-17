package  {
	
	public class SimpleUnitTest 
	{
		private var _report:String = "";
		private var assertCounter:int = 0;
		public var _title:String;

		public function SimpleUnitTest(title:String = null) 
		{
			_title = title;
		}
		
		public function assert(condition:Boolean, trueMessage:String, falseMessage:String)
		{
			assertCounter += 1;
			_report += "Assert ID " + assertCounter + "\n";
			_report += condition == true ? trueMessage : falseMessage;
			_report += "\n";
		}
		
		public function getReport():String
		{
			var header:String = _title == null ? "SimpleUnitTest Report" : _title;
			return header + "\n" + _report;
		}
	}
}
