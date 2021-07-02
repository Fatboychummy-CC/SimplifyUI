# What is this?
This file explains the specifications of all [`UIObject`](#UIObject) objects and sub-objects.

# Introduction
[`UIObject`](#UIObject) objects are objects which describe different aspects of a UI object, from how the corners look to how each side looks, and what the body of the object looks like.

# The UIObject
A [`UIObject`](#UIObject) is something that contains different methods and properties which aid significantly in creating a nice, responsive UI.

# Specifications

## UIObject
> NotCreatable

By default, a UIObject only defines an area in which *something* will be drawn to. However, a [`Collection`](#../Collection/README.md#Collection) is a more advanced (and less advanced in some ways) version of a [`UIObject`](#UIObject). Excluding [`Collection`](#../Collection/README.md#Collection)s, a [`UIObject`](#UIObject) does not handle background or borders. You should use a [`Collection`](#../Collection/README.md#Collection) in tandem with these [`UIObject`](#UIObject)s to achieve your desired look.

***NOTE: `Collection` may be converted to `UIObject`***

### Static Properties (Properties used by all [`UIObject`](#UIObject)s)
* `SelectionColor: color[default = colors.cyan]`: The border color used when selecting an object via the keyboard.

### Properties (Excluding those inherited from `Instance`)
* `Visible: boolean[default = true]`: Determines whether this [`UIObject`](#UIObject) is drawn. When `false`, calling `UIObject:Draw()` will not draw the [`UIObject`](#UIObject), nor will it draw the [`UIObject`](#UIObject)'s children.
* `AnchorPoint: UDim2[default = 0,0,0,0]`: Determines the origin point of this [`UIObject`](#UIObject).
* `Position: UDim2[default = 0,0,0,0]`: Describes the position relative to the parent object (or the terminal, if no parent) of this [`UIObject`](#UIObject).
* `AbsolutePosition: Vector2[default = 0,0]`: Describes the actual position relative to the terminal of this [`UIObject`](#UIObject), only updated when `UIObject:Update()`.
* `AutomaticSize: AutomaticSize[default = AutomaticSize.None]`: Determines whether this object is resized based on child content.
* `Size: UDim2[default = 0,0,0,0]`: Describes the size relative to the parent object (or the terminal, if no parent) of this [`UIObject`](#UIObject)
* `AbsoluteSize: Vector2[default = 0,0]`: Describes the actual size (in characters) relative to the terminal of this [`UIObject`](#UIObject), only updated when `UIObject:Update()`.
* `NextSelectionRight, NextSelectionLeft, NextSelectionUp, NextSelectionDown: UIObject[default = nil]`: These are used for determining what hitting the arrow-keys will move the `Active` item to.
* `Selectable: boolean[default = false]`: Determines if a [`UIObject`](#UIObject) is selectable.
* `Selected: boolean[default = false]`: Determines if this object has been selected by keyboard. When selected using arrow keys, will display a border around the object using `UIObject.SelectionColor`.
* `Active: boolean[default = true]`: Controls when a UI element will sink inputs from reaching other elements behind it.
* `ClipsDescendants: boolean[default = false]`: Determines if descendant [`UIObject`](#UIObject)s are clipped when out of bounds of this object.


### Methods (Excluding those inherited from `Instance`)
* `Draw()`: Simply draws the [`UIObject`](#UIObject), also calling `UIObject:Draw()` on all children and `UIObject:Draw()` on all objects in the `Body`.
* `Update()`: Updates this object's `ActualPosition` and `ActualSize` values in regards to the parent, also calling `UIObject:Update()` on all children.
* `TweenPosition(UDim2 endPosition, EasingDirection easingDirection, EasingStyle easingStyle, float time, boolean override, function callback): boolean`: Smoothly move a [`UIObject`](#UIObject) to a new position.
* `TweenSize(UDim2 endSize, EasingDirection easingDirection, EasingStyle easingStyle, float time, boolean override, function callback): boolean`: Smoothly resize a [`UIObject`](#UIObject) to a new size.
* `TweenSizeAndPosition(UDim2 endSize, UDim2 endPosition, EasingDirection easingDirection, EasingStyle easingStyle, float time, boolean override, function callback): boolean`: Smoothly move a [`UIObject`](#UIObject) to a new position and size.

## The different types of [`UIObject`](#UIObject)s

### TextLabel
This object displays text.

#### Properties (Excluding those inherited from [`UIObject`](#UIObject))
* `Text: string[default = "TextLabel"]`: The string rendered by the UI element.
* `TextAlign: TextAlign[default = TextAlign.Center]`: The alignment of the text inside this UI element, using the [`TextAlign`](#TextAlign-Enum) enum.
* `TextColor: color[default = colors.white]`: The color of the rendered text.
* `BackgroundColor: color[default = colors.black]`: The color of the background.
* `TextTruncate: boolean[default = false]`: Controls the truncation of the text displayed in this [`TextBox`](#TextBox).
* `TextWrapped: boolean[default = false]`: Determines if text wraps to multiple lines within the `UIObject`s space, truncating excess text.
* `TextFits: boolean`: Whether the text fits within the constraints of the [`TextBox`](#TextBox).

##### TextAlign: Enum
* `TopLeft      = 1`
* `TopCenter    = 2`
* `TopRight     = 3`
* `CenterLeft   = 4`
* `Center       = 5`
* `CenterRight  = 6`
* `BottomLeft   = 7`
* `BottomCenter = 8`
* `BottomRight  = 9`

### TextBox (inherits from [`TextLabel`](#TextLabel))
This object contains a `read()`-like window that allows you the user to select it then write to it.

#### Properties (Excluding those inherited from [`UIObject`](#UIObject) and [`TextLabel`](#TextLabel))
* `Selected: boolean[default = false]`: Determines if this object has been selected by keyboard.
* `TextScrolled: boolean[default = true]`: If `TextWrapped` is `false`, determines if the [`TextBox`](#TextBox) will scroll similarly to `read()`.

#### Methods (Excluding those inherited from [`UIObject`](#UIObject) and [`TextLabel`](#TextLabel))
* `CaptureFocus()`: Forces the client to focus on this [`TextBox`](#TextBox), removing focus from any other [`TextBox`](#TextBox)s in the hierarchy.
* `IsFocused(): boolean`: Returns `true` if the [`TextBox`](#TextBox) is focused, or `false` if not.
* `ReleaseFocus(boolean submitted[default = false])`: Forces the client to unfocus the [`TextBox`](#TextBox). If `submitted` is true, will emulate hitting `keys.enter` before unfocusing the [`TextBox`](#TextBox).

### UIButton
> NotCreatable

This is a base class to [`TextButton`](#TextButton)s and [`ImageButton`](#ImageButton)s.

#### Events
* `Activated(InputObject inputObject, int hitCount)`: Fires when the button is activated (whether it be by keyboard, mouse input, or etc), delaying a quarter-second to count hits (for checking double-clicks/etc).
* `MouseButton1Click()`: Fired when the mouse fully left-clicks this button.
* `MouseButton2Click()`: Fired when the mouse fully right-clicks this button.
* `MouseButton1Down(int x, int y)`: Fired when the left mouse is down on this button.
* `MouseButton2Down(int x, int y)`: Fired when the right mouse is down on this button.
* `MouseButton1Up(int x, int y)`: Fired when the left mouse is released on this button.
* `MouseButton2Up(int x, int y)`: Fired when the right mouse  is released on this button.

##### InputObject
A more basic version of Roblox's `InputObject`

###### Properties
* `KeyCode: keys`: If keyboard input, the key that was hit.
* `UserInputType: UserInputType`: [`UserInputType`](#UserInputType) enum for what type of input was detected.

####### UserInputType: Enum
* `MouseButton1 = 1`: The left mouse button
* `MouseButton2 = 2`: The right mouse button
* `MouseButton3 = 3`: The middle mouise button
* `MouseWheel   = 4`: Scrolling while hovering over the UI Object.
* `Keyboard     = 5`: Keyboard input.
* `TextInput    = 6`: Keyboard input, but input was sank by a text input object (Usually only [`TextBox`](#TextBox)es do this).

### TextButton
This object displays text like [`TextLabel`](#TextLabel), but is also clicky like a button.

Inherits from both [`TextLabel`](#TextLabel) and [`UIButton`](#UIButton)

### ImageLabel
An image-in-a-box.

#### Properties
* `Image: content`: The image to be displayed, formatted as a `paintutils` image.
* `ScaleType: ScaleType[default = ScaleType.Crop]`: Determines how the image will be scaled if displayed in a UI element which differs in size, using the [`ScaleType`](#ScaleType-Enum) enum.

##### ScaleType: Enum
* `Stretch = 1`: The image is stretched to fit in both `X` and `Y` dimensions to fit the image.
* `Tile    = 2`: The image is tiled inside of the element.
* `Fit     = 3`: The image is scaled up until either `X` or `Y` dimension is equal to the size of the element.
* `Crop    = 4`: The image is cropped to fit inside the element.

### ImageButton
An image, but also a button!

Inherits from [`UIButton`](#UIButton) and [`ImageLabel`](#ImageLabel)

#### Properties
* `PressedImage: content`: The image that will be drawn when an [`ImageButton`](#ImageButton) is pressed.
* `TileCount: UDim2[default = 0,1,0,1]`: The amount to tile the image in each direction, if `ScaleType.Tile` is selected.

### Frame
A [`UIObject`](#UIObject) that renders simply as a rectangle with no other content. Despite being "nothings", they are useful as containers for other [`UIObject`](#UIObject)s.

#### Properties
* `Style: FrameStyle[default = FrameStyle.Square]`: The style of frame to be used.

### ScrollingFrame
A special version of a [`Frame`](#Frame) which handles scrolling for you.

#### Properties
* `AbsoluteWindowSize: Vector2[default = 0,0]`: The size in characters of the frame, without scrollbars.
* `CanvasPosition: Vector2[default = 0,0]`: The location within the canvas that is drawn at the top-right corner of the [`ScrollingFrame`](#ScrollingFrame).
* `CanvasSize: UDim2[default = 0,0,0,0]`: The size of the area that is scrollable. The `UDim2` is calculated using the parent object's size, not this object's size.
* `AutomaticCanvasSize: AutomaticSize[default = AutomaticSize.None]`: Determines whether the `CanvasSize` is resized based on child content.
* `BottomChar: char[default = ↓]`: The character used for the down arrow on the scrollbar.
* `TopChar: char[default = ↑]`: The character used for the up arrow on the scrollbar.
* `ScrollBarThickness: int[default = 1]`: The thickness in characters of the scrollbar. This applies to both vertical and horizontal scrollbars.
* `ScrollingDirection: ScrollingDirection[default = ScrollingDirection.XY]`: The direction this [`ScrollingFrame`](#ScrollingFrame) is allowed to scroll.
* `ScrollingEnabled: boolean[default = true]`: Whether or not scrolling is allowed. When false, scroll bars will not be rendered.
