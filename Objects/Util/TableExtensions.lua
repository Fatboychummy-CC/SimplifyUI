local TE = {}

function TE.find(t, v)
  for i = 1, #t do
    if t[i] == v then
      return i
    end
  end
end

function TE.deepCopy(t)
  local nt = {}
  
  for k, v in pairs(t) do
    if type(v) == "table" then
      nt[k] = TE.deepCopy(v)
    else
      nt[k] = v
    end
  end

  return nt
end

function TE.copy(t)
  local nt = {}

  for k, v in pairs(t) do
    nt[k] = v
  end

  return nt
end

return TE
