local function expect(n, val, ...)
  local args = table.pack(...)
  local t = type(val)

  for i = 1, args.n do
    if t == args[i] then
      return true
    end
  end

  return false,
         string.format(
           "Bad argument to test function #%d: Expected %s, got %s.",
           n,
           table.concat(
             args,
             " or "
           ),
           t
         )
end

local t_eq_error = "Tables are not equal."
local function t_eq(a, b, noflip)
  if type(a) ~= "table" or type(b) ~= "table" then return false, t_eq_error end
  for k, v in pairs(a) do
    if type(v) == "table" then
      if not t_eq(v, b[k]) then return false, t_eq_error end
    elseif v ~= b[k] then
      return false, t_eq_error
    end
  end

  if not noflip then
    return t_eq(b, a, true)
  end

  return true, ""
end

local M = {}

function M.EVENT(f, event, timeout, ...)
  local ok, e = expect(1, f, "function")
    if not ok then return false, e end
  ok, e = expect(2, event, "string")
    if not ok then return false, e end
  ok, e = expect(3, timeout, "number", "nil")
    if not ok then return false, e end

  ok, e = pcall(f, ...)
    if not ok then error(e, 0) end

  local tmr = os.startTimer(timeout or 0.25)
  while true do
    local ev = table.pack(os.pullEvent())
    if ev[1] == "timer" and ev[2] == tmr then
      return false, string.format("Timed out before receiving event '%s'.", event)
    elseif ev[1] == event then
      return true, ""
    end
  end
end

function M.EQ(a, b)
  return a == b, string.format("Values %s and %s are unequal.", tostring(a), tostring(b))
end

function M.UEQ(a, b)
  return a ~= b, string.format("Values %s and %s are equal.", tostring(a), tostring(b))
end

function M.GT(a, b)
  return a > b, string.format("Value %s is not greater than %s.", tostring(a), tostring(b))
end

function M.LT(a, b)
  return a < b, string.format("Value %s is not less than %s.", tostring(a), tostring(b))
end

function M.GTE(a, b)
  return a >= b, string.format("Value %s is not greater than or equal to %s.", tostring(a), tostring(b))
end

function M.LTE(a, b)
  return a <= b, string.format("Value %s is not less than or equal to %s.", tostring(a), tostring(b))
end

function M.DEEP_TABLE_EQ(a, b)
  local ok, e = expect(1, a, "table")
    if not ok then return false, e end
  local ok2, e2 = expect(2, b, "table")
    if not ok2 then return false, e2 end
  return t_eq(a, b)
end

function M.FLOAT_EQ(a, b, range)
  local ok, e = expect(3, range, "number", "nil")
    if not ok then return false, e end
  range = range or 0.000000000001
  return a >= b - range and a <= b + range, string.format("Value %s is not within %f of %s", tostring(a), range, tostring(b))
end

function M.TYPE(a, t)
  local ok, e = expect(2, t, "string")
    if not ok then return false, e end
  return type(a) == t, string.format("Value %s is not of type %s.", tostring(a), t)
end

function M.TYPES(a, ...)
  local types = table.pack(...)
  for i = 1, types.n do
    local ok, e = expect(i + 1, types[i], "string")
      if not ok then return false, e end

    if type(a) ~= types[i] then
      return false, string.format("Value %s is not of type %s.", tostring(a), table.concat(types, " or "))
    end
  end

  return true, ""
end

function M.TRUE(a)
  return a == true, string.format("Value %s is not 'true'.", tostring(a))
end

function M.FALSE(a)
  return a == false, string.format("Value %s is not 'false'.", tostring(a))
end

function M.TRUTHY(a)
  return not not a, string.format("Value %s is not truthy.", tostring(a))
end

function M.FALSEY(a)
  return not a, string.format("Value %s is not falsey.", tostring(a))
end

function M.THROW_ANY_ERROR(f, ...)
  local ok, e = expect(1, f, "function")
  if not ok then return false, e end
  local ok, err = pcall(f, ...)
  return not ok, "Function did not throw an error."
end

function M.THROW_MATCHED_ERROR(f, m, ...)
  local ok, e = expect(1, f, "function")
    if not ok then return false, e end
  local ok2, e2 = expect(2, m, "string")
    if not ok2 then return false, e2 end

  local ok, err = pcall(f, ...)
  if ok then return false, "Function did not throw an error." end

  local match = string.match(err, m)
  return match and true or false, string.format("Error '%s' does not match pattern '%s'.", err, m)
end

function M.NO_THROW(f, ...)
  local ok, e = expect(1, f, "function")
  if not ok then return false, e end
  local ok, err = pcall(f, ...)
  return ok, string.format("Function threw error: %s", err)
end

return M
