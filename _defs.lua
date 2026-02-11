---@meta
---@class g
g = {}

function g.rect(x, y, w, h) end
function g.circle(x, y, radius) end
function g.text(font, text, x, y) end
function g.polygon(polygonXYXY) end
function g.polyline(polygonXYXY) end

function g.color(r, g, b, a) end
function g.lineWidth(s) end

---@reutrn number w
---@return number h
function g.fontSize(id, text) end

function g.image(imgId, x, y, w, h, sx, sy, sw, sh, flipX) end
function g.setClip(x, y, w, h) end
function g.resetClip() end

function g.push() end
function g.pop() end
function g.translate(x, y) end
function g.scale(sx, sy, ox, oy) end
function g.clip(x, y, w, h) end

---@return Canvas
function g.offscreenCanvas(w, h) end

---@class Canvas
local Canvas = {}
function Canvas:batchBegin() end
function Canvas:batchEnd() end
function Canvas:release() end
function Canvas:color(r, g, b, a) end
function Canvas:rect(x, y, w, h, isFilled) end
function Canvas:circle(x, y, r, isFilled) end
function Canvas:polyline(polygonXYXY, closed, strokeWidth) end
function Canvas:polygon(polygonXYXY) end
function Canvas:text(fontId, name, x, y) end
function Canvas:image(imgId, x, y, w, h, sx, sy, sw, sh) end
function Canvas:draw(x, y, w, h, sx, sy, sw, sh) end

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
---@return number
function res.image(path) end
function res.font(name, size) end
function res.fontFile(path, name, size) end
function res.json(path) end

---@return Task
function res.jsonAsync(path) end

---@class Task
---@field isDone boolean
local Task = {}
function Task.check() end
function Task.getResult() end

function res.loadTable(path) end
function res.saveTable(path, table) end

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
function sys.setTopmost(bool) end

---@return {x: number, y: number, w: number, h: number, workX: number, workY: number, workW: number, workH: number}[]
function sys.getMonitors() end
function sys.quit() end