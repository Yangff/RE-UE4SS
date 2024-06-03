#pragma once

#ifdef WIN32

#ifndef RC_INI_PARSER_EXPORTS
#ifndef RC_INI_PARSER_BUILD_STATIC
#ifndef RC_INI_PARSER_API
#define RC_INI_PARSER_API __declspec(dllimport)
#endif
#else
#ifndef RC_INI_PARSER_API
#define RC_INI_PARSER_API
#endif
#endif
#else
#ifndef RC_INI_PARSER_API
#define RC_INI_PARSER_API __declspec(dllexport)
#endif
#endif

#else

#ifndef RC_INI_PARSER_API
#ifndef RC_INI_PARSER_EXPORTS
#define RC_INI_PARSER_API __attribute__ ((visibility ("default")))//extern
#else
#define RC_INI_PARSER_API __attribute__ ((visibility ("default")))
#endif
#endif

#endif
