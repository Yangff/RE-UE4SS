#pragma once

#ifdef WIN32

#ifndef RC_DYNAMIC_OUTPUT_EXPORTS
#ifndef RC_DYNAMIC_OUTPUT_BUILD_STATIC
#ifndef RC_DYNOUT_API
#define RC_DYNOUT_API __declspec(dllimport)
#endif
#else
#ifndef RC_DYNOUT_API
#define RC_DYNOUT_API
#endif
#endif
#else
#ifndef RC_DYNOUT_API
#define RC_DYNOUT_API __declspec(dllexport)
#endif
#endif

#else

#ifndef RC_DYNOUT_API
#ifndef RC_DYNAMIC_OUTPUT_EXPORTS
#define RC_DYNOUT_API __attribute__ ((visibility ("default")))//extern
#else
#define RC_DYNOUT_API __attribute__ ((visibility ("default")))
#endif
#endif

#endif