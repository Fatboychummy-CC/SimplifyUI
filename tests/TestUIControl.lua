local UIControl = require "UIControl"
local UDim2 = require "UDim2"

cctest.newSuite "UIControlTests"
  "ConstructorArguments" (function()
    EXPECT_THROW_ANY_ERROR(UIControl.New)
    EXPECT_THROW_MATCHED_ERROR(UIControl.New, "Expected Terminal Object", {})
    EXPECT_THROW_ANY_ERROR(UIControl.New, term.current())
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name")
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1)
    EXPECT_THROW_ANY_ERROR(UIControl.New, term.current(), "Name", "")
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, 1)
    EXPECT_THROW_ANY_ERROR(UIControl.New, term.current(), "Name", 1, "")
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, 1, 1)
    EXPECT_THROW_ANY_ERROR(UIControl.New, term.current(), "Name", 1, 1, "")
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, 1, 1, 1)
    EXPECT_THROW_ANY_ERROR(UIControl.New, term.current(), "Name", 1, 1, 1, "")
    local temp = UIControl.New(term.current(), "Name")
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, 1, 1, 1, temp)

    EXPECT_THROW_MATCHED_ERROR(UIControl.New, "non%-UIObject", term.current(), "Name", 1, 1, 1, 1, {})

    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", nil, 1, 1, 1)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", nil, nil, 1, 1)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", nil, 1, nil, 1)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", nil, 1, 1, nil)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", nil, nil, nil, 1)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", nil, nil, 1, nil)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", nil, 1, nil, nil)

    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, nil, 1, 1)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, nil, nil, 1)
    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, nil, 1, nil)

    EXPECT_NO_THROW(UIControl.New, term.current(), "Name", 1, 1, nil, 1)
  end)
  "ActualPositionUpdates" (function()
    -- ActualPosition should update when:
    --  position changes
    --  anchorpoint changes
    --  parent changes
    FAIL()
  end)
  "SetTypesGood" (function()
    local obj = UIControl.New(term.current(), "Name")

    EXPECT_NO_THROW(function() obj.Name = "NewName" end)
    EXPECT_EQ(obj.Name, "NewName")

    local pos = UDim2.FromOffset(32, -2)
    EXPECT_NO_THROW(function() obj.Position = pos end)
    EXPECT_EQ(obj.Position, pos)

    local anchor = UDim2.FromOffset(32, -2)
    EXPECT_NO_THROW(function() obj.AnchorPoint = anchor end)
    EXPECT_EQ(obj.AnchorPoint, anchor)

    local size = UDim2.FromScale(0.5, 0.1)
    EXPECT_NO_THROW(function() obj.Size = size end)
    EXPECT_EQ(obj.Size, size)

    local w = window.create(term.current(), 1, 1, 1, 1)
    EXPECT_NO_THROW(function() obj.ParentTerm = w end)
    EXPECT_EQ(obj.ParentTerm, w)

    local obj2 = UIControl.New(term.current(), "Name2")
    EXPECT_NO_THROW(function() obj.Parent = obj2 end)
    EXPECT_EQ(obj.Parent, obj2)
  end)
  "SetTypesBad" (function()
    local obj = UIControl.New(term.current(), "Name")

    EXPECT_THROW_ANY_ERROR(function() obj.Name = 32 end)
    EXPECT_UEQ(obj.Name, 32)

    local pos = 32
    EXPECT_THROW_ANY_ERROR(function() obj.Position = pos end)
    EXPECT_UEQ(obj.Position, pos)

    local anchor = "yea"
    EXPECT_THROW_ANY_ERROR(function() obj.AnchorPoint = anchor end)
    EXPECT_UEQ(obj.AnchorPoint, anchor)

    local size = {}
    EXPECT_THROW_ANY_ERROR(function() obj.Size = size end)
    EXPECT_UEQ(obj.Size, size)

    local w = "rawr xd"
    EXPECT_THROW_ANY_ERROR(function() obj.ParentTerm = w end)
    EXPECT_UEQ(obj.ParentTerm, w)

    local obj2 = function() end
    EXPECT_THROW_ANY_ERROR(function() obj.Parent = obj2 end)
    EXPECT_UEQ(obj.Parent, obj2)
  end)
