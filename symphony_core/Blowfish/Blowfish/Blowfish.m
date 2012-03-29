//      Copyright (C) <2012> by <ladinu@gmail.com>
//
//		Permission is hereby granted, free of charge, to any person obtaining a copy
//		of this software and associated documentation files (the "Software"), to deal
//		in the Software without restriction, including without limitation the rights
//		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//		copies of the Software, and to permit persons to whom the Software is
//		furnished to do so, subject to the following conditions:
//		
//		The above copyright notice and this permission notice shall be included in
//		all copies or substantial portions of the Software.
//		
//		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//		THE SOFTWARE.  

//
//  This is a really thin wrapper around Pianobar's encrypt/decrypt functions.
//  Inorder for this to work in Macruby, objects and garbage collecetion needs-
//  to be supported.

#import "Blowfish.h"

void Init_Blowfish (void)
{
    // This is how macruby identify the module
}

@implementation Blowfish

- (id)init
{
    self = [super init];
    return self;
}

- (NSString *) encrypt:(NSString *)str
{
    const char *cstring;
    
    // Convert NSString to cstring
    cstring = [str cStringUsingEncoding:NSUTF8StringEncoding];
    
  
    // Encrypt via piano libs
    cstring = PianoEncryptString(cstring);
    
    // Convert encrypted cstring back to NSString
    str     = [[NSString alloc] initWithUTF8String:cstring];
    
    return str;
}

- (NSString *) decrypt:(NSString *)str
{
    
    const char *cstring;
    
    // Convert NSString to cstring
    cstring = [str cStringUsingEncoding:NSUTF8StringEncoding];
    
    
    // Encrypt via piano libs
    cstring = PianoDecryptString(cstring);
    
    // Convert encrypted cstring back to NSString
    
    // TODO#: For some reason I cannot change the cstring back into a NSString properly, for example if this
    // was passed on to this function (9338f5b889484c1464428ead3625924a) it would return nil when encoding is UTF8. 
    
    NSString *retStr = [[NSString alloc] initWithCString:cstring encoding:NSASCIIStringEncoding];
    

    return retStr;
}


@end
