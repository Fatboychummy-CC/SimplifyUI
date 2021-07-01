# UIObject

* `Transparent: boolean`: Determines whether this [`Collection`](Objects/UI/Collection/README.md#Collection) is drawn. When `true`, calling `Collection:Draw()` will not draw the [`Collection`](Objects/UI/Collection/README.md#Collection), nor will it draw the [`Collection`](Objects/UI/Collection/README.md#Collection)'s children.
* `Position: UDim2`: Describes the position relative to the parent object (or the terminal, if no parent) of this [`Collection`](Objects/UI/Collection/README.md#Collection).
* `ActualPosition: UDim2`: Describes the actual position relative to the terminal of this [`Collection`](Objects/UI/Collection/README.md#Collection), only updated when `Collection:Update()` is called. The `.Scale` values of the `UDim`s are ignored.
* `Size: UDim2`: Describes the size relative to the parent object (or the terminal, if no parent) of this [`Collection`](Objects/UI/Collection/README.md#Collection)
* `ActualSize: UDim2`: Describes the actual size relative to the terminal of this [`Collection`](Objects/UI/Collection/README.md#Collection), only updated when `Collection:Update()` is called. The `.Scale` values of the `UDim`s are ignored.
