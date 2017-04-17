package  
{
	import fl.controls.TextArea;
	import flash.display.DisplayObject;
    import flash.display.Stage;
	import flash.display.MovieClip;
	import flash.utils.*;
				
	public class SimpleLocalSQLTouch extends MovieClip 
	{
		public static var stage	:Stage;
        public static var root	:DisplayObject;
		public var console		:SimpleConsole;
		public var unitTest		:SimpleUnitTest;
		public var personal		:Vector.<User>;
		
		
		public var dbw:LocalDataBase;
		/** 
 		* LocalDataBase.as usage example.
 		* @constructor
 		*/
		public function SimpleLocalSQLTouch() 
		{
				super();	this.stop();	SimpleLocalSQLTouch.stage = this.stage;		SimpleLocalSQLTouch.root = this;
				
				console 	= new SimpleConsole(this.Console);
				unitTest 	= new SimpleUnitTest("LocalDataBaseTest");
				personal 	= new <User>[];
				
				for (var i = 1; i < 6; i++)
				{
					var u:User 	= new User();
					u.id = i;
					u.userName 	= "userName"+i;
					u.login 	= "login"+i;
					personal.push(u);
				}
				
				var delUser:User = new User();
				delUser.id = 2;
				var userUpdate:User = new User();
				userUpdate.id = 3;
				userUpdate.pass = "my_pass";
				
				for (var i = 0; i < 10; i++)
				{
					var db:LocalDataBase = new LocalDataBase("MyDB"+i+".db");
					db.logger = console;

					db.createTable(User)
					//.callHere(this, "viewStack")
					  .createTable(Post)
						//.callHere(this, "viewStack")
						.insertOrReplace(personal, this, "personalInsertedTest")
						//.insert(personal, this, "personalInsertedTest")
							.dropTable(Post, this, "dropPostTableTest")
								.deleteData(delUser)
									.selectWithCondition(User, "ID = 3", this, "selectWithConditionTest")
										.update(userUpdate, this, "userUpdateTest")
											.getTable(User, this, "receiveUsersTest")
											.callHere(this, "afterAll")
												.getLastId(User, this, "getLastIdTest")
													.clearTable(User, this, "clearTableTest");
					dbw = db;
				}
		}
		
		/** 
 		* Method listener example, called when insert command passed.
 		* @function
 		* @param {Object} resultData - must receive result object.
 		*/
		public function 			personalInsertedTest	(resultData:Object):void
		{
			console.LogHTMLText("<br>");
			console.LogHTMLText("<b>Personal Inserted Occur</b>");
		}
		public function 			receiveUsersTest	(resultData:Object):void
		{
			
			console.LogHTMLText("<br>");
			console.LogHTMLText("<b>receiveUsersTest();</b>");
						
			for (var i = 0 , max = resultData.length; i < max; i++)
			{
				console.LogHTMLText(	SimpleLocalSQLTouch.describeObject(resultData[i])	);	
			}
			
			console.LogHTMLText("<b>Assertion of Users</b>");
			
			var uploadedUser0	:User = personal[0];
			var receivedUser0	:User = resultData[0];
			var receivedUser1	:User = resultData[1];
			var newUser			:User = new User();
						
			unitTest.assert( uploadedUser0.valueOf() == receivedUser0.valueOf() , 	"Users u0 and r0 are equal.", "Users u0 and r0 are not equal.");
			unitTest.assert( uploadedUser0.equals(receivedUser1) , 					"Users u0 and r1 are equal.", "Users u0 and r1 are not equal.");
			unitTest.assert( uploadedUser0.equals(newUser) , 						"Users u0 and nu are equal.", "Users u0 and nu are not equal.");
			unitTest.assert( uploadedUser0 === receivedUser0, 						"Users u0 and r0 are strict equal.", "Users u0 and r0 are not strict equal.");
			unitTest.assert( uploadedUser0 === receivedUser1, 						"Users u0 and r1 are strict equal.", "Users u0 and r1 are not strict equal.");
			
			console.LogHTMLText("<font color='#0066ff'>"+ unitTest.getReport()+"</font>");
			
			
		}
		public function 			viewStack ():void
		{
			console.LogHTMLText("<br>");
			console.LogHTMLText("<b>Stack:</b>");
			console.LogHTMLText("<font color='#0a4b3e'>"+dbw.printExecutedCommands()+"</font>");
		}
		public function 			afterAll		():void
		{
			console.LogHTMLText("<br>");
			console.LogHTMLText("<b>Call after All</b>");
			console.LogHTMLText("<font color='#0a4b3e'>"+dbw.printExecutedCommands()+"</font>");
		}
		public function 			selectWithConditionTest(resultData:Object):void
		{
			console.LogHTMLText("<b>selectWithConditionTest();</b>");
			
			for (var i = 0 , max = resultData.length; i < max; i++)
			{
				console.LogHTMLText(	SimpleLocalSQLTouch.describeObject(resultData[i])	);	
			}
		}
		public function 		getLastIdTest(resultData:Object):	void
		{
			console.LogHTMLText("<b>getLastIdTest();</b>");
			console.LogHTMLText("<p>Last Id = " +	resultData[0]["MAX(id)"]	+ "</p>");
		}
		public function 		userUpdateTest(resultData:Object)	:void
		{
			console.LogHTMLText("<b>userUpdateTest();</b>");
		}
		public function 		dropPostTableTest(resultData:Object):void
		{
			console.LogHTMLText("<b>dropPostTableTest();</b>");
			console.LogHTMLText(	describeObject(resultData)		);
		}
		public function 		clearTableTest(resultData:Object)	:void
		{
			console.LogHTMLText("<b><font color='#85090b'>clearTableTest();</font></b>");
		}
		public static function describeObject	(object:Object)		:String
		{
			var des			:String = "";
			var description	:XML 	= describeType(object);
			var fieldData = description.variable;
			des += "Object fields description:\n";
			des += "Class "+ getQualifiedClassName(object) + "\n{\n";
								
			for (var i in fieldData)
			{
				des += fieldData[i].@name + "\t:"+fieldData[i].@type+"\t = "+object[fieldData[i].@name]+";\n";
			}
			des += "};\n";
			return des;
		}
	}
}
