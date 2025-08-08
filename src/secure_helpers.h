#ifndef _SECURE_HELPERS_H
#define _SECURE_HELPERS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>

// Secure string copy with explicit size
static inline size_t secure_strlcpy(char *dst, const char *src, size_t dsize)
{
    const char *osrc = src;
    size_t nleft = dsize;

    if (nleft != 0) {
        while (--nleft != 0) {
            if ((*dst++ = *src++) == '\0')
                break;
        }
    }

    if (nleft == 0) {
        if (dsize != 0)
            *dst = '\0';
        while (*src++)
            ;
    }

    return (src - osrc - 1);
}

// Secure string concatenation with explicit size
static inline size_t secure_strlcat(char *dst, const char *src, size_t dsize)
{
    const char *odst = dst;
    const char *osrc = src;
    size_t n = dsize;
    size_t dlen;

    while (n-- != 0 && *dst != '\0')
        dst++;
    dlen = dst - odst;
    n = dsize - dlen;

    if (n-- == 0)
        return (dlen + strlen(src));
    while (*src != '\0') {
        if (n != 0) {
            *dst++ = *src;
            n--;
        }
        src++;
    }
    *dst = '\0';

    return (dlen + (src - osrc));
}

// Secure printf with bounds checking
static inline int secure_snprintf(char *str, size_t size, const char *format, ...)
{
    va_list args;
    int result;
    
    if (!str || size == 0)
        return -1;
        
    va_start(args, format);
    result = vsnprintf(str, size, format, args);
    va_end(args);
    
    // Ensure null termination even if truncated
    str[size - 1] = '\0';
    
    return result;
}

// Secure memory allocation with validation
static inline void* secure_malloc(size_t size)
{
    void *ptr;
    
    if (size == 0) {
        return NULL;
    }
    
    ptr = malloc(size);
    if (!ptr) {
        fprintf(stderr, "Memory allocation failed: %zu bytes\n", size);
        exit(EXIT_FAILURE);
    }
    
    // Initialize to zero for security
    memset(ptr, 0, size);
    return ptr;
}

// Secure memory reallocation
static inline void* secure_realloc(void *ptr, size_t size)
{
    void *new_ptr;
    
    if (size == 0) {
        free(ptr);
        return NULL;
    }
    
    new_ptr = realloc(ptr, size);
    if (!new_ptr) {
        fprintf(stderr, "Memory reallocation failed: %zu bytes\n", size);
        free(ptr);
        exit(EXIT_FAILURE);
    }
    
    return new_ptr;
}

// Secure memory free with pointer nullification
static inline void secure_free(void **ptr)
{
    if (ptr && *ptr) {
        free(*ptr);
        *ptr = NULL;
    }
}

// Input validation for strings
static inline int validate_string_input(const char *input, size_t max_len)
{
    if (!input) return 0;
    
    size_t len = strlen(input);
    if (len == 0 || len > max_len) return 0;
    
    // Check for control characters and null bytes
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)input[i];
        if (c < 32 && c != '\t' && c != '\n' && c != '\r') {
            return 0; // Invalid control character
        }
    }
    
    return 1; // Valid input
}

// Macros for backward compatibility and ease of use
#define SECURE_STRCPY(dst, src) secure_strlcpy(dst, src, sizeof(dst))
#define SECURE_STRCAT(dst, src) secure_strlcat(dst, src, sizeof(dst))
#define SECURE_SNPRINTF(dst, fmt, ...) secure_snprintf(dst, sizeof(dst), fmt, __VA_ARGS__)

#endif // _SECURE_HELPERS_H