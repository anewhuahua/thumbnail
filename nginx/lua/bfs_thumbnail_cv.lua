local opath, width, height, name, ext =
  ngx.var.opath, ngx.var.width, ngx.var.height, ngx.var.name, ngx.var.ext
local host = ngx.var.host

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

if not res or 200 ~= res.status then
    return_not_found()
    
end

if res.truncated then
    ngx.log(ngx.ERR, "detect truncated\n")
    return_server_error()
end



-- resize the image
local cv = require("opencv")
local magick = require("magick")

-- ngx.log(ngx.ERR, "body length is " .. string.len(res.body) .. "\n")
-- ngx.log(ngx.ERR, "width is " .. width .. "height is " .. height .. "\n")

if string.lower(ext) == "gif" then
  ngx.log(ngx.ERR, "hit gif\n")

  local img = magick.load_image_from_blob(res.body)
  local owidth  = img:get_width()
  local oheight = img:get_height()
  if owidth > width and oheight > height then
      img:resize(width, height)
  end
  ngx.print(img:get_blob())
  img=nil

else

  local c = cv.load_bytes_image(
    string.len(res.body), res.body,
    cv.load_image_anydepth
  )
  local owidth, oheight = c:size()
  if owidth > width and oheight > height then
      c:resize(width, height)
  end
  ngx.print(c:get_blob("." .. ext))
  c:close()
  c=nil

end



-- ngx.log(ngx.ERR, "hua\n")