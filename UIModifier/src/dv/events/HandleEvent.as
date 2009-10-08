/**
 * 
 * Handle Scale event
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

	public class HandleEvent extends Event
	{
		
		public static const MOVED:String = 'handle_moved';
		public static const ROTATED:String = 'handle_rotated';
		
		private var _x:Number;
		private var _y:Number;
		private var _id:String;
		
		public function HandleEvent(type:String, x:Number,y:Number,id:String,bubbles:Boolean=false, cancelable:Boolean=false)
		{
			_x = x
			_y = y
			_id = id
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
		
		public function get id():String
		{
			return _id;
		}
		
		override public function toString():String
		{
			return "[HandleScaleEvent x="+x+", y="+y+", id="+id+"]"
		}
		
	}
}