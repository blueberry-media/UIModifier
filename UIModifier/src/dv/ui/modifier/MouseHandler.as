/**
 * Base object for all handlers
 *  
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 * 
 */

package dv.ui.modifier
{
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	import mx.managers.CursorManager;

	public class MouseHandler extends UIComponent
	{
		
		private var _cursor:Class;
		private var _cursorID:Number;
		private var bitmap:DisplayObject
		
		public function MouseHandler()
		{
			super();
		}
		
		/**
		 * Set the graphic
		 * 
		 * @param graphic
		 * 
		 */
		public function set visual(graphic:Class):void
		{
			bitmap = new graphic();
			addChild(bitmap);
			width = bitmap.width;
			height = bitmap.height;
			bitmap.addEventListener(MouseEvent.MOUSE_DOWN,startModifier)
			bitmap.addEventListener(MouseEvent.MOUSE_OVER,showCursor)
			bitmap.addEventListener(MouseEvent.MOUSE_OUT,hideCursor)
		}
		
		/**
		 * Set the cursor
		 *  
		 * @param graphic
		 * 
		 */
		public function set cursor(graphic:Class):void
		{
			_cursor = graphic;
		}
		
		/**
		 * On mouse down the mouse over and out events are disabled
		 *  
		 * @param event
		 * 
		 */
		protected function startModifier(event:MouseEvent):void
		{
			parent.stage.addEventListener(MouseEvent.MOUSE_UP,stopModifier)
			bitmap.removeEventListener(MouseEvent.MOUSE_OVER,showCursor)
			bitmap.removeEventListener(MouseEvent.MOUSE_OUT,hideCursor)
		}
		
		/**
		 * On mouse up the over and out events are restored
		 *  
		 * @param event
		 * 
		 */
		protected function stopModifier(event:MouseEvent):void
		{
			parent.stage.removeEventListener(MouseEvent.MOUSE_UP,stopModifier)
			bitmap.addEventListener(MouseEvent.MOUSE_OVER,showCursor)
			bitmap.addEventListener(MouseEvent.MOUSE_OUT,hideCursor)
		}
		
		/**
		 * Show the cursor
		 *  
		 * @param event
		 * 
		 */
		protected function showCursor(event:MouseEvent):void
		{
			_cursorID = CursorManager.setCursor(_cursor);
		}
		
		/**
		 * Hide the cursor
		 *  
		 * @param event
		 * 
		 */
		protected function hideCursor(event:MouseEvent):void
		{
			CursorManager.removeCursor(_cursorID);
		}
	}
}