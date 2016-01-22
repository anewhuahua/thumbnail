local fullname, width, height, name, oext, ext, way, no_cache =
  ngx.var.fullname, ngx.var.width, ngx.var.height, ngx.var.name, ngx.var.oext, ngx.var.ext, ngx.var.way, ngx.var.nocache


local images_dir = "images/" -- where images come from
local cache_dir = "cache/" .. way .. "/" -- where images are cached

local function return_not_found(msg)
  ngx.status = ngx.HTTP_NOT_FOUND
  ngx.header["Content-type"] = "text/html"
  ngx.say(msg or "not found")
  ngx.exit(0)
end

local source_fname = images_dir .. name .. "." .. oext

-- make sure the file exists
local file = io.open(source_fname)

if not file then
  ngx.log(ngx.ERR, "source file "  .. source_fname .. "not found\n")
  return_not_found()
end

file:close()

local dest_fname = cache_dir .. fullname

-- resize the image
if way == "gm" then
    local size = width .. "x" .. height
    local magick = require("magick")
    magick.thumb(source_fname, size, dest_fname)
elseif way == "cv" then
    local cv = require("opencv")
    local c = cv.load_image(source_fname, cv.load_image_unchanged)
    c:resize(width, height)
    c:write(dest_fname)
else
    return_not_found()
end

if no_cache then
    ngx.exec("/images_" .. way .. "/" .. fullname)
else
    ngx.exec(ngx.var.request_uri)
end
