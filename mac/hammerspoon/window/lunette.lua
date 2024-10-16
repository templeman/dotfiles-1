--
-- Spectacle.app style window management
-- https://github.com/scottwhudson/Lunette
print("== window.lunette")

hs.loadSpoon("Lunette")

spoon.Lunette:bindHotkeys({
  leftHalf = {
    { mc, "H" },
  },
  rightHalf = {
    { mc, "L" },
  },
  topHalf = {
    { mc, "K" },
  },
  bottomHalf = {
    { mc, "J" },
  },
  topLeft = false,
  topRight = false,
  bottomLeft = false,
  bottomRight = false,
  fullScreen = {
    { mc, "F" },
  },
  center = false,
  nextThird = false,
  prevThird = false,
  enlarge = false,
  shrink = false,
})

return nil
