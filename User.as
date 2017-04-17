package
{	

	/*For example only!!!*/
	public class User 
	{
		/*FIELDS*/
		public var id					:int;
		public var idPost				:int;
		public var userName				:String;
		public var userSurname			:String;
		public var login				:String;
		/*Do not use pass like this, store only hash. For example only!!!*/
		public var pass					:String;
		public var email				:String;
		public var isAdmin				:Boolean;
		public var isDeleted			:Boolean;
		
		
		/*CONSTRUCTOR*/
		public function 	User()	{}
		
		/*METHODS*/
		public function 	valueOf()				:String
		{
			var _id					:String = id 		== undefined ? "" : id.toString();
			var _idPost				:String = idPost 	== undefined ? "" : idPost.toString();
			var _userName			:String = userName 	== null ? "" : userName;
			var _userSurname		:String = userSurname == null ? "" : userSurname;
			var _login				:String = login 	== null ? "" : userName;
			var _pass				:String = pass 		== null ? "" : pass;		
			var _email				:String = email 	== null ? "" : email;
			var _isAdmin			:String = isAdmin 	== null ? "" : isAdmin.toString();
			var _isDeleted			:String = isDeleted == null ? "" : isDeleted.toString();
			
			/*Do not show pass like this, store only hash. For example only!!!*/
			return _id + _idPost + _userName + _userSurname + _login + _pass + _email + _isAdmin + _isDeleted;
		}
		public function 	equals(object:Object)	:Boolean
		{
			return this.valueOf() == object.valueOf();
		}
	}
}
