#include <winsock2.h>
#include <ws2tcpip.h>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN

// this is supposed to be inlined but apparently there is a flag causing it to not be
// inlined? zig mingw may be too old
PVOID WINAPI RtlSecureZeroMemory(PVOID ptr,SIZE_T cnt)
{
  volatile char *vptr = (volatile char *)ptr;
#ifdef __x86_64
  __stosb ((PBYTE)((DWORD64)vptr),0,cnt);
#else
  while (cnt != 0)
    {
      *vptr++ = 0;
      cnt--;
    }
#endif /* __x86_64 */
  return ptr;
}

// zig doesn't compile the parts of mingw that contain this for some reason
WCHAR *gai_strerrorW(int ecode)
{
    DWORD dwMsgLen __attribute__((unused));
    static WCHAR buff[GAI_STRERROR_BUFFER_SIZE + 1];
    dwMsgLen = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM|FORMAT_MESSAGE_IGNORE_INSERTS|FORMAT_MESSAGE_MAX_WIDTH_MASK,
                  NULL, ecode, MAKELANGID(LANG_NEUTRAL,SUBLANG_DEFAULT), (LPWSTR)buff,
                  GAI_STRERROR_BUFFER_SIZE, NULL);
    return buff;
}

char *gai_strerrorA(int ecode)
{
    static char buff[GAI_STRERROR_BUFFER_SIZE + 1];
    wcstombs(buff, gai_strerrorW(ecode), GAI_STRERROR_BUFFER_SIZE + 1);
    return buff;
}
