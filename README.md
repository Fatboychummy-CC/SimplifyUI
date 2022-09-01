# What is Simplify UI?
Simplify UI aims to provide a simple library for simple graphics. Want a few
checkboxes? We got 'em. Want a few sliders? Got those too. Buttons? Yeah.

# Features

- [ ] Fully buffered
- [ ] Monitor or terminal (or multiple!) support
- [ ] Input boxes
  - [ ] Type support
- [ ] Buttons
  - [ ] Toggle
  - [ ] "Normal"
  - [ ] Timed
- [ ] Sliders
  - [ ] "Filling bar" sliders
  - [ ] "Sliding bar" sliders
  - [ ] Vertical and horizontal
  - [ ] Optional input box attachment
- [ ] Percentage bars
  - [ ] "Filling" bars
  - [ ] "Fancy Shape" bars
  - [ ] "Multi" bars
  - [ ] Higher resolution
- [ ] Checkboxes
  - [ ] Grouping
    - [ ] Radio
- [ ] Lists
  - [ ] Configurable columns and rows
- [ ] Scroll Boxes
  - [ ] Horizontal and vertical
- [ ] Shapes
  - [ ] Simple shapes
  - [ ] Make custom shapes
  - [ ] Attach objects
- [ ] Smart positioning
  - [ ] Roblox UDim objects
  - [ ] Roblox UDim2 objects
- [ ] Objects

## Fully buffered
The overarching system is fully buffered and updated entirely at once, to avoid
annoying flickers.

## Monitor or terminal (or multiple!) support
You will be able to select what you want to output the UI to, and it supports
outputting to any number of locations.

## Input boxes
You can create input boxes to allow the user to input information. You can also
specify a type, and the input box will not allow other types of information to
be inserted.

## Buttons
There are multiple types of buttons. The simple, "Normal" buttons which just
click once when you hit them, toggle buttons which stay enabled until you 
disable them again, and timed buttons which work similarly to minecraft's 
buttons, where they stay "active" for a certain period of time.

## Sliders
There are multiple types of sliders.

There is a filling bar slider, which looks much like a [progress bar](<Percentage bars>), but the
slider is the "percentage" filled.

[||||    ]

Also, a sliding bar styled slider, with a small line displaying the width of the
bar and a thick line in perpendicular.

--------|--------

These sliders can be horizontal or vertical, and allow for an [input box](<Input boxes>) to be
attached for finer control.

## Percentage bars
Otherwise known as "Progress bars", the percentage bars will display a
percentage in a bar-styled object.

These bars come in three styles:

- Filling
- Multi
- Fancy

Filling bars are the normal percentage bars. They simply increase an amount of
fill inside the bar based on the percentage supplied.

Multi bars allow you to supply multiple different percentages, and will display
them "stacked" on top of each-other.

Fancy bars allow you to pass a [shape](Shapes), and it will fill it from left to
right (or bottom to top) depending on the percentage supplied.

## Checkboxes
Simple checkboxes, not much to them.

You can group them together and form radio boxes (or just group them without 
toggling them to be radio).

## Lists
You can create lists, and they can have any number of columns (widths
are automatically sized to the largest item in the list). Insert items to add a
row. A list will automatically create a vertical [Scroll box](<Scroll boxes>)
which is useful for when more items are in the list than can physically fit on
screen.

## Scroll boxes
A scroll box simply allows you to scroll through things, horizontally or
vertically. Optionally a scroll bar and scroll buttons can be positioned on the
scroll box.

## Shapes
The shape system comes with some shapes preinstalled (circles, ovals,
rectangles, etc) and allows you to attach other objects to them.

For example, to give a [percentage bar](<Percentage bars>) a border, you can
make a rectangle which is one larger in every dimension, then attach the bar in
the center of the shape.

## Smart positioning
The positioning system works in a parent-child basis. Each object can be
parented to another object, and its position is relative to that object.

We make use of Roblox's
[Udim](https://developer.roblox.com/en-us/api-reference/datatype/UDim) and
[UDim2](https://developer.roblox.com/en-us/api-reference/datatype/UDim2) objects 
for these. Everything available on the developer forum to these objects are
available in Simplify UI.

## Objects
A simple object system that allows you to create your own custom objects and
attach them to other objects in this library.

# Code samples

To be continued...