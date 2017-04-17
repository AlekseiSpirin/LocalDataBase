package  
{
	import flash.filesystem.File;
	import flash.events.Event;
	
		/** 
		* FileManager.as
		* First Issue
		* Revision 0
		* Apr 17, 2017
		* 
		* Aleksei Spirin
		* spirin.aleksei.yurevich@gmail.com
		*
		* MIT License
		*
		* Copyright (c) 2017 Aleksei Spirin

		* Permission is hereby granted, free of charge, to any person obtaining a copy
		* of this software and associated documentation files (the "Software"), to deal
		* in the Software without restriction, including without limitation the rights
		* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		* copies of the Software, and to permit persons to whom the Software is
		* furnished to do so, subject to the following conditions:

		* The above copyright notice and this permission notice shall be included in all
		* copies or substantial portions of the Software.

		* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		* SOFTWARE.
 		*/	
	
	public class FileManager extends File
	{
		public var reqFile		:File;
		private var testFile	:File;
		private var сopyPath	:File = File.applicationStorageDirectory;
		private var filePath	:File = new File();
		private var connString	:String;
		
		public function FileManager(connection:String) 
		{
			connString = connection;
		}
		public function getFile()	:File
		{
			return reqFile;
		}
		public function openFile():void
		{
			testFile = File.applicationStorageDirectory.resolvePath(connString);
		
			if (testFile.exists)
			{
				reqFile = testFile;
				dispatchEvent(new FileManagerEvent(FileManagerEvent.EXISTS, reqFile));
			}
			else
			{
				dispatchEvent(new FileManagerEvent(FileManagerEvent.NOT_EXISTS, null));
			}
		}
		public function browseForOpenFile():void
		{
			filePath.browseForOpen("Select SQLite3 DB > " + connString);
			filePath.addEventListener(Event.SELECT, exdbopen);
			filePath.addEventListener(Event.CANCEL, testHandler);
		}
		public function createFile():void
		{
			//trace("createFile: "+ connString);
			reqFile = File.applicationStorageDirectory.resolvePath(connString);
			//trace(File.applicationStorageDirectory.nativePath.toString());
			dispatchEvent(new FileManagerEvent(FileManagerEvent.EXISTS, reqFile));
		}
		private function testHandler(e:Event):void
		{
			reqFile = File.applicationStorageDirectory.resolvePath(connString);
		}
		private function exdbopen(e:Event):void
		{
			if (e.target.name !== connString)
			{
				e.target.browseForOpen("Select SQLite3 DB > "  + connString);
			}
			else
			{
				trace(сopyPath.resolvePath(e.target.name));
				
				try
				{
					e.target.copyTo(сopyPath.resolvePath(e.target.name));
				}
				catch(error:Error)
				{
					trace(error.message);
				}
				openFile();
			}
		}
	}
}