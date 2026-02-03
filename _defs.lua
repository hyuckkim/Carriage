---@meta
---@class g
g = {}

function g.rect(x, y, w, h) end
function g.color(r, g, b, a) end
function g.text(font, text, x, y) end

---@reutrn number
---@return number
function g.fontSize(id, text) end
function g.image(imgId, x, y, w, h, sx, sy, sw, sh) end
function g.setClip(x, y, w, h) end
function g.resetClip() end

---@class is
is = {}

---@param keyCode number
---@return boolean
function is.key(keyCode) end

---@return number x
---@return number y
---@return boolean lbt
---@return boolean rbt
function is.mouse() end

---@class res
res = {}

function res.image(path) end
function res.font(name, size) end
function res.fontFile(path, name, size) end

---@class sys
sys = {}

function sys.setSize(w, h) end
function sys.setPos(x, y) end
function sys.getSize() end
function sys.getPos() end
function sys.getScreenSize() end
function sys.getWorkArea() end
function sys.showCursor(bool) end
function sys.setCursor() end
function sys.quit() end