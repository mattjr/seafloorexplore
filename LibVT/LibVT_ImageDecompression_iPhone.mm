/*
 *  LibVT_ImageDecompression_iPhone.mm
 *
 *
 *  Created by Julian Mayer on 19.03.10.
 *  Copyright 2009 A. Julian Mayer. 
 *
 */

/*
 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 3.0 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License along with this library; if not, see <http://www.gnu.org/licenses/> or write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#include "LibVT_Internal.h"
#include "LibVT.h"
#include <stdio.h>

extern vtConfig c;


void * vtuDecompressImageFile(const char *imagePath, uint32_t *pic_size)
{
	CGImageRef imageRef = [UIImage imageWithContentsOfFile:[NSString stringWithUTF8String:imagePath]].CGImage;
	size_t width = CGImageGetWidth(imageRef);
	size_t height = CGImageGetHeight(imageRef);
	CGRect rect = {{0, 0}, {width, height}};
	void *data = calloc(width * 4, height);
    CGColorSpaceRef colorSpa = CGColorSpaceCreateDeviceRGB();

	CGContextRef bitmapContext = CGBitmapContextCreate (data, width, height, 8, width * 4, colorSpa, kCGImageAlphaPremultipliedLast);

	CGContextTranslateCTM (bitmapContext, 0, height);
	CGContextScaleCTM (bitmapContext, 1.0, -1.0);

	CGContextDrawImage(bitmapContext, rect, imageRef);

	CGContextRelease(bitmapContext);
    CFRelease(colorSpa);

	if (*pic_size == 0)
		*pic_size = width;
	else {
        if(!((width == *pic_size) && (height == *pic_size))){
            fprintf(stderr,"Something bad happend in vtuDecompressImageFile %d %d %d %d\n",(int)width , *pic_size, (int)height ,*pic_size);
            //assert((width == *pic_size) && (height == *pic_size));
        }
    }

	return data;
}
void * vtuDecompressImageBuffer(const void *file_data, uint32_t file_size, uint32_t *pic_size)
{
    NSData *img_data=[[NSData alloc] initWithBytesNoCopy:(void *)file_data length:file_size];
	CGImageRef imageRef = [UIImage imageWithData:img_data].CGImage;
	size_t width = CGImageGetWidth(imageRef);
	size_t height = CGImageGetHeight(imageRef);
	CGRect rect = {{0, 0}, {width, height}};
	void *data = calloc(width * 4, height);
    CGColorSpaceRef colorSpa = CGColorSpaceCreateDeviceRGB();
    
	CGContextRef bitmapContext = CGBitmapContextCreate (data, width, height, 8, width * 4, colorSpa, kCGImageAlphaPremultipliedLast);
    
	CGContextTranslateCTM (bitmapContext, 0, height);
	CGContextScaleCTM (bitmapContext, 1.0, -1.0);
    
	CGContextDrawImage(bitmapContext, rect, imageRef);
    
	CGContextRelease(bitmapContext);
    CFRelease(colorSpa);
    
	if (*pic_size == 0)
		*pic_size = width;
	else {
        if(!((width == *pic_size) && (height == *pic_size))){
            fprintf(stderr,"Something bad happend in vtuDecompressImageFile %d %d %d %d\n",(int)width , *pic_size, (int)height ,*pic_size);
            //assert((width == *pic_size) && (height == *pic_size));
        }
    }
    [img_data release];
	return data;
}
