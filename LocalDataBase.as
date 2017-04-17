package  
{
	import flash.data.SQLStatement;
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.events.SQLEvent;
	import flash.events.Event;
	import flash.events.SQLErrorEvent;
	import flash.utils.*;
	import flash.filesystem.File;
	import flash.data.SQLMode;
	import flash.utils.ByteArray;

		/** 
		* LocalDataBase.as
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
 		* Work with the class has number of features:
		* 1. To initialize a class instance, you need to call the constructor, passing the name of the existing or new database, if it was not created; and a database encryption key of the ByteArray type, which is an optional parameter. If encryption key specified, encryption will be applied to the newly created database;
		* 2. Calling the chain of methods on one modified instance adopt with good practices of working with SQL queries and priority procedures;
		* 3. Due to the difference between ActionScript3 and SQLite3 types, when designing a class as table row, take into account that only public properties of the class can be transformed to table columns. Following types are permissible: Date, Boolean, int, uint, String. All other types will be ignored and discarded at table generation;
		* 4. Each class which planned to generate table or intended to use for data transfer must contain a public property named as "id" of int type.
 		*/	
		
	public class LocalDataBase
	{
		/*FIELDS*/
		public var logger				:ILogger;
		private var commandStack		:Vector.<LocalDataBaseCommand>;
		private var executedCommandStack:Vector.<LocalDataBaseCommand>;
		
		private var commandCounter		:int = -1;
		private var _dbPath				:String;
		private var _encryptionKey		:ByteArray
		
		private var conn				:SQLConnection;
		private var sttmnt				:SQLStatement;
		private var dbFile				:File;
		private var fm					:FileManager;
		
		private var conn_open			:Boolean = false;
		private var needToCreateDb		:Boolean = false;
		private var runSQLCommandExecution:Boolean = false;
		
		/*CONSTRUCTOR*/
		/** 
 		* Creates or connects to specified local database.
 		* @constructor
 		* @param {String} dbPath - path or name of database being created or connected.
		* @param {ByteArray} encryptionKey (default = null) - encryption key for database file. 
		* If the LocalDataBase constructor call creates a database, the database is encrypted and the specified key
		* is used as the encryption key for the database. If the call opens an encrypted database, 
		* the value must match the database's encryption key or an error occurs. If the database being 
		* opened is not encrypted, the value must be null (the default) or an error occurs.
 		*/
		public function 	LocalDataBase			(dbPath:String, encryptionKey:ByteArray = null) 
		{
			conn 					= new SQLConnection();
			sttmnt 					= new SQLStatement();
			sttmnt.sqlConnection 	= conn;
			
			//commandIndex 			= 0;
			commandStack 			= new Vector.<LocalDataBaseCommand>();
			executedCommandStack 	= new Vector.<LocalDataBaseCommand>();			
			_dbPath 				= dbPath;
			_encryptionKey 			= encryptionKey;
			fm 						= new FileManager(_dbPath);
			
			
			fm.addEventListener(FileManagerEvent.EXISTS, 		attachDB);
			fm.addEventListener(FileManagerEvent.NOT_EXISTS, 	createDB);
			
			fm.openFile();
		}
		
		
		
		/*METHODS*/
		/*METHODS > EVENT LISTENERS*/
		
		/** 
 		* Attaches database after FileManager establishe local database file. Returns nothing (void).
		* Adding connectSuccess and connectFailure listeners to LocalDataBase SQLConnection instance.
		* Protected Method available only to the this class and to any subclasses of that class.
 		* @function
 		* @param {FileManagerEvent} event (default = null) - passing on FileManagerEvent.EXISTS occur.
 		*/
		protected function 	attachDB				(event:FileManagerEvent = null)	:void
		{
			conn.addEventListener(SQLEvent.OPEN, 		connectSuccess);
			conn.addEventListener(SQLErrorEvent.ERROR, 	connectFailure);
			
			if (_encryptionKey == null)
			{
				conn.openAsync(fm.getFile());
			}
			else
			{
				conn.openAsync(fm.getFile(), SQLMode.CREATE, null, false, 1024, _encryptionKey);
			}
		}
		
		/** 
 		* Creates database after FileManager didn't find local database file. Returns nothing (void).
		* When FileManager send "NOT_EXISTS" event, this method call FileManager createFile() method.
		* If at second time "NOT_EXISTS" event occur, this method throw LocalDataBaseError. This indicates
		* a problems with file system operation.
		* Protected Method available only to the this class and to any subclasses of that class.
 		* @function
 		* @param {FileManagerEvent} event (default = null) - passing on FileManagerEvent.EXISTS occur.
 		*/
		protected function 	createDB				(event:FileManagerEvent = null)	:void
		{
			if ( needToCreateDb == false )
			{
				needToCreateDb = true;
				var methMess:String = "FileManager did not find db on this location: "+ _dbPath + ". A new DB will be created. ";
				logger == null ? trace(methMess) : logger.LogHTMLText(methMess);
			
				fm.createFile();
				
			}
			else
			{
				fm.removeEventListener(FileManagerEvent.EXISTS, 		attachDB);
				fm.removeEventListener(FileManagerEvent.NOT_EXISTS, 	createDB);
								
				throw new LocalDataBaseError(LocalDataBaseError.DB_creation_cycled_12003 + _dbPath, 12003);
			}
		}
		
		/** 
 		* Armed commandQueueController() method. Returns nothing (void).
		* In normal call sequence attachDB method add this connectSuccess method as event listener on SQLEvent.OPEN.
		* Private Method available only to this class.
 		* @function
 		* @param {SQLEvent} event - passing on SQLEvent.OPEN occur.
 		*/
		private function 	connectSuccess			(event:SQLEvent)			:void
		{
			logger == null ? trace("connectSuccess(); ") : logger.LogHTMLText("connectSuccess(); ");
			
			conn_open = true;
			
			conn.removeEventListener(SQLEvent.OPEN, 		connectSuccess);
			conn.removeEventListener(SQLErrorEvent.ERROR, 	connectFailure);
			
			sttmnt.sqlConnection 	= conn;
			
			if (!runSQLCommandExecution && conn_open)
			{
				runSQLCommandExecution = true;
				commandQueueController();
			}
		}
		
		/** 
 		* Throw LocalDataBaseError. Returns nothing (void).
		* In normal call sequence attachDB method add this connectFailure method as event listener on SQLErrorEvent.ERROR.
		* Private Method available only to this class.
 		* @function
 		* @param {SQLEvent} event - passing on SQLErrorEvent.ERROR occur.
 		*/
		private function 	connectFailure			(event:SQLErrorEvent)		:void
		{
			throw new LocalDataBaseError(LocalDataBaseError.Connection_failure_12000 + _dbPath, 12001);
		}
		
		/** 
 		* Calls in response to the execution of a SQL statement. Returns nothing (void).
		* Remove itself to listening SQL results, cut first SQL commandStack element as 
		* accomplished and copy it to executedCommandStack. Rearmed commandQueueController method.
		* This method calls stored in LocalDataBaseCommand ObjectListenerMethod and passing sql result data to it.
		* Private Method available only to this class.
 		* @function
 		* @param {SQLEvent} event - passing on SQLEvent.RESULT occur.
 		*/
		private function 	sqlResult				(event:SQLEvent)			:void
		{
			//logger == null ? trace("sqlResult(); ") : logger.LogHTMLText("sqlResult(); ");
			
			sttmnt.removeEventListener(SQLEvent.RESULT, 		sqlResult);
			sttmnt.removeEventListener(SQLErrorEvent.ERROR, 	sqlError);
			
			if ( commandStack.length > 0 )
			{
				commandStack[0].commandStarted = false;
				commandStack[0].commandFinished = true;
				
				var sqlResult:SQLResult = sttmnt.getResult();
				
				var tObj :Object = commandStack[0].objectListener;
				var listenerName = commandStack[0].objectListenerMethodName;
				
				if(sqlResult!= null && listenerName != null && listenerName != "" && tObj != null)
				{
					var resultData = SQLToObjTransformer(sqlResult, commandStack[0].resultVectorClass);
												 
					tObj[listenerName](resultData);
				}
				executedCommandStack.push(commandStack[0]);
				commandStack.splice(0,1);
			}
			commandQueueController();
		}
		
		/** 
 		* Throw LocalDataBaseError. Returns nothing (void).
		* Calls when SQLConnection instance or SQLStatement instance dispatched error while performing a database 
		* operation in asynchronous execution mode.
		* Private Method available only to this class.
 		* @function
 		* @param {SQLEvent} event - passing on SQLErrorEvent.ERROR occur.
 		*/
		private function 	sqlError				(event:SQLErrorEvent)		:void
		{
			sttmnt.removeEventListener(SQLEvent.RESULT, 		sqlResult);
			sttmnt.removeEventListener(SQLErrorEvent.ERROR, 	sqlError);

			throw new LocalDataBaseError(LocalDataBaseError.SQL_Error_12001+event.error.message, 12001);
		}
				
		
		
		/*METHODS > SERVICE IMPLEMENTATION*/
		
		/** 
 		* Method passes through commandStack vector and extracts LocalDataBaseCommand. Returns nothing (void).
		* Method on each calls extracts LocalDataBaseCommand and reassigns SQLStatement instance.
		* Method on each calls adding sqlResult and sqlError event listeners to basic SQLStatement instance. 
		* Private Method available only to this class.
 		* @function
 		*/
		private function 	commandQueueController	()							:void
		{
			//logger == null ? trace("commandQueueController(); ") : logger.LogHTMLText("commandQueueController(); ");
			
			if ( commandStack.length > 0 )
			{
				var ldbc:LocalDataBaseCommand = commandStack[0];
				sttmnt.clearParameters();
				
				if (ldbc.sqlCommand == null)
				{
					commandStack[0].commandFinished = true;
					executedCommandStack.push(commandStack[0]);
					var tObj :Object = commandStack[0].objectListener;
					var listenerName = commandStack[0].objectListenerMethodName;
					commandStack.splice(0,1);
					tObj[listenerName]();					
					commandQueueController();
				}
				else
				{
					sttmnt = ldbc.sqlCommand;
					sttmnt.sqlConnection = conn;
					sttmnt.addEventListener(SQLEvent.RESULT, 		sqlResult);
					sttmnt.addEventListener(SQLErrorEvent.ERROR, 	sqlError);
					ldbc.commandStarted = true;
					sttmnt.execute();
				}
				//commandIndex += 1;
			}
			else
			{
				runSQLCommandExecution = false;
			}
		}
		
		/** 
 		* Not implemented.
		* Private Method available only to this class.
 		* @function
 		*/
		private function 	commandRollback			()							:void
		{
			
		}

		/** 
 		* Method creates new LocalDataBaseCommand instance and adding it to commandStack. Returns nothing (void).
		* Method armed commandQueueController method.
		* Private Method available only to this class.
 		* @function
		* @param {SQLStatement} sqlCommand - SQL statement of query.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
		* @param {Class} resultVectorClass (default = null) - Class object that points to what typed vector class that must be generated to return the result of the SQL query.
 		*/
		private function 	commandRegister			(sqlCommand:SQLStatement, objectListener:Object = null, methodName:String = null, resultVectorClass:Class = null)		:void
		{
			//logger == null ? trace("commandRegister(); ") : logger.LogHTMLText("commandRegister(); ");
			
			var ldbc:LocalDataBaseCommand 	= new LocalDataBaseCommand();
			ldbc.id 						= commandCounter+1;
			ldbc.sqlCommand 				= sqlCommand;
			ldbc.objectListener 			= objectListener;
			ldbc.objectListenerMethodName 	= methodName;
			ldbc.resultVectorClass 			= resultVectorClass;
			commandStack.push(ldbc);
			
			if (!runSQLCommandExecution && conn_open)
			{
				runSQLCommandExecution = true;
				commandQueueController();
			}
		}
		
		/** 
 		* Method converts SQL result to specific type. Returns typed Vector (vector.<*>).
		* Vector base type assign on method calls by 'c' parameter. This method is called only by sqlResult method - event listener.
		* Private Method available only to this class.
 		* @function
		* @param {Object} sqlResult - SQL result.
		* @param {Class} c  - Class object that points to what typed vector class that must be generated to return the result of the SQL query.
 		*/
		private function 	SQLToObjTransformer		(sqlResult:Object, c:Class)	:Object
		{
			//logger == null ? trace("SQLToObjTransformer(); ") : logger.LogHTMLText("SQLToObjTransformer(); ");
			
			var sqlData = sqlResult.data;
			
			if (sqlData != null)
			{
				var Slacc:Class = c;
				var v = typedVectorGenerator(c);
				
				for (var i=0; i< sqlData.length; i++)
				{
					var t = sqlData[i];
					var o = new c();
					
					for (var j in t)
					{
						o[j] = t[j];
					}
					v.push(o);
				}
			}
			return v;
		}
		
		/** 
 		* Method filtred only id field. Returns boolean.
		* Method used to ignore 'id' class field name for table columns generation as default column.
		* Private Method available only to this class.
 		* @function
		* @param {String} t - field name.
 		*/
		private function 	SQLNameIsCompatible		(t:String)					:Boolean
		{
			if(t == "id")
			{
				return false;
			}
			return true;
		}
		
		/** 
 		* Method filtred vector and array types. Returns boolean.
		* Method used to ignore vector and array types of class field as incompatible types for table columns.
		* Private Method available only to this class.
 		* @function
		* @param {String} t - type name.
 		*/
		private function 	SQLTypeIsCompatible		(t:String)					:Boolean
		{
			if(t.indexOf("__AS3__.vec::Vector")==0 || t == "Array")
			{
				return false;
			}
			return true;
		}
		
		/** 
 		* Method filtred only simple permissible types for SQL. Returns boolean.
		* Method used to ignore vector, array and custom types of class field as incompatible types for table columns.
		* Private Method available only to this class.
 		* @function
		* @param {String} t - type name.
 		*/
		private function 	SQLTypeIsPermissible	(t:String)					:Boolean
		{
			switch (t)
			{
				case "Date":	
				case "Boolean":
				case "int":
				case "uint":
				case "String":			return true;
			}
			return false;
		}
		
		/** 
 		* Method converts names of SQL type to simple AS3 type. Returns string.
		* Private Method available only to this class.
 		* @function
		* @param {String} t - type name.
 		*/
		private function 	SQLTypeTransformer		(t:String)					:String
		{
			switch (t)
			{
				case "Date":	
				case "Boolean":			return t.toUpperCase();
				case "String":			return "TEXT";
			}
			return "INTEGER";
		}
						
		/** 
 		* Method correct class name from packages for SQL table name. Returns string.
		* Private Method available only to this class.
 		* @function
		* @param {String} t - class name.
 		*/
		private function 	classNameCorrectorFor	(t:String)					:String
		{
			var res:String = "Object";
			var delim:Array = t.split("::");
			res = delim[delim.length-1];
			return res;
		}
		
		/** 
 		* Method to avoid SQL Error. Returns associative array of class field names.
		* SQL Error occur when declared table columns sequence does not match with insert request table columns sequence.
		* Private Method available only to this class.
 		* @function
		* @param {Object} obj - object to sort field names.
 		*/
		private function 	getSortedFieldForSQLSequence(obj:Object)			:Array
		{
			//trace("getSortedFieldForSQLSequence");
			var res:Array = new Array();
			var description:XML = describeType(obj);
			var fieldData = description.variable;
								
			for (var i in fieldData)
			{
				res.push({name:fieldData[i].@name, type:fieldData[i].@type, value:obj[fieldData[i].@name]});
			}
			
			res.sortOn("name");
			var idPos:uint = 0;
			for (var t=0; t<res.length; t++)
			{
				if(res[t].name == "id")
				{
					idPos = t;
					break;
				}
			}
			var fname = res[t].name;
			var ftype = res[t].type;
			var fvalue = res[t].value;
			res.splice(t,1);
			/*array bug*/
			res.splice(0,0, {name:fname, type:ftype, value:fvalue});
			return res;
		}
		
		/** 
 		* Method to create vector with specific base type. Returns typed vector.<*>.
		* Private Method available only to this class.
 		* @function
		* @param {Class} _class - base type of vector.
 		*/
		private function 	typedVectorGenerator	(_class:Class)				:*
		{
			if(_class != null)
			{
				/* Based on http://stackoverflow.com/questions/12890387/as3-casting-to-vector */
				var className	:String = getQualifiedClassName(_class);
				var vectorClass	:Class 	= getDefinitionByName("__AS3__.vec::Vector.<"+className+">") as Class;
				return new vectorClass();        
			}
			else
			{
				throw new LocalDataBaseError(LocalDataBaseError.Vector_base_type_must_be_not_null_12006, 12006);
			}
		}
		
		
		
		/*METHODS > SERVICE*/
		
		/** 
 		* Method returns current database path. Returns string.
		* Public Method available to any caller.
 		* @function
 		*/
		public function 	getDBName			()							:String
		{
			return _dbPath;
		}
		
		/** 
 		* Method push objectListener method to command stack. Returns LocalDataBase instance (LocalDataBase).
		* ObjectListener method will be called in the general SQL and/or non SQL command order.
		* Public Method available to any caller.
 		* @function
		* @param {Object} objectListener - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName - name of object method, which must not take an arguments.
 		*/
		public function 	callHere 			(objectListener:Object, methodName:String)						:LocalDataBase
		{
			commandRegister(null , objectListener, methodName);
			return this;
		}
		
		/** 
 		* Method returns string of all commands presence in executed command stack at call. Returns string.
		* Public Method available to any caller.
 		* @function
 		*/
		public function 	printExecutedCommands()							:String
		{
			
			var printStr:String = "";
			
			if(executedCommandStack.length>0)
			{
				printStr = "LocalDataBase executed sql commands report:\n";
			
			for (var i = 0, max = executedCommandStack.length; i < max; i++)
			{
				printStr += "i = " + i + "; \n";
				if (executedCommandStack[i].sqlCommand != null)
				{
					printStr += "sqlCommand.text = " + executedCommandStack[i].sqlCommand.text + "; \n";
				}
				else
				{
					printStr += "sqlCommand = null; \n";
				}
				printStr += "commandStarted = " + executedCommandStack[i].commandStarted + "; \n";
				printStr += "commandFinished = " + executedCommandStack[i].commandFinished + "; \n";
				printStr += "objectListenerMethodName = " + executedCommandStack[i].objectListenerMethodName + "; \n";
				printStr += "resultVectorClass = " + executedCommandStack[i].resultVectorClass + "; \n";
			}
			}
			else
			{
				printStr = "LocalDataBase: no one sql command was executed.";
			}
			return printStr;
		}
		
		/** 
 		* Method creates database table based on class fields. Returns LocalDataBase instance (LocalDataBase).
		* Class name sets to the table. SQLTypeTransformer converts class field types to table column data types.
		* Public Method available to any caller.
 		* @function
		* @param {Class} for_class - base class for table generation.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
 		*/
		public function 	createTable			(for_class:Class, objectListener:Object = null, methodName:String = null)	:LocalDataBase
		{
			var tClass:Class = for_class;
			var t:Object = new tClass();
			
			var sql:String = "CREATE TABLE IF NOT EXISTS ";
	
			var description:XML = describeType(t);
			var className:String = classNameCorrectorFor(getQualifiedClassName(t));

			sql += className;
			sql += " (id INTEGER PRIMARY KEY AUTOINCREMENT";
			
			var objectFieldsSortedArray:Array = getSortedFieldForSQLSequence(t);
						
			logger == null ? trace("createTable(); Name: "+ className) : logger.LogHTMLText("createTable(); Name: "+ className);
										
			for (var f=1; f < objectFieldsSortedArray.length; f++)
			{
					
				var fieldName 		= objectFieldsSortedArray[f].name;
				var fieldClass 		= objectFieldsSortedArray[f].type;

				
				if (SQLNameIsCompatible(fieldName))
				{
					if (SQLTypeIsCompatible(fieldClass) && SQLTypeIsPermissible(fieldClass))
					{
						sql += ", ";
						sql += fieldName + " " + SQLTypeTransformer(fieldClass);
					}
					if (SQLTypeIsCompatible(fieldClass) && !SQLTypeIsPermissible(fieldClass))
					{
						sql += ", ";
						sql += fieldName + " " + SQLTypeTransformer(fieldClass);
					}
				}
			}
			
			sql += ")";
			var sqlStatement:SQLStatement = new SQLStatement();
			sqlStatement.text = sql;
			t = null;
			
			commandRegister(sqlStatement, objectListener, methodName);
			
			return this;
		}
		
		/** 
 		* Method prepare insert statement based on passed typed vector. Returns LocalDataBase instance (LocalDataBase).
		* Vector base type indicates table name, vector elements represent data to insertion.
		* Conflict-algorithm is not used.
		* Public Method available to any caller.
 		* @function
		* @param {Object} vector - typed vector which must be parsed to SQL insert statement.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
 		*/
		public function 	insert				(vector:Object, objectListener:Object = null, methodName:String = null)		:LocalDataBase
		{
			logger == null ? trace("insert(); ") : logger.LogHTMLText("insert(); ");
			
			var sqlStatement:SQLStatement = new SQLStatement();
						
			var letGo		:Boolean = false;
			var union_select:Boolean = false;
			var sql			:String = "INSERT INTO ";
			var table		:String = getQualifiedClassName(vector[0]);
			

				var className:String = getQualifiedClassName(vector);
				
				if (className.indexOf("__AS3__.vec::Vector")==0)
				{
					if ((vector as Vector.<*>).length >0)
					{ 					
						letGo = true;
					}
				}
				else
				{
					throw new LocalDataBaseError(LocalDataBaseError.NON_typed_vector_12005, 12005);
				}
			if(letGo)
			{
				sql += table + " SELECT ";
				
				for (var i=0; i<vector.length; i++)
				{
					var obj:Object = vector[i];
					var objectFieldsSortedArray:Array = getSortedFieldForSQLSequence(obj);
					
					if (union_select)
					{
						sql = sql.slice(0, sql.length-2) + " ";
						sql += "UNION SELECT ";
					}
					for (var f = 0; f < objectFieldsSortedArray.length; f++)
					{
						var addComm:Boolean = false;
						
						var fieldName = objectFieldsSortedArray[f].name;
						var fieldType = objectFieldsSortedArray[f].type;
						var fieldValue = obj[fieldName];
						
						//fieldValue = ifDateThenOptimize(fieldValue, fieldType);
						
						var descrT:XML = describeType(fieldValue);
						
						if (SQLTypeIsCompatible(fieldType) && !SQLTypeIsPermissible(fieldType))
						{
								addComm = true;
								
								try
								{
									fieldValue = fieldValue.id;
								}
								catch(error:Error)
								{
									fieldValue = null;
									throw new LocalDataBaseError(LocalDataBaseError.ID_field_not_found_12002, 12002);
								}
						}
						if ((addComm) || (SQLTypeIsCompatible(fieldType)))
						{
							if (union_select)
							{
								sql += ":"+fieldName+ i +", ";
							}
							else
							{
								sql += ":"+fieldName+ i + " AS " + fieldName+", ";
							}
							sqlStatement.parameters[":"+fieldName+ i ] = fieldValue;
						}
					}
					union_select = true;
				}
				sql = sql.slice(0, sql.length-2);
			}
			sqlStatement.text = sql;
			commandRegister(sqlStatement, objectListener, methodName);
			return this;
		}
		
		/** 
 		* Method prepare insertOrReplace statement based on passed typed vector. Returns LocalDataBase instance (LocalDataBase).
		* Vector base type indicates table name, vector elements represent data to insertion.
		* InsertOrReplace Statement equivalent to using the standard INSERT form with the REPLACE conflict algorithm.
		* Public Method available to any caller.
 		* @function
		* @param {Object} vector - typed vector which must be parsed to SQL insertOrReplace statement.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
 		*/
		public function 	insertOrReplace		(vector:Object, objectListener:Object = null, methodName:String = null)		:LocalDataBase
		{
			logger == null ? trace("insertOrReplace(); ") : logger.LogHTMLText("insertOrReplace(); ");
			
			var sqlStatement:SQLStatement = new SQLStatement();
			
			var letGo		:Boolean = false;
			var union_select:Boolean = false;
			var sql			:String = "INSERT OR REPLACE INTO ";
			var table		:String = getQualifiedClassName(vector[0]);
			
			
				var className:String = getQualifiedClassName(vector);
				
				if (className.indexOf("__AS3__.vec::Vector")==0)
				{
					if ((vector as Vector.<*>).length >0)
					{ 					
						letGo = true;
					}
				}
				else
				{
					throw new LocalDataBaseError(LocalDataBaseError.NON_typed_vector_12005, 12005);
				}
			if(letGo)
			{
				sql += table + " SELECT ";
				
				for (var i=0; i<vector.length; i++)
				{
					var obj:Object = vector[i];
					var objectFieldsSortedArray:Array = getSortedFieldForSQLSequence(obj);
					
					if (union_select)
					{
						sql = sql.slice(0, sql.length-2) + " ";
						sql += "UNION SELECT ";
					}
					for (var f = 0; f < objectFieldsSortedArray.length; f++)
					{
						var addComm:Boolean = false;
						
						var fieldName = objectFieldsSortedArray[f].name;
						var fieldType = objectFieldsSortedArray[f].type;
						var fieldValue = obj[fieldName];
						
						//fieldValue = ifDateThenOptimize(fieldValue, fieldType);
						
						var descrT:XML = describeType(fieldValue);
						
						if (SQLTypeIsCompatible(fieldType) && !SQLTypeIsPermissible(fieldType))
						{
								addComm = true;
								
								try
								{
									fieldValue = fieldValue.id;
								}
								catch(error:Error)
								{
									fieldValue = null;
									throw new LocalDataBaseError(LocalDataBaseError.ID_field_not_found_12002, 12002);
								}
						}
						if ((addComm) || (SQLTypeIsCompatible(fieldType)))
						{
							if (union_select)
							{
								sql += ":"+fieldName+ i +", ";
							}
							else
							{
								sql += ":"+fieldName+ i + " AS " + fieldName+", ";
							}
							sqlStatement.parameters[":"+fieldName+ i ] = fieldValue;
						}
					}
					union_select = true;
				}
				sql = sql.slice(0, sql.length-2);
			}
			sqlStatement.text = sql;	
			commandRegister(sqlStatement, objectListener, methodName);
			return this;
		}
		
		/** 
 		* Method prepare 'select * from table where condition' sql statement for specified tableClass and condition. Returns LocalDataBase instance (LocalDataBase).
		* Unsafe method. 
		* Public Method available to any caller.
 		* @function
		* @param {Class} tableClass - database table base class.
		* @param {Object} objectListener - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName - name of object method, which receives the results of sql command execution.
 		*/
		public function 	selectWithCondition	(tableClass:Class, condition:String, objectListener:Object, methodName:String):LocalDataBase
		{
			logger == null ? trace("selectWithCondition(); ") : logger.LogHTMLText("selectWithCondition(); ");
			
			var sqlStatement:SQLStatement = new SQLStatement();
			var table		:String = getQualifiedClassName(tableClass);	
			var sql			:String = "SELECT * FROM "+table+" WHERE "+condition;
			sqlStatement.text = sql;
			
			commandRegister(sqlStatement, objectListener, methodName, tableClass);
			return this;
		}
		
		/** 
 		* Method get last id for specified tableClass. Returns LocalDataBase instance (LocalDataBase).
		* Public Method available to any caller.
 		* @function
		* @param {Class} tableClass - database table base class.
		* @param {Object} objectListener - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName - name of object method, which receives the results of sql command execution 
		* (Object with ["MAX(id)"] field name!)
 		*/
		public function 	getLastId		(tableClass:Class, objectListener:Object, methodName:String)					:LocalDataBase
		{
			logger == null ? trace("getLastId(); ") : logger.LogHTMLText("getLastId(); ");
			
			var sqlStatement:SQLStatement = new SQLStatement();
			var table		:String = getQualifiedClassName(tableClass);	
			var sql:String = "SELECT MAX(id) FROM "+table;	
			sqlStatement.text = sql;
			
			commandRegister(sqlStatement, objectListener, methodName, Object);
			return this;
		}
		
		/** 
 		* Method prepare update statement based for passed object. Returns LocalDataBase instance (LocalDataBase).
		* Object type indicate table name. All object data (properties/fields of simple types) updates relevant table row.
		* Public Method available to any caller.
 		* @function
		* @param {Object} object - object which data must be updated in the relevant table.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
 		*/
		public function 	update		(object:Object, objectListener:Object = null, methodName:String = null)				:LocalDataBase
		{
			logger == null ? trace("update(); ") : logger.LogHTMLText("update(); ");
			
			var sqlStatement:SQLStatement = new SQLStatement();
			var table:String = getQualifiedClassName(object);
			var sql:String = "";
			
				if (SQLTypeIsCompatible(table))
				{
					sql += "UPDATE "+table+" SET ";
					var objectFieldsSortedArray:Array = getSortedFieldForSQLSequence(object);
					
					for (var f = 0; f < objectFieldsSortedArray.length; f++)
					{
						var fieldName = objectFieldsSortedArray[f].name;
						var fieldType = objectFieldsSortedArray[f].type;
						var fieldValue = object[fieldName];
						
						if (SQLTypeIsCompatible(fieldType) && !SQLTypeIsPermissible(fieldType))
						{
								try
								{
									fieldValue = fieldValue.id;
								}
								catch(error:Error)
								{
									fieldValue = null;
									throw new LocalDataBaseError(LocalDataBaseError.ID_field_not_found_12002, 12002);
								}
						}
						if (fieldName != "id" && SQLTypeIsCompatible(fieldType))
						{
							sql += fieldName+" = :"+fieldName +", ";
							
							sqlStatement.parameters[":"+fieldName] = fieldValue;
						}
					}
					sql = sql.slice(0, sql.length-2);
					
					try
					{
						sql += " WHERE id = :id";
						sqlStatement.parameters[":id"] =  object.id;
					}
					catch(error:Error)
					{
						throw new LocalDataBaseError(LocalDataBaseError.ID_field_not_found_12002, 12002);
					}
				}
				else
				{
					throw new LocalDataBaseError(LocalDataBaseError.Incompatible_type_12007, 12007);
				}
			sqlStatement.text = sql;	
			commandRegister(sqlStatement, objectListener, methodName);
			return this;
		}
		
		/**
		* Method prepare DROP TABLE statement to remove a table added with a CREATE TABLE statement. Returns LocalDataBase instance (LocalDataBase).
		* The table with the specified table-name is the table that's dropped. It is completely removed from the database and the disk file. 
		* The table cannot be recovered. All indices associated with the table are also deleted.
		* @function
		* @param {Class} tableOrClassName - base class indicate table which must be dropped.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
		*/
		public function 	dropTable	(tableOrClassName:Class, objectListener:Object = null, methodName:String = null)	:LocalDataBase
		{
			logger == null ? trace("dropTable(); ") : logger.LogHTMLText("dropTable(); ");
			
			var sqlStatement:SQLStatement = new SQLStatement();
			var table:String = getQualifiedClassName(tableOrClassName);
			var sql:String = "DROP TABLE IF EXISTS "+table;
			sqlStatement.text = sql;	
			
			commandRegister(sqlStatement, objectListener, methodName);
			return this;
		}
		
		/**
		* Method erase all data in the relevant database table. Returns LocalDataBase instance (LocalDataBase).
		* Method equivalent to sql statement 'delete from table' without a WHERE clause - all rows of the table are removed.
		* @function
		* @param {Class} tableOrClassName - base class indicate table which must be cleared.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
		*/
		public function 	clearTable	(tableOrClassName:Class, objectListener:Object = null, methodName:String = null)	:LocalDataBase
		{
			logger == null ? trace("clearTable(); ") : logger.LogHTMLText("clearTable(); ");
			
			var sqlStatement:SQLStatement = new SQLStatement();
			var table:String = getQualifiedClassName(tableOrClassName);
			var sql:String = "DELETE FROM "+table;
			sqlStatement.text = sql;	
			
			commandRegister(sqlStatement, objectListener, methodName);
			return this;
		}
		
		/** 
 		* Method prepare delete statement based on passed object. Returns LocalDataBase instance (LocalDataBase).
		* Passed object must contain only assigned ID field to delete some data from table.
		* Public Method available to any caller.
 		* @function
		* @param {Object} o - object with assigned id field to delete data from relevant table.
		* @param {Object} objectListener (default = null) - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName (default = null) - name of object method, which receives the results of sql command execution.
 		*/
		public function 	deleteData	(o:Object, objectListener:Object = null, methodName:String = null)			:LocalDataBase
		{
			logger == null ? trace("deleteData(); ") : logger.LogHTMLText("deleteData(); ");
						
			var sql:String = "DELETE FROM "+getQualifiedClassName(o)+" WHERE ID = ";
			var fieldValue:String = "";
						
			if (o.hasOwnProperty("id"))
			{
				sql += o.id;
			}
			else
			{
				throw new LocalDataBaseError(LocalDataBaseError.ID_field_not_found_12002, 12002);
			}
			
			var sqlStatement:SQLStatement = new SQLStatement();
			sqlStatement.text = sql;
			
			commandRegister(sqlStatement, objectListener, methodName);
			
			return this;
		}
		
		/** 
 		* Method prepare 'select * from' sql statement for specified  Class. Returns LocalDataBase instance (LocalDataBase).
		* Public Method available to any caller.
 		* @function
		* @param {Class} tableOrClassName - database table base class.
		* @param {Object} objectListener - object which contains specified ObjectListenerMethodName.
		* @param {String} methodName - name of object method, which receives the results of sql command execution.
 		*/
		public function 	getTable	(tableOrClassName:Class, objectListener:Object, methodName:String)			:LocalDataBase
		{
			logger == null ? trace("getTable(); ") : logger.LogHTMLText("getTable(); ");
						
			var className:String = classNameCorrectorFor(getQualifiedClassName(tableOrClassName));
			var sql:String = "SELECT * FROM "+className;
			
			var sqlStatement:SQLStatement = new SQLStatement();
			sqlStatement.text = sql;

			commandRegister(sqlStatement, objectListener, methodName, tableOrClassName);
			return this;
		}
		
		/*METHODS > OVERRIDED*/
		public function toString():String
		{
			return "LocalDataBase exemplar for DataBase name " + _dbPath;
		}
	}
}

