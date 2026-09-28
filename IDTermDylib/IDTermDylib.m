#import <Foundation/Foundation.h>
#include <sys/utsname.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
__attribute__((visibility("default"))) const char *idterm_version(void){return "PI Terminal Dylib 2.0";}
__attribute__((visibility("default"))) int idterm_sandbox_root(char*out,size_t n){if(!out||!n)return EINVAL;const char*p=NSHomeDirectory().UTF8String;size_t l=strlen(p);if(l+1>n)return ENOSPC;memcpy(out,p,l+1);return 0;}
__attribute__((visibility("default"))) int idterm_file_list(const char*path,char*out,size_t n){if(!out||!n)return EINVAL;NSString*p=path?[NSString stringWithUTF8String:path]:@".";p=[p hasPrefix:@"/"]?p:[NSHomeDirectory() stringByAppendingPathComponent:p];p=[p stringByStandardizingPath];NSString*h=[NSHomeDirectory() stringByStandardizingPath];if(![p isEqual:h]&&![p hasPrefix:[h stringByAppendingString:@"/"]])return EACCES;NSError*e=nil;NSArray*a=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:p error:&e];if(!a)return(int)(e.code?:EIO);NSString*s=[[a sortedArrayUsingSelector:@selector(localizedStandardCompare:)]componentsJoinedByString:@"\n"];NSData*d=[s dataUsingEncoding:NSUTF8StringEncoding];if(d.length+1>n)return ENOSPC;memcpy(out,d.bytes,d.length);out[d.length]=0;return 0;}
__attribute__((visibility("default"))) int idterm_system_info(char*out,size_t n){if(!out||!n)return EINVAL;struct utsname u;uname(&u);NSString*s=[NSString stringWithFormat:@"kernel=%s\nmachine=%s\nos=%@\nuid=%d gid=%d\nhome=%@\n",u.release,u.machine,NSProcessInfo.processInfo.operatingSystemVersionString,getuid(),getgid(),NSHomeDirectory()];NSData*d=[s dataUsingEncoding:NSUTF8StringEncoding];if(d.length+1>n)return ENOSPC;memcpy(out,d.bytes,d.length);out[d.length]=0;return 0;}
__attribute__((constructor))static void loaded(void){NSLog(@"[PI Terminal] native sandbox dylib loaded");}
