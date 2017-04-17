package  {
	
	/** 
		* LocalDataBaseError.as
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
		*
 		*/	
	
	public class LocalDataBaseError extends Error 
	{
		public static const Connection_failure_12000 	:String = "LDBE 12000: Connection failed. Connection string...";
		public static const SQL_Error_12001				:String = "LDBE 12001...";
		public static const ID_field_not_found_12002	:String = "LDBE 12002: class definition must have id field. ";
		public static const DB_creation_cycled_12003	:String = "LDBE 12003: db creation process is cycled. Aborted. Tryed resolve path... ";
		public static const NON_typed_vector_12005		:String = "LDBE 12005: Only typed vectors can be inserted. ";
		public static const Vector_base_type_must_be_not_null_12006:String = "LDBE 12006: Vector base type Class must be not null!";
		public static const Incompatible_type_12007		:String = "LDBE 12007: Incompatible object type.";

		private var _message:String;
		
		public function LocalDataBaseError(message:String, errorID:int) 
    	{ 
        	super(message, errorID); 
			_message = message;
    	} 
		public function toString():String
		{
			return _message == null ? super.toString() : _message;
		}
	}
}
