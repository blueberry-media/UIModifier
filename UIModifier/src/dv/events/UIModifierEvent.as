/**
 * 
 * UIModifier event. Is dispatched everytime the modifier updates.
 * 
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 * 
 */

package dv.events
{
	import flash.events.Event;
	import flash.geom.Point;

	public class UIModifierEvent extends Event
	{
		
		public static const MODIFIED:String = 'modified';
		public static const MODIFIED_DONE:String = 'modified_done';
		
		private var _x:Number
		private var _y:Number
		private var _width:Number
		private var _height:Number
		private var _rotation:Number
		private var _pivot:Point
		
		public function UIModifierEvent(type:String, 
			x:Number , y:Number, width:Number, height:Number ,
			rotation:Number, pivot:Point,
			bubbles:Boolean=false, cancelable:Boolean=false)
		{
			_x = x;
			_y = y;
			_width = width;
			_height = height;
			_rotation = rotation;
			_pivot = pivot;
			super(type, bubbles, cancelable);
		}

		public function get x():Number
		{
			return _x;
		}
		
		public function get y():Number
		{
			return _y;
		}
		
		public function get width():Number
		{
			return _width;
		}
		
		public function get height():Number
		{
			return _height;
		}
		
		public function get rotation():Number
		{
			return _rotation;
		}
		
		public function get pivot():Point
		{
			return _pivot;
		}
		
		override public function toString():String
		{
			return "[UIModifierEvent rotation="+rotation+", width="+width+", height="+height+", x="+x+",y="+y+", pivot="+pivot+"]";
		}	
	}
}