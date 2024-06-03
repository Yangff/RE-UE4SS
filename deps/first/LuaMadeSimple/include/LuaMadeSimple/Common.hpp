#pragma once

#ifdef WIN32

#ifndef RC_LUA_MADE_SIMPLE_EXPORTS
#ifndef RC_LUA_MADE_SIMPLE_BUILD_STATIC
#ifndef RC_LMS_API
#define RC_LMS_API __declspec(dllimport)
#endif
#else
#ifndef RC_LMS_API
#define RC_LMS_API
#endif
#endif
#else
#ifndef RC_LMS_API
#define RC_LMS_API __declspec(dllexport)
#endif
#endif

#else

#ifndef RC_LMS_API
#ifndef RC_LUA_MADE_SIMPLE_EXPORTS
#define RC_LMS_API __attribute__ ((visibility ("default")))//extern
#else
#define RC_LMS_API __attribute__ ((visibility ("default")))
#endif
#endif

#endif