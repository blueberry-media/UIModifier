package dv.ui.modifier.data
{
	
	public class DisplayProperties
	{
		private var _x : Number;
		private var _y : Number;
		private var _height : Number;
		private var _width : Number;
		private var _rotation : Number;
		
		public function DisplayProperties()
		{
		}
		
		public function get height() : Number
		{
			return _height;
		}
		
		public function set height(value : Number) : void
		{
			_height = value;
		}
		
		public function get rotation() : Number
		{
			return _rotation;
		}
		
		public function set rotation(value : Number) : void
		{
			_rotation = Math.round(value);
		}
		
		public function get width() : Number
		{
			return _width;
		}
		
		public function set width(value : Number) : void
		{
			_width = value;
		}
		
		public function get x() : Number
		{
			return _x;
		}
		
		public function set x(value : Number) : void
		{
			_x = value;
		}
		
		public function get y() : Number
		{
			return _y;
		}
		
		public function set y(value : Number) : void
		{
			_y = value;
		}
	
	}
}