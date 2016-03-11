local base_dir = "/data/thumbnail/www"
local local_location_prefix = "/local"

local opath, width, height, ext, debug =
ngx.var.opath, ngx.var.width, ngx.var.height, ngx.var.ext, ngx.var.debug

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

local function exist_file(path)
    if not path then return false end
    return os.rename(path, path)
end

local function exist_dir(path)
    if not exist_file(path) then return false end
    local f = io.open(path)
    if f then
        f:close()
        return true
    end
    return false
end

local function com_cmd_resize(orig_pic_bob, w, h, cmd_getter)
    local src_file = base_dir .. opath
    local dst_uri = opath .. "_" .. w .. "x" .. h
    local dst_file = base_dir .. dst_uri
    local dir = src_file:match("(.*/)")
    if not exist_dir(dir) then
        if os.execute("mkdir -p " .. dir) then
            return_server_error() end
    end
    local src_f = io.open(src_file, "w")
    if not src_f then return_server_error() end
    src_f:write(orig_pic_bob)
    src_f:close()
    local cmd = cmd_getter(w, h, src_file, dst_file)
    local result = os.execute(cmd)
    if result ~= 0 then
        if debug then
            ngx.log(ngx.ERR, "exec gm convert failed")
        end
        return_server_error()
    end
    ngx.exec(local_location_prefix .. dst_uri)
end

local function gm_cmd_getter(w, h, src_file, dst_file)
    local cmd = "gm convert -resize " .. w .. "x" .. h .. " " .. src_file .. " " .. dst_file
    return cmd
end

local function gs_cmd_getter(w, h, src_file, dst_file)
    local cmd = "gifsicle --resize " .. w .. "x" .. h .. " " .. src_file .. " --resize-method catrom -o " .. dst_file
    return cmd
end

local function gm_cmd_resize(orig_pic_bob, w, h)
    com_cmd_resize(orig_pic_bob, w, h, gm_cmd_getter)
end

local function gs_cmd_resize(orig_pic_bob, w, h)
    com_cmd_resize(orig_pic_bob, w, h, gs_cmd_getter)
end

local function is_gif(orig_pic_bob)
    -- compare whether startswith GIF87a or GIF89a
    local cmp_str = string.sub(orig_pic_bob, 1, 6)
    return cmp_str == "GIF87a" or cmp_str == "GIF89a"
end

local function gm_resize(img, w, h)
    local res, msg, code = img:resize(w, h)
    if not res then
        if debug then
            ngx.log(ngx.ERR, "resize failed, msg is " .. (msg and msg or "") .. ", code is " .. (code and code or ""))
        end
        return_server_error()
    end
    -- if not img:deconstruct() then 
    --     if debug then
    --         ngx.log(ngx.ERR, "decon failed")
    --     end
    --     return_server_error()
    -- end
    -- img:coalesce()
    local blob = img:get_images_blob()
    -- local magick = require("magick")
    -- local blob = magick.thumb(img, w .. "x" .. h)
    ngx.print(blob)
end

local function cv_resize(orig_pic_bob, fmt, w, h)
    local cv = require("opencv")
    -- ngx.log(ngx.ERR, "body length is " .. string.len(res.body) .. "\n")
    -- ngx.log(ngx.ERR, "width is " .. width .. "height is " .. height .. "\n")
    local c = cv.load_bytes_image(
        string.len(orig_pic_bob), orig_pic_bob,
        cv.load_image_anydept
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

width = tonumber(width)
height = tonumber(height)

if width == 0 and height == 0 then
    return_not_found()
end

local res = ngx.location.capture(
    opath,
    {args = ngx.req.get_uri_args()}
)

if not res or 200 ~= res.status then
    if debug then
        ngx.log(ngx.ERR, "")
    end
    return_not_found()
end

if res.truncated then
    ngx.log(ngx.ERR, "detect truncated\n")
    return_server_error()
end

-- resize the image
-- local magick = require("magick")
-- local image = magick.load_image_from_blob(res.body)
-- if not image then
--     return_server_error()
-- end
-- local format = image:get_format()
-- image = nil

if is_gif(res.body) then
    -- gm_cmd_resize(res.body, width, height)
    -- gm_resize(image, width, height)
    gs_cmd_resize(res.body, width, height)
else
    if ext == "gif" then ext = "jpg" end
    cv_resize(res.body, ext, width, height)
end
