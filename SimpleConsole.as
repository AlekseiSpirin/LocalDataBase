package  
{
	import fl.controls.TextArea;	
	
	public class SimpleConsole implements ILogger
	{
		private var _textArea:TextArea;

		public function SimpleConsole(textArea:TextArea) 
		{
			_textArea = textArea;
		}
		public function LogText(str:String):void
		{
			_textArea.htmlText += "<p>"+str+"</p>";
			_textArea.verticalScrollPosition = _textArea.maxVerticalScrollPosition;
		}
		public function LogHTMLText(str:String):void
		{
			_textArea.htmlText += "<p>"+str+"</p>";
			_textArea.verticalScrollPosition = _textArea.maxVerticalScrollPosition;
		}
		public function flush():void
		{
			_textArea.htmlText = "";
			//_textArea.verticalScrollPosition = _textArea.maxVerticalScrollPosition;
		}

	}
	
}