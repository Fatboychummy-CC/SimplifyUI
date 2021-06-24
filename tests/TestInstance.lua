local Instance = require "Objects.Instance"

local dummyClass = {ClassName = "DummyClass"}
Instance.Register(dummyClass)

function dummyClass.new(instanceData, arg)
  instanceData.value = arg

  function instanceData._internal:Clone()
    return Instance.new(dummyClass, self.value)
  end
  function instanceData._internal:Destroy()
    for k, v in pairs(self) do self[k] = nil end
  end

  instanceData.WRITING = nil

  return instanceData
end

cctest.newSuite "TestInstance"
  "REGISTRATION" (function()
    local fakeClass = {}
    EXPECT_NO_THROW(Instance.Register, fakeClass)

    EXPECT_NO_THROW(Instance.DeRegister, fakeClass)
  end)
  "CREATION" (function()
    local fakeClass = {ClassName = "Derp"}
    EXPECT_NO_THROW(Instance.Register, fakeClass)

    local argData = "Bla bla YEET"

    function fakeClass.new(data, arg)
      EXPECT_TYPE(data, "table")
      EXPECT_EQ(arg, argData)

      return data
    end

    --[[
      local AllInstances = {
        IsInstance = true,
        Archivable = true,
        ClassName = class.ClassName,
        Name = class.ClassName,
        Children = setmetatable({_proxy = {}}, childrenMetaTable),
        _proxy = {
          Parent = Instance.INSTANCE_ROOT,
          Class = class
        },
        WRITING = true,
        _internal = {}
      }
    ]]

    local classObject
    EXPECT_NO_THROW(function() classObject = Instance.new(fakeClass, argData) end)
    EXPECT_TYPE(classObject, "table")
    EXPECT_TRUE(classObject.Archivable)
    EXPECT_TRUE(classObject.IsInstance)
    EXPECT_EQ(classObject.ClassName, fakeClass.ClassName)
    EXPECT_EQ(classObject.Name, fakeClass.ClassName)
    EXPECT_TYPE(classObject.Children, "table")
    EXPECT_EQ(classObject.Parent, Instance.INSTANCE_ROOT)
    EXPECT_EQ(classObject._proxy.Class, fakeClass)
    EXPECT_TRUE(classObject.WRITING)
    EXPECT_TYPE(classObject._internal, "table")

    EXPECT_NO_THROW(function() classObject.Value = 32 end)
    
    classObject.WRITING = nil

    EXPECT_THROW_ANY_ERROR(function() classObject.Value2 = 32 end)

    EXPECT_NO_THROW(Instance.DeRegister, fakeClass)
  end)
  "CLONE" (function()
    local v1 = Instance.new(dummyClass, "Hello World!")
    local v2
    EXPECT_NO_THROW(function() v2 = v1:Clone() end)
    EXPECT_EQ(v1.value, v2.value)
  end)
  "CHILDREN_ASSIGNMENT" (function()
    print()
    local v1 = Instance.new(dummyClass, "DerpDerp")
    v1.Name = "Parent" -- just so I remember later on
    local v2 = Instance.new(dummyClass, "Bruh")
    v2.Name = "Child"

    v2.Parent = v1

    EXPECT_EQ(v1.Children[1], v2)

    v2.Parent = nil

    EXPECT_EQ(v1.Children[1], nil)
    EXPECT_EQ(v2.Parent, Instance.INSTANCE_ROOT)
  end)
  "CLEAR_ALL_CHILDREN" (function()
    local v1 = Instance.new(dummyClass, "EEEEE")
    v1.Name = "Parent"
    local v2 = Instance.new(dummyClass, "AAAAA")
    v2.Name = "Child1"
    local v3 = Instance.new(dummyClass, "IIIII")
    v3.Name = "Child2"
    local v4 = Instance.new(dummyClass, "OOOOO")
    v4.Name = "Child3"

    v2.Parent = v1
    v3.Parent = v1
    v4.Parent = v1

    EXPECT_EQ(#v1.Children._proxy, 3)

    v1:ClearAllChildren()

    EXPECT_EQ(#v1.Children, 0)

    EXPECT_DEEP_TABLE_EQ(v2, {})
    EXPECT_DEEP_TABLE_EQ(v3, {})
    EXPECT_DEEP_TABLE_EQ(v4, {})
  end)
  "DESTROY" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "FIND_FIRST_ANCESTOR" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "FIND_FIRST_ANCESTOR_OF_CLASS" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "FIND_FIRST_ANCESTOR_WHICH_IS_A" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "FIND_FIRST_CHILD" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "FIND_FIRST_CHILD_OF_CLASS" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "FIND_FIRST_CHILD_WHICH_IS_A" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "FIND_FIRST_DESCENDANT" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "GET_ACTOR" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "GET_CHILDREN" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "GET_FULL_NAME" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "IS_A" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "IS_ANCESTOR_OF" (DISABLED, function()
    FAIL("Unimplemented")
  end)
  "IS_DESCENDANT_OF" (DISABLED, function()
    FAIL("Unimplemented")
  end)
