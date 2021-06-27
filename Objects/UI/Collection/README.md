# What is this?
This file explains the specifications of all `Collection` objects and sub-objects.

# Introduction
[`Collection`](#Collection) objects are objects which describe different aspects of a UI object, from how the corners look to how each side looks, and what the body of the object looks like.

## `Collection`
A `Collection` is a combination of any number of `Background`s, `Corner`s, `Edge`s, and up to one `Animation` (per attachment).

# Specifications

## `Collection`
A `Collection` is an `Instance`.

Each `Collection` object has the following properties (excluding those inherited from `Instance`):
* `Body: table[CollectionItem]`: A list of `CollectionItem`s, ordered in the order of drawing. The item at `Body[1]` is drawn before `Body[2]`.
* `Transparent: boolean`: Determines whether this `Collection` is drawn. When `true`, calling `Collection:Draw()` will not draw the `Collection`.
* `Position: UDim2`: Describes the position relative to the parent object (or the terminal, if no parent) of this `Collection`.
* `ActualPosition: UDim2`: Describes the actual position relative to the terminal of this `Collection`, only updated when `Collection:Update()` is called. The `.Scale` values of the `UDim`s are ignored.
* `Size: UDim2`: Describes the size relative to the parent object (or the terminal, if no parent) of this `Collection`
* `ActualSize: UDim2`: Describes the actual size relative to the terminal of this `Collection`, only updated when `Collection:Update()` is called. The `.Scale` values of the `UDim`s are ignored.

Each `Collection` object has the following methods:
* `Draw()`: Simply draws the `Collection`, also calling `Collection:Update()` on all children and `CollectionItem:Draw()` on all objects in the `Body`.
* `Update()`: Resizes the object's `Background`s, `Corner`s, and `Edge`s to the object's specifications, also calling `Collection:Update()` on all children.
  * Contrary to the UI objects in Roblox, the `Collection` is not updated when `Position` or `Size` is updated. You *must* call this method to get the updated values.
* `AddCollectionItem(CollectionItem)`: Adds a new `CollectionItem` at the back of `Collection.Body`.

## `CollectionItem`:
A `CollectionItem` is not a full object, however there are other objects which derive from `CollectionItem`.

The following objects derive from `CollectionItem`:
* `Background`
* `Side`
* `Corner`
* `Animation`

Each of the `CollectionItem` objects have the following methods/properties:
* `Draw(Position: UDim2, Scale: UDim2)`: Draws the object, given the position and scale.
* `BGColo[u]r: color`: The color used for the background of this object.
* `FGColo[u]r: color`: The color used for the foreground of this object (textColo[u]r).

## `Background`

### Properties
* `Character: char [default=' ']`: The character used for the background.

## `Corner`

### Properties
* `Corner: CornerPosition`: The actual corner this `Corner` object is attached to.
* `Size: number`: The square size of this object.
* `PositionOffset: UDim2 [default=UDim2[0, 0, 0, 0]]`: The position offset of this object on each corner.
  * By default, corners are positioned so the corners are "sticking out" of the side of the object, like so:
```
  ╔═╗      ╔═╗
  ╚═╝══════╚═╝
    ║  UI  ║
    ║      ║
    ║OBJECT║
  ╔═╗══════╔═╗
  ╚═╝      ╚═╝

```
* `Body: table[table[char/nil]]`: The body of this object. `nil` values in the table will not be drawn --

#### `CornerPosition`
A `CornerPosition` is an Enum, values are:
* `TOP_LEFT: 1`
* `TOP_RIGHT: 2`
* `BOTTOM_LEFT: 3`
* `BOTTOM_RIGHT: 4`

## `Side`

### Properties
* `Side: SidePosition`: The actual side this `Side` object is attached to.
* `Character: char`: The character to be repeated across the side.
* `IsDashed: boolean [default=false]`:
* `DashLength: number [default=1]`: If `IsDashed` is true, this number will be checked for the length of each "dash".
  * If the DashLength is even and the length of the side is odd (or vice-versa), the center dash of the side will either be longer or shorter to compensate.

#### `SidePosition`
A `SidePosition` is an Enum, values are:
* `TOP: 1`
* `RIGHT: 2`
* `BOTTOM: 3`
* `LEFT: 4`

## `Animation`s
`Animation`s are a special `CollectionItem` that adds a bit of flare to a `Collection`.

### Methods:
* `Tick()`: Advances the animation forward by a frame using the `Animation.Animator` function.
* `Run(tickSpeed: number [default=0.05])`: Runs the animation by calling `Tick` every `tickSpeed` seconds, then calling `Draw` on itself.
* `Stop()`: Stops the animation.

### Properties:
* `Attachment: CollectionItem`: Attaches the animation to the selected `CollectionItem`.
  * `CollectionItem` usage is enforced by `Instance:IsA`.
  * Cannot attach an `Animation` to another `Animation`.
* `Animator: function(self, Parent)`: The function called every tick.
