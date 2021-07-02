local Instance = require "Objects.Instance"

local dummyClass, dummyClass2, dummyClass3

local ok, err = pcall(function()
  dummyClass = {ClassName = "DummyClass", _creatable = true, _properties = {someVal = "Hello"}}
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

  dummyClass2 = {ClassName = "DummyClass2", _creatable = true, _properties = {someOtherVal = "World!"}}
  Instance.Register(dummyClass2, {dummyClass})

  function dummyClass2.new(instanceData)
    function instanceData._internal:Clone()
      return Instance.new(dummyClass2, self.value)
    end
    function instanceData._internal:Destroy()
      for k, v in pairs(self) do self[k] = nil end
    end

    instanceData.WRITING = nil

    return instanceData
  end

  dummyClass3 = {ClassName = "DummyClass3", _creatable = true, _properties = {thirdVal = "Bruh"}}
  Instance.Register(dummyClass3, {dummyClass, dummyClass2})

  function dummyClass3.new(instanceData)
    function instanceData._internal:Clone()
      return Instance.new(dummyClass3, self.value)
    end
    function instanceData._internal:Destroy()
      for k, v in pairs(self) do self[k] = nil end
    end

    instanceData.WRITING = nil

    return instanceData
  end
end)

if not ok then printError("Failed to create dummy classes.") error(err, -1) end
if not dummyClass or not dummyClass2 or not dummyClass3 then error("Failed to create dummy classes: Unknown", -1) end

cctest.newSuite "TestInstance"
  "[DE]REGISTRATION" (function()
    local fakeClass = {}
    ASSERT_NO_THROW(Instance.Register, fakeClass)

    EXPECT_NO_THROW(Instance.DeRegister, fakeClass)
  end)
  "CREATION" (function()
    local fakeClass = {ClassName = "Derp", _creatable = true}
    ASSERT_NO_THROW(Instance.Register, fakeClass)

    local argData = "Bla bla YEET"

    function fakeClass.new(data, arg)
      EXPECT_TYPE(data, "table")
      EXPECT_EQ(arg, argData)

      return data
    end

    local classObject
    ASSERT_NO_THROW(function() classObject = Instance.new(fakeClass, argData) end)
    ASSERT_TYPE(classObject, "table")
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
  "INHERITANCE_1_DEPTH" (function()
    local obj = Instance.new(dummyClass2)

    EXPECT_EQ(obj.someVal, dummyClass._properties.someVal)
    EXPECT_EQ(obj.someOtherVal, dummyClass2._properties.someOtherVal)
  end)
  "INHERITANCE_2_DEPTH" (function()
    local obj = Instance.new(dummyClass3)

    EXPECT_EQ(obj.someVal, dummyClass._properties.someVal)
    EXPECT_EQ(obj.someOtherVal, dummyClass2._properties.someOtherVal)
    EXPECT_EQ(obj.thirdVal, dummyClass3._properties.thirdVal)
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
  "DESTROY" (function()
    local fakeClass = {ClassName = "TestDestruction", _creatable = true}
    ASSERT_NO_THROW(Instance.Register, fakeClass)
    local destructorTimesRun = 0

    function fakeClass.new(data)
      EXPECT_TYPE(data, "table")

      function data._internal.Destroy(self)
        for k, v in pairs(self) do self[k] = nil end
        destructorTimesRun = destructorTimesRun + 1
      end

      return data
    end

    local fake1 = Instance.new(fakeClass)
    fake1.Name = "Parent"

    local fake2 = Instance.new(fakeClass)
    fake2.Name = "Child"
    fake2.Parent = fake1

    ASSERT_NO_THROW(fake1.Destroy, fake1)
    ASSERT_EQ(destructorTimesRun, 2)

    -- The metatable should be removed, so we should be able to throw any index into the table and not error.
    EXPECT_NO_THROW(function() local x = fake1.randomIndex end)
    EXPECT_NO_THROW(function() local x = fake2.randomIndex end)


    -- Nothing should exist in the tables.
    for k, v in pairs(fake1) do
      FAIL(string.format("fake1 key '%s' still exists (value: %s)", k, v))
    end
    for k, v in pairs(fake2) do
      FAIL(string.format("fake2 key '%s' still exists (value: %s)", k, v))
    end

    EXPECT_NO_THROW(Instance.DeRegister, fakeClass)
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
