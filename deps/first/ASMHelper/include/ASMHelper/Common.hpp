#pragma once

#ifdef WIN32
#ifndef RC_ASM_HELPER_EXPORTS
#ifndef RC_ASM_HELPER_BUILD_STATIC
#ifndef RC_ASM_API
#define RC_ASM_API __declspec(dllimport)
#endif
#else
#ifndef RC_ASM_API
#define RC_ASM_API
#endif
#endif
#else
#ifndef RC_ASM_API
#define RC_ASM_API __declspec(dllexport)
#endif
#endif

#else

#ifndef RC_ASM_API
#ifndef RC_ASM_HELPER_EXPORTS
#define RC_ASM_API __attribute__ ((visibility ("default")))//extern
#else
#define RC_ASM_API __attribute__ ((visibility ("default")))
#endif
#endif

#endif
