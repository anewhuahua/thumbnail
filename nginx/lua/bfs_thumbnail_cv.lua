local opath, width, height =
  ngx.var.opath, ngx.var.width, ngx.var.height

local base_dir = "/data/thumbnail/www"
local local_location_prefix = "/local"

width = tonumber(width)
height = tonumber(height)

local res = ngx.location.capture(
  opath,
  {args = ngx.req.get_uri_args()}
)

local function return_server_error(msg)
  ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
  ngx.header["Content-type"] = "text/html"
  ngx.say(msg or "")
  ngx.exit(0)
end

local function return_not_found(msg)
  ngx.status = ngx.HTTP_NOT_FOUND
  ngx.header["Content-type"] = "text/html"
  ngx.say(msg or "not found")
  ngx.exit(0)
end

local function gm_cmd_resize(w, h)
    local src_file = base_dir .. opath
    local dst_file = src_file .. "_" .. w .. "x" .. h
    local cmd = "gm convert -resize " .. w .. "x" .. h .. " " .. src_file .. " " .. dst_file
    local result = os.execute(cmd)
    if result ~= 0 then
        return_server_error()
    end
    ngx.exec(local_location_prefix .. dst_file)
end

local function gm_resize(img, w, h)
    img = magick.thumb(img, w .. "x" .. h)
    -- img:coalesce()
    if not img then
        return_server_error()
    end
    ngx.print(img:get_blob())
    img = nil
end

local function cv_resize(fmt, w, h)
    local cv = require("opencv")
    -- ngx.log(ngx.ERR, "body length is " .. string.len(res.body) .. "\n")
    -- ngx.log(ngx.ERR, "width is " .. width .. "height is " .. height .. "\n")
    local c = cv.load_bytes_image(
        string.len(res.body), res.body,
        cv.load_image_anydepth
    )
    local owidth, oheight = c:size()
    if owidth > w and oheight > h then
        c:resize(w, h)
        -- ngx.log(ngx.ERR, "after resize\n")
    end
    ngx.print(c:get_blob("." .. fmt))
    c:close()
    c = nil
    -- ngx.log(ngx.ERR, "hua\n")
end

if not res or 200 ~= res.status then
    return_not_found()
end

if res.truncated then
    ngx.log(ngx.ERR, "detect truncated\n")
    return_server_error()
end

-- resize the image
local magick = require("magick")
local image = magick.load_image_from_blob(res.body)
if not image then
    return_server_error()
end
local format = image:get_format()

if format == "gif" then
    gm_cmd_resize(image, width, height)
else
    image = nil
    cv_resize(format, width, height)
end
