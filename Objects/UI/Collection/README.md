# What is this?
This file explains the specifications of all [`Collection`](#Collection) objects and sub-objects.

# Introduction
[`Collection`](#Collection) objects are objects which describe different aspects of a UI object, from how the corners look to how each side looks, and what the body of the object looks like.

## Collection
A [`Collection`](#Collection) is a combination of any number of [`Background`](#Background)s, [`Corner`](#Corner)s, [`Edge`](#Edge)s, and up to one [`Animation`](#Animation) (per attachment).

# Specifications

## `Collection`
A [`Collection`](#Collection) is an `Instance`.

### Properties (excluding those inherited from `Instance`)
* `Body: table[CollectionItem]`: A list of [`CollectionItem`](#CollectionItem)s, ordered in the order of drawing. The item at `Body[1]` is drawn before `Body[2]`.
* `Transparent: boolean`: Determines whether this [`Collection`](#Collection) is drawn. When `true`, calling `Collection:Draw()` will not draw the [`Collection`](#Collection).
* `Position: UDim2`: Describes the position relative to the parent object (or the terminal, if no parent) of this [`Collection`](#Collection).
* `ActualPosition: UDim2`: Describes the actual position relative to the terminal of this [`Collection`](#Collection), only updated when `Collection:Update()` is called. The `.Scale` values of the `UDim`s are ignored.
* `Size: UDim2`: Describes the size relative to the parent object (or the terminal, if no parent) of this [`Collection`](#Collection)
* `ActualSize: UDim2`: Describes the actual size relative to the terminal of this [`Collection`](#Collection), only updated when `Collection:Update()` is called. The `.Scale` values of the `UDim`s are ignored.

### Methods (excluding those inherited from `Instance`)
* `Draw()`: Simply draws the [`Collection`](#Collection), also calling `Collection:Update()` on all children and `CollectionItem:Draw()` on all objects in the `Body`.
* `Update()`: Resizes the object's [`Background`](#Background)s, [`Corner`](#Corner)s, and [`Edge`](#Edge)s to the object's specifications, also calling `Collection:Update()` on all children.
  * Contrary to the UI objects in Roblox, the [`Collection`](#Collection) is not updated when `Position` or `Size` is updated. You *must* call this method to get the updated values.
* `AddCollectionItem(CollectionItem)`: Adds a new [`CollectionItem`](#CollectionItem) at the back of `Collection.Body`.

## `CollectionItem`
A [`CollectionItem`](#CollectionItem) is not a full object, however there are other objects which derive from [`CollectionItem`](#CollectionItem).

### Objects which derive from [`CollectionItem`](#CollectionItem):
* [`Background`](#Background)
* [`Edge`](#Edge)
* [`Corner`](#Corner)
* [`Animation`](#Animation)

### Methods
* `Draw(Position: UDim2, Scale: UDim2)`: Draws the object, given the position and scale.
* `SetTextColor(color)`: Sets the text colo[u]r.
* `SetBackgroundColor(color)`: Sets the background colo[u]r.

### Properties
* `BackGroundColo[u]r: color`: The color used for the background of this object.
* `TextColo[u]r: color`: The color used for the foreground of this object.
  * It is not recommended to set these manually, but if you do: The `Color` spelling is used internally.

## `Background`

### Properties
* `Character: char [default=' ']`: The character used for the background.

## `Corner`

### Properties
* `Corners: table[CornerPosition]`: The corners this [`Corner`](#Corner) object is attached to.
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

## `Edge`

### Properties
* `Edges: table[EdgePosition]`: The edges this [`Edge`](#Edge) object is attached to.
* `Character: char`: The character to be repeated across the edge.
* `IsDashed: boolean [default=false]`:
* `DashLength: number [default=1]`: If `IsDashed` is true, this number will be checked for the length of each "dash".
  * If the DashLength is even and the length of the edge is odd (or vice-versa), the center dash of the edge will either be longer or shorter to compensate.

#### `EdgePosition`
A `EdgePosition` is an Enum, values are:
* `TOP: 1`
* `RIGHT: 2`
* `BOTTOM: 3`
* `LEFT: 4`

## `Animation`
[`Animation`](#Animation)s are a special [`CollectionItem`](#CollectionItem) that adds a bit of flare to a [`Collection`](#Collection).

### Methods:
* `Tick()`: Advances the animation forward by a frame using the `Animation.Animator` function.
* `Run(tickSpeed: number [default=0.05])`: Runs the animation by calling `Tick` every `tickSpeed` seconds, then calling `Draw` on itself.
* `Stop()`: Stops the animation.

### Properties:
* `Attachment: CollectionItem`: Attaches the animation to the selected [`CollectionItem`](#CollectionItem).
  * [`CollectionItem`](#CollectionItem) usage is enforced by `Instance:IsA`.
  * Cannot attach an [`Animation`](#Animation) to another [`Animation`](#Animation).
* `Animator: function(self, Parent)`: The function called every tick.
