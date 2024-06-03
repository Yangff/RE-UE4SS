#pragma once

#ifdef WIN32

#ifndef RC_PARSER_BASE_EXPORTS
#ifndef RC_PARSER_BASE_BUILD_STATIC
#ifndef RC_PB_API
#define RC_PB_API __declspec(dllimport)
#endif
#else
#ifndef RC_PB_API
#define RC_PB_API
#endif
#endif
#else
#ifndef RC_PB_API
#define RC_PB_API __declspec(dllexport)
#endif
#endif

#else

#ifndef RC_PB_API
#ifndef RC_PARSER_BASE_EXPORTS
#define RC_PB_API __attribute__ ((visibility ("default")))//extern
#else
#define RC_PB_API __attribute__ ((visibility ("default")))
#endif
#endif

#endif