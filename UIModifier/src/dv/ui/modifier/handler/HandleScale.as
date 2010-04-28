/**
 * Handler for scaling
 *  
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 * 
 */

package dv.ui.modifier.handler
{
	import dv.events.HandleEvent;
	import dv.utils.UIModifierFrameTicker;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	[ExcludeClass]
	public final class HandleScale extends MouseHandler
	{
		
		private var _id:String;
		private var _bounds:Rectangle;
		
		public static const RIGHT_BOTTOM:String = 'right_bottom';
		public static const LEFT_BOTTOM:String = 'left_bottom';
		public static const RIGHT_TOP:String = 'right_top';
		public static const LEFT_TOP:String = 'left_top';
		
		public static const LEFT:String = 'left';
		public static const RIGHT:String = 'right';
		public static const TOP:String = 'top';
		public static const BOTTOM:String = 'bottom';
		
		public function HandleScale ()
		{
			super();
		}
		
		public function set pid(value:String):void
		{
			_id = value;
		}
		
		
		public function set bounds ( value:Rectangle ):void
		{
			_bounds = value;
		}

		override protected function startModifier(event:MouseEvent):void
		{
			startDrag(false,_bounds);
			parent.stage.addEventListener(MouseEvent.MOUSE_UP,releaseScale);
			UIModifierFrameTicker.getInstance().addEventListener(UIModifierFrameTicker.FRAME_TICK, updatePosition, false, 0, true);
			
			super.startModifier(event);
		}
		
		private function updatePosition(event:Event):void
		{
			x = Math.round(x);
			y = Math.round(y);
			dispatchEvent( new HandleEvent( HandleEvent.MOVED,x,y,_id));
		}
		
		private function releaseScale(event:MouseEvent):void
		{
			stopDrag();
			UIModifierFrameTicker.getInstance().removeEventListener(UIModifierFrameTicker.FRAME_TICK ,updatePosition);
			hideCursor(null);
		}
	}
}