/**
 * UI Modifier can modify width, height, x, y and rotation of every DisplayObject
 * Because Flash doesn't support pivot editing on runtime and therefor has no place
 * to store the pivot data. You have to store it somewhere. The Class dispatches an event
 * by every modification which contains the pivot location. Using the setTarget method
 * you can tell the Class the pivot location otherwise the pivot is always in the
 * centre of the DisplayObject.
 *
 * version 1.0:
 * - Scaling + rotation + position works nicely on every type of DisplayObject of the real
 *   pivot point is located at 0,0
 *
 * version 1.1
 * - added Key events
 * 	CTRL+C -> Copy Event
 * 	CTRL+V -> Paste Event
 * 	ESC    -> Reset to Start
 * 	DELETE -> DELETE Event
 * 	SHIFT  -> Holding shift will scale proportional and will move 10px by keys
 * - Fixed rotation
 * - isCentered this will disable the pivot point and should be used if the objet you want to
 *   transform is centerd in a empty container
 * - fixed minor bugs
 * Known bug if set scalemode = SCALE_PROPORTIONAL,
 * then set a new source the modifier sometimes flips, stragely SHIFT keeps working well in my
 * tests.
 *
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @author Bart Ducheyne [bart at design-lab dot be]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 *
 */

package dv.ui.modifier
{
	
	import dv.events.HandleEvent;
	import dv.events.UIModifierEvent;
	import dv.log.LogInstance;
	import dv.log.Logger;
	import dv.ui.modifier.data.DisplayProperties;
	import dv.ui.modifier.handler.HandleCentre;
	import dv.ui.modifier.handler.HandleRotate;
	import dv.ui.modifier.handler.HandleScale;
	import dv.utils.MathUtils;
	import dv.utils.UIModifierFrameTicker;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.CursorManager;
	import mx.managers.IFocusManagerComponent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	import nbilyk.utils.PivotRotate;
	
	[Event(name="modified", type="dv.events.UIMofifierEvent")]
	
	[IconFile("UIModifier.png")]
	[Inspectable(category="Devigner")]
	
	
	[Style(name="borderColor", type="Number", inherit="no")]
	[Style(name="borderAlpha", type="Number", inherit="no")]
	[Style(name="borderThickness", type="Number", inherit="no")]
	[Style(name="scaleHandle", type="Class", inherit="no")]
	[Style(name="rotateHandle", type="Class", inherit="no")]
	[Style(name="centrePoint", type="Class", inherit="no")]
	[Style(name="cursorLeftRight", type="Class", inherit="no")]
	[Style(name="cursorRightLeft", type="Class", inherit="no")]
	[Style(name="cursorVertical", type="Class", inherit="no")]
	[Style(name="cursorHorizontal", type="Class", inherit="no")]
	[Style(name="cursorMove", type="Class", inherit="no")]
	[Style(name="cursorPivot", type="Class", inherit="no")]
	[Style(name="cursorRotate", type="Class", inherit="no")]
	
	
	public class UIModifier extends UIComponent implements IFocusManagerComponent
	{
		
		[Bindable]
		private var _handle : Class;
		
		[Bindable]
		private var _rotate_handle : Class;
		
		[Bindable]
		private var _centrePoint : Class;
		
		[Bindable]
		private var _cursor_left_right : Class;
		
		[Bindable]
		private var _cursor_right_left : Class;
		
		[Bindable]
		private var _cursor_vertical : Class;
		
		[Bindable]
		private var _cursor_horizontal : Class;
		
		[Bindable]
		private var _cursor_move : Class;
		
		[Bindable]
		private var _cursor_pivot : Class;
		
		[Bindable]
		private var _cursor_rotate : Class;
		
		private var _overlay : UIComponent;
		private var _cross : UIComponent;
		private var _target : DisplayObject = null;
		private var _handles : Object;
		private var _maxBoundries : Rectangle = new Rectangle(0, 0, 1000, 1000);
		private var _minBoundries : Rectangle = new Rectangle(0, 0, 10, 10);
		private var _cursorID : Number;
		private var _centre : HandleCentre
		private var _modifier : UIComponent;
		private var _debug : Boolean = false;
		private var _created : Boolean = false;
		private var _applyModification : Boolean = true;
		private var _resizeCounts : Number = 0;
		private var _resizeTries : Number = 10;
		private var _rotateHandlerSize : Object;
		private var _scaleMode : Number;
		private var _originalScaleMode : Number;
		
		private var _enableRotation : Boolean = true;
		private var _enableScaling : Boolean = true;
		private var _enableMoving : Boolean = true;
		
		//This is a object witch contains the current properties of the target
		//we will update this object realtime and use it to dispatch events, 
		//incase applyModifications is set to true it will also be used to set the 
		//changes to the _target
		private var _targetProperties : DisplayProperties;
		
		private var _storage : Object;
		
		private var _focus : Boolean;
		
		private var _isCentered : Boolean;
		
		private var log : LogInstance = dv.log.Logger.createLogger(this);
		
		
		public static const DIRECTION_X : uint = 1;
		public static const DIRECTION_Y : uint = 2;
		public static const DIRECTION_BOTH : uint = 3;
		
		public static const SCALE_ALL : uint = 1;
		public static const SCALE_PROPORTIONAL : uint = 2;
		
		public static const SCALE_HORIZONTAL : uint = 3;
		public static const SCALE_HORIZONTAL_LEFT : uint = 7;
		public static const SCALE_HORIZONTAL_RIGHT : uint = 8;
		
		public static const SCALE_VERTICAL : uint = 4;
		public static const SCALE_VERTICAL_BOTTOM : uint = 5;
		public static const SCALE_VERTICAL_TOP : uint = 6;
		
		[Embed(source="/assets/graphics.swf", symbol="handle")]
		[Bindable]
		private static var __scaleHandle : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="rotate_handle")]
		[Bindable]
		private static var __rotateHandle : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="centrePoint")]
		[Bindable]
		private static var __centrePoint : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="cursor_left_right")]
		[Bindable]
		private static var __cursorLeftRight : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="cursor_right_left")]
		[Bindable]
		private static var __cursorRightLeft : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="cursor_vertical")]
		[Bindable]
		private static var __cursorVertical : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="cursor_horizontal")]
		[Bindable]
		private static var __cursorHorizontal : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="cursor_move")]
		[Bindable]
		private static var __cursorMove : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="cursor_pivot")]
		[Bindable]
		private static var __cursorPivot : Class;
		
		[Embed(source="/assets/graphics.swf", symbol="cursor_rotate")]
		[Bindable]
		private static var __cursorRotate : Class;
		
		public static const DELETE : String = 'DELETE';
		public static const COPY : String = 'onCopy';
		public static const PASTE : String = 'onPaste';
		public static const DOUBLE_CLICK : String = 'DOUBLE_CLICK_mod';
		// Define a static variable.
		private static var defaultStylesInitialized : Boolean = setDefaultStyles();
		
		private static function setDefaultStyles() : Boolean
		{
			
			var style : CSSStyleDeclaration = StyleManager.getStyleDeclaration("UIModifier");
			if (!style)
			{
				// If there is no CSS definition for StyledRectangle, 
				// then create one and set the default value.
				style = new CSSStyleDeclaration();
				style.defaultFactory = function() : void
				{
					this.borderColor = 0x000000;
					this.borderThickness = 0;
					this.borderAlpha = 1;
					this.scaleHandle = __scaleHandle;
					this.rotateHandle = __rotateHandle
					this.centrePoint = __centrePoint;
					this.cursorLeftRight = __cursorLeftRight;
					this.cursorRightLeft = __cursorRightLeft;
					this.cursorVertical = __cursorVertical;
					this.cursorHorizontal = __cursorHorizontal;
					this.cursorMove = __cursorMove;
					this.cursorPivot = __cursorPivot;
					this.cursorRotate = __cursorRotate;
				}
				StyleManager.setStyleDeclaration("UIModifier", style, true);
			}
			return true;
		}
		
		/**
		 *
		 *
		 */
		public function UIModifier()
		{
			super();
			focusEnabled = true;
			mouseEnabled = true;
			buttonMode = false;
			Logger.useTrace =  _debug;
			//			addEventListener(FocusEvent.FOCUS_IN,focusInHandler);
			UIModifierFrameTicker.getInstance().start(12);
		}
		
		private function doubleClickEvent(event : MouseEvent) : void
		{
			dispatchEvent(new Event(DOUBLE_CLICK));
			stopDragging(event);
		}
		
		override protected function focusInHandler(event : FocusEvent) : void
		{
			log.info("Focus In");
			_focus = true;
			draw();
		}
		
		override protected function focusOutHandler(event : FocusEvent) : void
		{
			log.info("Focus Out")
			_focus = false;
			hideCursor(null);
			draw();
		}
		
		override protected function keyDownHandler(event : KeyboardEvent) : void
		{
			log.info("keyDownHandler");
			var steps : Number = 1;
			if (event.shiftKey)
			{
				steps = 10;
			}
			switch (event.keyCode)
			{
				case Keyboard.SHIFT:
					if (scaleMode == SCALE_ALL)
					{
						_scaleMode = SCALE_PROPORTIONAL;
					}
					break;
				case Keyboard.DOWN:
					y += steps;
					applyModifications();
					break;
				case Keyboard.UP:
					y -= steps;
					applyModifications();
					break;
				case Keyboard.LEFT:
					x -= steps;
					applyModifications();
					break;
				case Keyboard.RIGHT:
					x += steps;
					applyModifications();
					break;
				//V
				case 67:
					if (event.ctrlKey)
					{
						dispatchEvent(new Event(COPY));
					}
					break;
				//C
				case 86:
					if (event.ctrlKey)
					{
						dispatchEvent(new Event(PASTE));
					}
					break;
			}
			event.stopImmediatePropagation()
			event.preventDefault();
		}
		
		override protected function keyUpHandler(event : KeyboardEvent) : void
		{
			switch (event.keyCode)
			{
				case Keyboard.ESCAPE:
					reset();
					break;
				case Keyboard.DELETE:
					dispatchEvent(new Event(DELETE));
					break;
				case Keyboard.SHIFT:
					_scaleMode = _originalScaleMode;
					break;
			}
			log.info("keyUpHandler");
			event.stopImmediatePropagation()
			event.preventDefault();
		}
		
		override protected function createChildren() : void
		{
			super.createChildren();
			createdHandler(null)
		}
		
		override protected function updateDisplayList(unscaledWidth : Number, unscaledHeight : Number) : void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			width = unscaledWidth;
			height = unscaledHeight;
			applyModifications();
		}
		
		override public function invalidateProperties() : void
		{
			super.invalidateProperties();
			//applyModifications();
		}
		
		private function createdHandler(event : FlexEvent) : void
		{
			_handle = getStyle("scaleHandle");
			_rotate_handle = getStyle("rotateHandle");
			_centrePoint = getStyle("centrePoint");
			_cursor_left_right = getStyle("cursorLeftRight");
			_cursor_right_left = getStyle("cursorRightLeft");
			_cursor_vertical = getStyle("cursorVertical");
			_cursor_horizontal = getStyle("cursorHorizontal");
			_cursor_move = getStyle("cursorMove");
			_cursor_pivot = getStyle("cursorPivot");
			_cursor_rotate = getStyle("cursorRotate");
			
			_modifier = new UIComponent();
			addChild(_modifier);
			
			createHandles();
		}
		
		/**
		 * @return Boolean
		 */
		public function get debug() : Boolean
		{
			return _debug;
		}
		
		/**
		 * @param value
		 */
		public function set debug(value : Boolean) : void
		{
			_debug = value;
			Logger.useTrace = value;
		}
		
		/**
		 * @return Boolean
		 */
		public function get scaleMode() : Number
		{
			return _scaleMode;
		}
		
		/**
		 * @param value
		 */
		public function set scaleMode(value : Number) : void
		{
			_scaleMode = value;
			_originalScaleMode = value;
			if (_created)
			{
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Boolean
		 */
		public function get enableRotation() : Boolean
		{
			return _enableRotation;
		}
		
		/**
		 * @param value
		 */
		public function set enableRotation(value : Boolean) : void
		{
			_enableRotation = value;
			if (_created)
			{
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Boolean
		 */
		public function get enableScaling() : Boolean
		{
			return _enableScaling;
		}
		
		/**
		 * @param value
		 */
		public function set enableScaling(value : Boolean) : void
		{
			_enableScaling = value;
			if (_created)
			{
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Boolean
		 */
		public function get enableMoving() : Boolean
		{
			return _enableMoving;
		}
		
		/**
		 * @param value
		 */
		public function set enableMoving(value : Boolean) : void
		{
			_enableMoving = value;
			if (_created)
			{
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Rectangle
		 */
		public function get maxBoundries() : Rectangle
		{
			return _maxBoundries
		}
		
		/**
		 * @param value
		 */
		public function set maxBoundries(value : Rectangle) : void
		{
			_maxBoundries = value;
		}
		
		/**
		 * To use UIModifier you have to pass your DisplayObject which you want to modify
		 * through setTarget
		 *
		 * @param value A displayobject where the graphics are starting at 0,0
		 * @param pivot The starting point where the rotation turns around
		 *
		 */
		public function setTarget(value : DisplayObject, pivot : Point = null, isCentered : Boolean = false) : void
		{
			if (value != null && value != _target)
			{
				stopDragging(null);
				_target = value;
				_targetProperties = new DisplayProperties();
				_targetProperties.x = _target.x;
				_targetProperties.y = _target.y;
				_targetProperties.width = _target.width;
				_targetProperties.height = _target.height;
				_targetProperties.rotation = _target.rotation;
				
				init(pivot, isCentered);
			}
			else
			{
				log.info("Target is null")
			}
		}
		
		/**
		 * To use UIModifier you have to pass the properties of the object you wanne modifie
		 *
		 * @param value A displayobject where the graphics are starting at 0,0
		 * @param pivot The starting point where the rotation turns around
		 *
		 */
		public function setProperties(value : DisplayProperties, pivot : Point = null, isCentered : Boolean = false) : void
		{
			if (value != null)
			{
				stopDragging(null);
				_applyModification = false;
				_targetProperties = value;
				init(pivot, isCentered);
			}
			else
			{
				log.info("_targetProperties is null")
			}
		}
		
		private function init(pivot : Point = null, isCentered : Boolean = false) : void
		{
			if (pivot == null)
			{
				_centre.pivot = new Point(_targetProperties.width / 2, _targetProperties.height / 2);
			}
			else
			{
				_centre.pivot = pivot;
			}
			_isCentered = isCentered;
			_centre.bounds = new Rectangle(0, 0, width, height);
			_centre.canDrag = !_isCentered;
			if (_isCentered)
			{
				rotation = _targetProperties.rotation
				width = _targetProperties.width;
				height = _targetProperties.height;
				///
				var localOppositeLeg : Number = _centre.pivot.x;
				var localAdjacentLeg : Number = _centre.pivot.y;
				var Ls : Number = Math.sqrt((localOppositeLeg * localOppositeLeg) + (localAdjacentLeg * localAdjacentLeg));
				if (_centre.pivot.x < 0)
				{
					Ls = -Ls;
				}
				var Lr : Number = Math.atan(localAdjacentLeg / localOppositeLeg);
				var Gr : Number = MathUtils.degree2radian(rotation) + Lr;
				var Gx : Number = Math.cos(Gr) * Ls;
				var Gy : Number = Math.sin(Gr) * Ls;
				
				x = _targetProperties.x - Gx;
				y = _targetProperties.y - Gy;
				
			}
			else
			{
				x = _targetProperties.x;
				y = _targetProperties.y;
				rotation = _targetProperties.rotation;
				width = _targetProperties.width;
				height = _targetProperties.height;
			}
			_storage = {x: x, y: y, width: width, height: height, rotation: rotation, pivot: pivot}
			//	applyModifications();
			focusManager.setFocus(this);
		}
		
		public function reset() : void
		{
			x = _storage.x;
			y = _storage.y;
			width = _storage.width;
			height = _storage.height;
			rotation = _storage.rotation;
			if (_isCentered || _storage.pivot == null)
			{
				_centre.pivot = new Point(_storage.width / 2, _storage.height / 2);
			}
			else
			{
				_centre.pivot = _storage.pivot;
			}
			applyModifications()
		}
		
		
		/**
		 *
		 * Correction on the rotation because the registration point is virtual the
		 * rotation needs reposition.
		 *
		 * @param event
		 *
		 */
		
		private function updateHandleRotate(event : HandleEvent) : void
		{
			/*
			   a = opposite leg;
			   b = adjacent leg;
			   A = corner;
			   tan ( A ) = a / b;
			   A = atan(a/b);
			 */
			var mouse : Point = new Point(mouseX, mouseY);
			var a : int = mouse.y - _centre.pivot.y;
			var b : int = mouse.x - _centre.pivot.x;
			;
			log.info("corner :" + Math.atan(a / b) + " RAD, " + MathUtils.radian2degree(Math.atan(a / b)));
			var mouseCornerRad : Number = Math.atan(a / b);
			var handlePoint : Point = (event.target as HandleRotate).startPoint;
			a = handlePoint.y - _centre.pivot.y;
			b = handlePoint.x - _centre.pivot.x;
			var startCornerRad : Number = Math.atan(a / b);
			log.info("cornerStartPoint :" + Math.atan(a / b) + " RAD, " + MathUtils.radian2degree(Math.atan(a / b)));
			var changedCornerRad : Number = mouseCornerRad - startCornerRad;
			log.info("Change :" + changedCornerRad + " RAD, " + MathUtils.radian2degree(changedCornerRad));
			
			//Round the degrees to rounded corner and then put it back to rads
			changedCornerRad = MathUtils.degree2radian(Math.round(MathUtils.radian2degree(changedCornerRad)));
			
			//Calculate the position of the center point, in its parent
			var localOppositeLeg : Number = _centre.pivot.x;
			var localAdjacentLeg : Number = _centre.pivot.y;
			var Ls : Number = Math.sqrt((localOppositeLeg * localOppositeLeg) + (localAdjacentLeg * localAdjacentLeg));
			
			if (_centre.pivot.x < 0)
			{
				Ls = -Ls;
			}
			
			var Lr : Number = Math.atan(localAdjacentLeg / localOppositeLeg);
			var Gr : Number = MathUtils.degree2radian(rotation) + Lr;
			var Gx : Number = Math.cos(Gr) * Ls;
			var Gy : Number = Math.sin(Gr) * Ls;
			var offsetWidth : Number = x + Gx; //img.width / 2;
			var offsetHeight : Number = y + Gy; //img.height / 2;
			
			var tempMatrix : Matrix = this.transform.matrix;
			tempMatrix.translate(-offsetWidth, -offsetHeight);
			tempMatrix.rotate(changedCornerRad);
			tempMatrix.translate(+offsetWidth, +offsetHeight);
			
			this.transform.matrix = tempMatrix;
			
			applyModifications();
		}
		
		/**
		 *
		 * Correction on the positioning of the subject in all directions
		 *
		 * @param position
		 * @return
		 *
		 */
		private function calculatePosition(position : Point, direction : Number = 1) : Point
		{
			var xpos : Number;
			var ypos : Number;
			var radians : Number = MathUtils.degree2radian(rotation);
			
			switch (direction)
			{
				case DIRECTION_X:
					xpos = position.x * Math.cos(radians);
					ypos = position.x * Math.sin(radians);
					break;
				case DIRECTION_Y:
					xpos = position.y * Math.sin(-radians);
					ypos = position.y * Math.cos(-radians);
					break;
				case DIRECTION_BOTH:
					var x1 : Number = position.x * Math.cos(radians);
					var x2 : Number = position.y * Math.sin(-radians);
					var y1 : Number = position.x * Math.sin(radians);
					var y2 : Number = position.y * Math.cos(-radians);
					xpos = x1 + x2
					ypos = y2 + y1
					break;
			}
			
			
			if (debug)
			{
				graphics.clear()
				graphics.lineStyle(0, 0xFF0000);
				graphics.moveTo(position.x, position.y)
				graphics.lineTo(xpos, ypos)
			}
			
			return new Point(xpos, ypos);
		}
		
		/**
		 *
		 * Every handle can scale the subject but rotation has effect of scaling because the
		 * actual registration point is not modified and width and height are not the
		 * real values the modification need. Not every handle has trouble with rotation.
		 * The right bottom, bottom and the right handle doesn't need correction
		 * The right top, left bottom, top and the left need one direction correction
		 * The left top needs correction in all directions
		 *
		 * @param event
		 *
		 */
		private function updateHandleMove(event : HandleEvent) : void
		{
			var position : Point
			switch (event.id)
			{
				// Modify properties that always work (rotation has no effect)
				case HandleScale.RIGHT_BOTTOM:
					_handles.right_top.x = event.x
					_handles.left_bottom.y = event.y
					break;
				case HandleScale.BOTTOM:
					_handles.right_bottom.y = event.y
					break;
				case HandleScale.RIGHT:
					_handles.right_bottom.x = event.x
					break;
				
				// Modify properties that need reposition once
				case HandleScale.RIGHT_TOP:
					position = calculatePosition(new Point(event.x, event.y), DIRECTION_Y);
					x += position.x;
					y += position.y;
					_handles.right_bottom.x = event.x
					_handles.right_bottom.y -= event.y
					break;
				case HandleScale.LEFT_BOTTOM:
					position = calculatePosition(new Point(event.x, event.y), DIRECTION_X);
					x += position.x;
					y += position.y;
					_handles.right_bottom.x -= event.x
					_handles.right_bottom.y = event.y
					break;
				case HandleScale.TOP:
					position = calculatePosition(new Point(event.x, event.y), DIRECTION_Y);
					x += position.x;
					y += position.y;
					_handles.right_bottom.y -= event.y
					break;
				case HandleScale.LEFT:
					position = calculatePosition(new Point(event.x, event.y), DIRECTION_X);
					x += position.x;
					y += position.y;
					_handles.right_bottom.x -= event.x
					break;
				// Modify properties that need reposition twice
				case HandleScale.LEFT_TOP:
					position = calculatePosition(new Point(event.x, event.y), DIRECTION_BOTH);
					x += position.x;
					y += position.y;
					_handles.left_top.x = 0;
					_handles.left_top.y = 0;
					_handles.right_bottom.x -= event.x
					_handles.right_bottom.y -= event.y
					
					break;
			}
			width = Math.round(_handles.right_bottom.x);
			height = Math.round(_handles.right_bottom.y);
			_centre.pivot = new Point(width / 2, height / 2);
			applyModifications()
		}
		
		/**
		 * Start dragging the subject
		 *
		 * @param event
		 *
		 */
		private function startDragging(event : MouseEvent) : void
		{
			var max : Rectangle = _maxBoundries.clone()
			max.width -= width
			max.height -= height
			startDrag(false, max)
			stage.addEventListener(MouseEvent.MOUSE_UP, stopDragging);
			UIModifierFrameTicker.getInstance().addEventListener(UIModifierFrameTicker.FRAME_TICK , repositionTarget, false, 0 , true);
		}
		
		/**
		 * Called every time the user moves it's mouse while dragging subject
		 *
		 * @param event
		 *
		 */
		private function repositionTarget(event : Event) : void
		{
			applyModifications();
		}
		
		/**
		 * Called when user decides to stop the dragging
		 *
		 * @param event
		 *
		 */
		private function stopDragging(event : MouseEvent) : void
		{
			stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragging);
			UIModifierFrameTicker.getInstance().removeEventListener(UIModifierFrameTicker.FRAME_TICK, repositionTarget);
			if (_targetProperties != null)
			{
				applyModifications();
				dispatchEvent(new UIModifierEvent(UIModifierEvent.MODIFIED_DONE, _targetProperties.x, _targetProperties.y, _targetProperties.width, _targetProperties.height, _targetProperties.rotation, _centre.pivot));
			}
		}
		
		
		/**
		 * Create all handlers
		 */
		private function createHandles() : void
		{
			_overlay = new UIComponent();
			_modifier.addChild(_overlay);
			
			_handles = {}
			
			var rotate : HandleRotate;
			
			var rotateObjects : Array = [HandleRotate.LEFT_BOTTOM, HandleRotate.LEFT_TOP, HandleRotate.RIGHT_BOTTOM, HandleRotate.RIGHT_TOP]
			for (var i : Number = 0; i < rotateObjects.length; i++)
			{
				rotate = new HandleRotate();
				rotate.visual = _rotate_handle;
				rotate.pid = rotateObjects[i];
				rotate.cursor = _cursor_rotate;
				rotate.addEventListener(HandleEvent.ROTATED, updateHandleRotate);
				_modifier.addChild(rotate);
				_handles[rotateObjects[i]] = rotate;
				if (!debug)
				{
					rotate.alpha = 0;
				}
			}
			
			var handle : HandleScale
			var scaleObjects : Array = [{name: HandleScale.LEFT_BOTTOM, cursor: _cursor_left_right}, {name: HandleScale.LEFT_TOP, cursor: _cursor_right_left}, {name: HandleScale.RIGHT_BOTTOM, cursor: _cursor_right_left}, {name: HandleScale.RIGHT_TOP, cursor: _cursor_left_right}, {name: HandleScale.LEFT, cursor: _cursor_horizontal}, {name: HandleScale.TOP, cursor: _cursor_vertical}, {name: HandleScale.RIGHT, cursor: _cursor_horizontal}, {name: HandleScale.BOTTOM, cursor: _cursor_vertical}]
			
			var handles : UIComponent = new UIComponent();
			
			for (i = 0; i < scaleObjects.length; i++)
			{
				handle = new HandleScale();
				
				handle.visual = _handle;
				handle.pid = scaleObjects[i].name;
				handle.cursor = scaleObjects[i].cursor
				handle.addEventListener(HandleEvent.MOVED, updateHandleMove);
				handles.addChild(handle);
				_handles[scaleObjects[i].name] = handle;
			}
			
			_modifier.addChild(handles);
			
			
			_centre = new HandleCentre();
			_centre.visual = _centrePoint;
			_centre.cursor = _cursor_pivot;
			
			_modifier.addChild(_centre);
			
			_created = true;
			handleVisibleScaleHandlers()
		}
		
		/**
		 * Handle different modes of movement, scaling and rotation
		 *
		 */
		private function handleVisibleScaleHandlers() : void
		{
			_handles[HandleRotate.LEFT_TOP].visible = _enableRotation;
			_handles[HandleRotate.RIGHT_TOP].visible = _enableRotation;
			_handles[HandleRotate.LEFT_BOTTOM].visible = _enableRotation;
			_handles[HandleRotate.RIGHT_BOTTOM].visible = _enableRotation;
			_centre.visible = _enableRotation;
			
			_handles[HandleScale.LEFT_BOTTOM].visible = _enableScaling;
			_handles[HandleScale.LEFT_TOP].visible = _enableScaling;
			_handles[HandleScale.LEFT].visible = _enableScaling;
			_handles[HandleScale.RIGHT_BOTTOM].visible = _enableScaling;
			_handles[HandleScale.RIGHT_TOP].visible = _enableScaling;
			_handles[HandleScale.RIGHT].visible = _enableScaling;
			_handles[HandleScale.TOP].visible = _enableScaling;
			_handles[HandleScale.BOTTOM].visible = _enableScaling;
			
			if (_enableScaling)
			{
				switch (scaleMode)
				{
					case SCALE_ALL:
						break;
					case SCALE_PROPORTIONAL:
						_handles[HandleScale.LEFT].visible = false;
						_handles[HandleScale.BOTTOM].visible = false;
						_handles[HandleScale.TOP].visible = false;
						_handles[HandleScale.RIGHT].visible = false;
						break;
					
					case SCALE_VERTICAL_TOP:
						_handles[HandleScale.BOTTOM].visible = false;
					case SCALE_VERTICAL_BOTTOM:
						if (scaleMode == SCALE_VERTICAL_BOTTOM)
							_handles[HandleScale.TOP].visible = false;
					case SCALE_VERTICAL:
						_handles[HandleScale.LEFT_BOTTOM].visible = false;
						_handles[HandleScale.LEFT_TOP].visible = false;
						_handles[HandleScale.RIGHT_BOTTOM].visible = false;
						_handles[HandleScale.RIGHT_TOP].visible = false;
						_handles[HandleScale.RIGHT].visible = false;
						_handles[HandleScale.LEFT].visible = false;
						break;
					
					case SCALE_HORIZONTAL_LEFT:
						_handles[HandleScale.RIGHT].visible = false;
					case SCALE_HORIZONTAL_RIGHT:
						if (scaleMode == SCALE_HORIZONTAL_RIGHT)
							_handles[HandleScale.LEFT].visible = false;
					case SCALE_HORIZONTAL:
						_handles[HandleScale.LEFT_BOTTOM].visible = false;
						_handles[HandleScale.LEFT_TOP].visible = false;
						_handles[HandleScale.RIGHT_BOTTOM].visible = false;
						_handles[HandleScale.RIGHT_TOP].visible = false;
						_handles[HandleScale.TOP].visible = false;
						_handles[HandleScale.BOTTOM].visible = false;
						break;
				
				}
			}
			
			var hasEvent : Boolean = _overlay.hasEventListener(MouseEvent.MOUSE_DOWN)
			if (_enableMoving && !hasEvent)
			{
				_overlay.doubleClickEnabled = true;
				_overlay.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickEvent);
				_overlay.addEventListener(MouseEvent.MOUSE_DOWN, startDragging);
				_overlay.addEventListener(MouseEvent.MOUSE_OVER, showCursor);
				_overlay.addEventListener(MouseEvent.MOUSE_OUT, hideCursor);
			}
			else if (!_enableMoving && hasEvent)
			{
				_overlay.removeEventListener(MouseEvent.MOUSE_DOWN, startDragging);
				_overlay.removeEventListener(MouseEvent.MOUSE_OVER, showCursor);
				_overlay.removeEventListener(MouseEvent.MOUSE_OUT, hideCursor);
			}
		}
		
		/**
		 * Apply the modifications to the target and send them out as an event.
		 * Also start the event to ensure the graphics display correctly.
		 *
		 */
		private function applyModifications() : void
		{
			if (_targetProperties != null)
			{
				//	log.info("apply: ");
				if (_isCentered)
				{
					//if(_target.rotation != rotation){
					var localOppositeLeg : Number = _centre.pivot.x;
					var localAdjacentLeg : Number = _centre.pivot.y;
					var Ls : Number = Math.sqrt((localOppositeLeg * localOppositeLeg) + (localAdjacentLeg * localAdjacentLeg));
					if (_centre.pivot.x < 0)
					{
						Ls = -Ls;
					}
					var Lr : Number = Math.atan(localAdjacentLeg / localOppositeLeg);
					var Gr : Number = MathUtils.degree2radian(rotation) + Lr;
					var Gx : Number = Math.cos(Gr) * Ls;
					var Gy : Number = Math.sin(Gr) * Ls;
					
					_targetProperties.x = x + Gx;
					_targetProperties.y = y + Gy;
					_targetProperties.rotation = Math.round(rotation);
				}
				else
				{
					_targetProperties.x = x;
					_targetProperties.y = y;
					_targetProperties.rotation = Math.round(rotation);
				}
				
				_resize(null);
			}
		}
		
		
		
		/**
		 * Dispatches all modification
		 */
		private function updateModifiedData() : void
		{
			if (_targetProperties != null)
			{
				dispatchEvent(new UIModifierEvent(UIModifierEvent.MODIFIED, _targetProperties.x, _targetProperties.y, _targetProperties.width, _targetProperties.height, _targetProperties.rotation, _centre.pivot));
				if (_applyModification && _target != null)
				{
					_target.x = _targetProperties.x
					_target.y = _targetProperties.y
					_target.width = _targetProperties.width
					_target.height = _targetProperties.height
					_target.rotation = _targetProperties.rotation
				}
			}
		}
		
		/**
		 * Every time "applyModifications" is triggered, resizing is done
		 * via variable _resizeCount
		 *
		 * @param event
		 *
		 */
		private function _resize(event : Event) : void
		{
			//	log.info("Resize")
			if (_targetProperties != null)
			{
				if (_minBoundries != null)
				{
					if (width < _minBoundries.width)
					{
						width = _minBoundries.width
					}
					if (height < _minBoundries.height)
					{
						height = _minBoundries.height
					}
				}
				
				// apply ratio if scaleMode is set to SCALE_PROPORTIANAL ( Experimental )
				if (scaleMode == SCALE_PROPORTIONAL)
				{
					height = width * (_storage.height / _storage.width);
				}
				
				draw();
				
				_targetProperties.width = width
				_targetProperties.height = height
				
				_centre.bounds = new Rectangle(0, 0, width, height);
				
				//_resizeCounts ++
				//if ( _resizeCounts > _resizeTries ) {
				//	removeEventListener(Event.ENTER_FRAME,_resize);
				updateModifiedData()
					//}
			}
		}
		
		private function draw() : void
		{
			var rotate : HandleRotate = _handles[HandleRotate.LEFT_BOTTOM]
			_rotateHandlerSize = {width: rotate.width, height: rotate.height}
			
			
			_handles[HandleRotate.LEFT_TOP].x = -(_rotateHandlerSize.width / 2);
			_handles[HandleRotate.LEFT_TOP].y = -(_rotateHandlerSize.height / 2);
			_handles[HandleRotate.LEFT_BOTTOM].x = -(_rotateHandlerSize.width / 2);
			_handles[HandleRotate.LEFT_BOTTOM].y = height + (_rotateHandlerSize.height / 2);
			_handles[HandleRotate.RIGHT_TOP].x = width + (_rotateHandlerSize.width / 2);
			_handles[HandleRotate.RIGHT_TOP].y = -(_rotateHandlerSize.height / 2);
			_handles[HandleRotate.RIGHT_BOTTOM].x = width + (_rotateHandlerSize.width / 2);
			_handles[HandleRotate.RIGHT_BOTTOM].y = height + (_rotateHandlerSize.height / 2);
			
			_handles[HandleScale.LEFT_BOTTOM].x = 0;
			_handles[HandleScale.LEFT_BOTTOM].y = height;
			_handles[HandleScale.RIGHT_TOP].x = width;
			_handles[HandleScale.RIGHT_TOP].y = 0;
			_handles[HandleScale.RIGHT_BOTTOM].x = width;
			_handles[HandleScale.RIGHT_BOTTOM].y = height;
			/*
			   _handles[HandleScale.LEFT_BOTTOM].bounds  = new Rectangle(10,10,-1000, 1000);
			   _handles[HandleScale.LEFT_TOP].bounds     = new Rectangle(10,10,-1000,-1000);
			   _handles[HandleScale.RIGHT_TOP].bounds    = new Rectangle(10,10, 1000,-1000);
			   _handles[HandleScale.RIGHT_BOTTOM].bounds = new Rectangle(10,10, 1000, 1000);
			   _handles[HandleScale.LEFT].bounds         = new Rectangle(10,10,-1000, 1000);
			   _handles[HandleScale.TOP].bounds          = new Rectangle(10,10,-1000,-1000);
			   _handles[HandleScale.RIGHT].bounds        = new Rectangle(10,10, 1000,-1000);
			   _handles[HandleScale.BOTTOM].bounds       = new Rectangle(10,10, 1000, 1000);
			 */
			
			_handles[HandleScale.TOP].x = width / 2;
			_handles[HandleScale.TOP].y = 0;
			
			_handles[HandleScale.BOTTOM].x = width / 2;
			_handles[HandleScale.BOTTOM].y = height;
			
			_handles[HandleScale.LEFT].x = 0
			_handles[HandleScale.LEFT].y = height / 2
			
			_handles[HandleScale.RIGHT].x = width
			_handles[HandleScale.RIGHT].y = height / 2
			
			_overlay.width = width
			_overlay.height = height;
			
			_overlay.graphics.clear()
			
			var bcolor : Number = getStyle("borderColor");
			if (_focus)
			{
				var css : CSSStyleDeclaration = StyleManager.getStyleDeclaration("global");
				bcolor = css.getStyle("focusStrokeColor");
			}
			
			_overlay.graphics.lineStyle(getStyle("borderThickness"), bcolor, getStyle("borderAlpha"));
			_overlay.graphics.beginFill(0xffffff, 0);
			_overlay.graphics.drawRect(0, 0, width, height);
		}
		
		/**
		 *
		 * @param event
		 *
		 */
		private function showCursor(event : MouseEvent) : void
		{
			_cursorID = CursorManager.setCursor(_cursor_move);
		}
		
		/**
		 *
		 * @param event
		 *
		 */
		private function hideCursor(event : MouseEvent) : void
		{
			CursorManager.removeCursor(_cursorID);
		}
		
		public function get applyModification() : Boolean
		{
			return _applyModification;
		}
		
		/**
		 * If set to true the target will size realtime,
		 * If set to false the modifier will only dispatch events
		 * @param value Boolean
		 **/
		public function set applyModification(value : Boolean) : void
		{
			_applyModification = value;
		}
	
	}
}