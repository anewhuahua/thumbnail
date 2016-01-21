#include <lua.hpp>
#include <lauxlib.h>

#include <opencv2/opencv.hpp>


static int
image_sharpen(lua_State *L)
{
    return 1;
}


static int
image_blur(lua_State *L)
{
    return 1;
}


static int
image_crop(lua_State *L)
{
    return 1;
}


static int
image_get_blob(lua_State *L)
{
    luaL_Buffer b;

    cv::Mat **m = (cv::Mat **) lua_touserdata(L,1);
	if (m == NULL) {
		return 0;
	}
    const char *fmt = luaL_checkstring(L, 2);

    cv::vector<uchar> buf;
    cv::imencode(fmt, **m, buf);

    luaL_buffinit(L, &b);
    luaL_addlstring(&b, (const char*) &buf[0], buf.size());
    // lua_pushstring(L, "hengheng\n");
    luaL_pushresult(&b);

    return 1;
}


static int
image_resize(lua_State *L)
{
    cv::Mat **m = (cv::Mat **) lua_touserdata(L,1);
	if (m == NULL) {
		return 0;
	}

    int width = luaL_checknumber(L, 2);
    int high = luaL_checknumber(L, 3);
    int flag = luaL_optnumber(L, 4, CV_INTER_LINEAR);

    if (flag < CV_INTER_NN || flag > CV_INTER_LANCZOS4) {
        return luaL_error(L, "Invalid flag  %d", flag);
    }

    cv::Mat *dm = new cv::Mat(width, high, (*m)->type());

    cv::resize(**m, *dm, dm->size(), 0, 0, flag);

    delete *m;

    *m = dm;

    return 1;
}


static int
image_write(lua_State *L)
{
    cv::Mat **m = (cv::Mat **) lua_touserdata(L,1);
	if (m == NULL) {
		return 0;
	}

    const char *filename = luaL_checkstring(L, 2);

    if (cv::imwrite(filename, **m) == true) {
        return 1;
    }

    return 0;
}

static int
image_write_bytes(lua_State *L)
{
    cv::Mat **m = (cv::Mat **) lua_touserdata(L,1);
	if (m == NULL) {
		return 0;
	}

    std::vector<char> vec;
    (**m).copyTo(vec);
    // lua_pushlstring(L, reinterpret_cast<char*> (&vec[0]), vec.size());
    lua_pushlstring(L, "hello", 5);

    return 1;
}

static int
load_image(lua_State *L)
{
    const char *filename = luaL_checkstring(L, 1);

    int flag = luaL_optnumber(L, 2, CV_LOAD_IMAGE_COLOR);
    cv::Mat m = cv::imread(filename, flag);

    cv::Mat **ud = (cv::Mat **) lua_newuserdata(L, sizeof(cv::Mat *));
    *ud = new cv::Mat(m);

    if (luaL_newmetatable(L, "opencv")) {
		luaL_Reg l[] = {
			{ "resize", image_resize },
            { "sharpen", image_sharpen },
            { "blur", image_blur },
            { "crop", image_crop },
            { "get_blob", image_get_blob },
            { "write", image_write },
            { "write_bytes", image_write_bytes },
			{ NULL, NULL },
		};

		// luaL_newlib(L,l);
		luaL_register(L, "opencv", l);
        lua_setfield(L, -2, "__index");
	}

    lua_setmetatable(L, -2);

    return 1;
}

static int
load_bytes_image(lua_State *L)
{
    int len = luaL_checkint(L, 1);
    const char *bs = luaL_checklstring(L, 2, (size_t*)(&len));
    std::vector<char> vec(bs, bs+len);

    int flag = luaL_optnumber(L, 3, CV_LOAD_IMAGE_COLOR);
    cv::Mat m = cv::imdecode(vec, flag);

    cv::Mat **ud = (cv::Mat **) lua_newuserdata(L, sizeof(cv::Mat *));
    *ud = new cv::Mat(m);

    if (luaL_newmetatable(L, "opencv")) {
		luaL_Reg l[] = {
			{ "resize", image_resize },
            { "sharpen", image_sharpen },
            { "blur", image_blur },
            { "crop", image_crop },
            { "get_blob", image_get_blob },
            { "write", image_write },
            { "write_bytes", image_write_bytes },
			{ NULL, NULL },
		};

		// luaL_newlib(L,l);
		luaL_register(L, "opencv", l);
        lua_setfield(L, -2, "__index");
	}

    lua_setmetatable(L, -2);

    return 1;
}


extern "C" {
    int luaopen_opencv(lua_State *L) {
        //  luaL_checkversion(L);

        luaL_Reg l[] = {
            { "load_image", load_image },
            { "load_bytes_image", load_bytes_image },
            { NULL, NULL}
        };

        // luaL_newlib(L, l);
        luaL_register(L, "opencv", l);

        lua_pushnumber(L, CV_LOAD_IMAGE_ANYDEPTH);
        lua_setfield(L,-2,"load_image_anydepth");

        lua_pushnumber(L, CV_LOAD_IMAGE_COLOR);
        lua_setfield(L,-2,"load_image_color");

        lua_pushnumber(L, CV_LOAD_IMAGE_GRAYSCALE);
        lua_setfield(L,-2,"load_image_grayscale");

        lua_pushnumber(L, CV_INTER_NN);
        lua_setfield(L,-2,"inter_nearest");

        lua_pushnumber(L, CV_INTER_LINEAR);
        lua_setfield(L,-2,"inter_linear");

        lua_pushnumber(L, CV_INTER_AREA);
        lua_setfield(L,-2,"inter_area");

        lua_pushnumber(L, CV_INTER_CUBIC);
        lua_setfield(L,-2,"inter_cubic");

        lua_pushnumber(L, CV_INTER_LANCZOS4);
        lua_setfield(L,-2,"inter_lanczos4");

        return 1;
    }
}
