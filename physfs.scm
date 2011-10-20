(module physfs *

  (import chicken scheme foreign bind miscmacros)

  (bind-options export-constants: #t prefix: "")
  (bind-rename/pattern "PHYSFS_" "")

  (bind* #<<ENDC
#ifndef CHICKEN
#include <physfs.h>
#endif

//////////////////////////////////////////////////////////////////////
// Bind-consumable definitions
//////////////////////////////////////////////////////////////////////

#ifdef CHICKEN
typedef unsigned short        PHYSFS_uint16;
typedef signed short          PHYSFS_sint16;
typedef unsigned int          PHYSFS_uint32;
typedef signed int            PHYSFS_sint32;

extern struct PHYSFS_Allocator;

typedef struct PHYSFS_File
{
    void *opaque;
} PHYSFS_File;

extern void PHYSFS_permitSymbolicLinks(bool allow);
extern int PHYSFS_deinit();
extern int PHYSFS_setWriteDir(const char *newDir);
extern int PHYSFS_removeFromSearchPath(const char *oldDir);
extern int PHYSFS_mkdir(const char *dirName);
extern int PHYSFS_delete(const char *filename);
extern int PHYSFS_exists(const char *fname);
extern int PHYSFS_isDirectory(const char *fname);
extern int PHYSFS_isSymbolicLink(const char *fname);
extern int PHYSFS_close(PHYSFS_File *handle);
extern int PHYSFS_eof(PHYSFS_File *handle);
extern int PHYSFS_flush(PHYSFS_File *handle);
extern const char *PHYSFS_getLastError();
extern const char *PHYSFS_getDirSeparator();
extern const char *PHYSFS_getBaseDir();
extern const char *PHYSFS_getUserDir();
extern const char *PHYSFS_getWriteDir();
extern const char *PHYSFS_getRealDir(const char *filename);
extern PHYSFS_File *PHYSFS_openWrite(const char *filename);
extern PHYSFS_File *PHYSFS_openAppend(const char *filename);
extern PHYSFS_File *PHYSFS_openRead(const char *filename);
extern int PHYSFS_setSaneConfig(const char *organization, const char *appName, const char *archiveExt, int includeCdRoms, int archivesFirst);
extern int PHYSFS_addToSearchPath(const char *newDir, int appendToPath);
extern PHYSFS_sint16 PHYSFS_swapSLE16(PHYSFS_sint16 val);
extern PHYSFS_uint16 PHYSFS_swapULE16(PHYSFS_uint16 val);
extern PHYSFS_sint32 PHYSFS_swapSLE32(PHYSFS_sint32 val);
extern PHYSFS_uint32 PHYSFS_swapULE32(PHYSFS_uint32 val);
extern PHYSFS_sint16 PHYSFS_swapSBE16(PHYSFS_sint16 val);
extern PHYSFS_uint16 PHYSFS_swapUBE16(PHYSFS_uint16 val);
extern PHYSFS_sint32 PHYSFS_swapSBE32(PHYSFS_sint32 val);
extern PHYSFS_uint32 PHYSFS_swapUBE32(PHYSFS_uint32 val);
extern int PHYSFS_writeSLE16(PHYSFS_File *file, PHYSFS_sint16 val);
extern int PHYSFS_writeULE16(PHYSFS_File *file, PHYSFS_uint16 val);
extern int PHYSFS_writeSBE16(PHYSFS_File *file, PHYSFS_sint16 val);
extern int PHYSFS_writeUBE16(PHYSFS_File *file, PHYSFS_uint16 val);
extern int PHYSFS_writeSLE32(PHYSFS_File *file, PHYSFS_sint32 val);
extern int PHYSFS_writeULE32(PHYSFS_File *file, PHYSFS_uint32 val);
extern int PHYSFS_writeSBE32(PHYSFS_File *file, PHYSFS_sint32 val);
extern int PHYSFS_writeUBE32(PHYSFS_File *file, PHYSFS_uint32 val);
extern int PHYSFS_isInit();
extern int PHYSFS_symbolicLinksPermitted();
extern int PHYSFS_mount(const char *newDir, const char *mountPoint, int appendToPath);
extern const char *PHYSFS_getMountPoint(const char *dir);
extern int PHYSFS_setAllocator(const PHYSFS_Allocator *allocator);
#endif

int init()
{
#ifndef CHICKEN
    if (C_main_argv != NULL)
	return PHYSFS_init(C_main_argv[0]);
    else
	return PHYSFS_init(NULL);
#endif
}

ENDC
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Non-trivial interfaces
;;; Mainly complex conversions and 64-bit values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-record Version
  major minor patch)

(define-record ArchiveInfo
  extension description author url)

(define-foreign-type File "PHYSFS_File")
(define-foreign-type Allocator "PHYSFS_Allocator")

(define linkedVersion
  (let*
      ((major (foreign-lambda* byte ()
                               "PHYSFS_Version version;
                                PHYSFS_getLinkedVersion(&version);
                                C_return(version.major);"))
       (minor (foreign-lambda* byte ()
                               "PHYSFS_Version version;
                                PHYSFS_getLinkedVersion(&version);
                                C_return(version.minor);"))
       (patch (foreign-lambda* byte ()
                               "PHYSFS_Version version;
                                PHYSFS_getLinkedVersion(&version);
                                C_return(version.patch);")))
    (make-Version (major) (minor) (patch))))

(define supportedArchiveTypes
  (letrec ((data-ptr (foreign-value "PHYSFS_supportedArchiveTypes()" (c-pointer c-pointer)))
           (finished? (foreign-lambda* bool (((c-pointer c-pointer) ptr))
                                       "C_return(*ptr == NULL);"))
           (next (foreign-lambda* (c-pointer c-pointer) (((c-pointer c-pointer) ptr))
                                  "C_return(ptr + 1);"))
           (extension (foreign-lambda* nonnull-c-string (((c-pointer c-pointer) ptr))
                                       "C_return((*(PHYSFS_ArchiveInfo **)ptr)->extension);"))
           (description (foreign-lambda* nonnull-c-string (((c-pointer c-pointer) ptr))
                                         "C_return((*(PHYSFS_ArchiveInfo **)ptr)->description);"))
           (author (foreign-lambda* nonnull-c-string (((c-pointer c-pointer) ptr))
                                    "C_return((*(PHYSFS_ArchiveInfo **)ptr)->author);"))
           (url (foreign-lambda* nonnull-c-string (((c-pointer c-pointer) ptr))
                                 "C_return((*(PHYSFS_ArchiveInfo **)ptr)->url);"))
           (make-rec (lambda (ptr) (make-ArchiveInfo (extension ptr) (description ptr) (author ptr) (url ptr))))
           (all-types '()))
    (until (finished? data-ptr)
           (begin
             (set! all-types (cons (make-rec data-ptr) all-types))
             (set! data-ptr (next data-ptr))))
    all-types))

(define getCdRomDirs (foreign-lambda c-string-list* "PHYSFS_getCdRomDirs"))

(define getSearchPath (foreign-lambda c-string-list* "PHYSFS_getSearchPath"))

(define enumerateFiles (foreign-lambda c-string-list* "PHYSFS_enumerateFiles" nonnull-c-string))

(define readSLE16 (foreign-lambda* short (((c-pointer File) file))
                                          "PHYSFS_sint16 val = 0;
                                           PHYSFS_readSLE16(file, &val);
                                           C_return(val);"))

(define readULE16 (foreign-lambda* unsigned-short (((c-pointer File) file))
                                          "PHYSFS_uint16 val = 0;
                                           PHYSFS_readULE16(file, &val);
                                           C_return(val);"))

(define readSBE16 (foreign-lambda* short (((c-pointer File) file))
                                          "PHYSFS_sint16 val = 0;
                                           PHYSFS_readSBE16(file, &val);
                                           C_return(val);"))

(define readUBE16 (foreign-lambda* unsigned-short (((c-pointer File) file))
                                          "PHYSFS_uint16 val = 0;
                                           PHYSFS_readUBE16(file, &val);
                                           C_return(val);"))

(define readSLE32 (foreign-lambda* integer32 (((c-pointer File) file))
                                          "PHYSFS_sint32 val = 0;
                                           PHYSFS_readSLE32(file, &val);
                                           C_return(val);"))

(define readULE32 (foreign-lambda* unsigned-integer32 (((c-pointer File) file))
                                          "PHYSFS_uint32 val = 0;
                                           PHYSFS_readULE32(file, &val);
                                           C_return(val);"))

(define readSBE32 (foreign-lambda* integer32 (((c-pointer File) file))
                                          "PHYSFS_sint32 val = 0;
                                           PHYSFS_readSBE32(file, &val);
                                           C_return(val);"))

(define readUBE32 (foreign-lambda* unsigned-integer32 (((c-pointer File) file))
                                          "PHYSFS_uint32 val = 0;
                                           PHYSFS_readUBE32(file, &val);
                                           C_return(val);"))

(define readSLE64 (foreign-lambda* integer64 (((c-pointer File) file))
                                          "PHYSFS_sint64 val = 0;
                                           PHYSFS_readSLE64(file, &val);
                                           C_return(val);"))

(define readULE64 (foreign-lambda* unsigned-integer64 (((c-pointer File) file))
                                          "PHYSFS_uint64 val = 0;
                                           PHYSFS_readULE64(file, &val);
                                           C_return(val);"))

(define readSBE64 (foreign-lambda* integer64 (((c-pointer File) file))
                                          "PHYSFS_sint64 val = 0;
                                           PHYSFS_readSBE64(file, &val);
                                           C_return(val);"))

(define readUBE64 (foreign-lambda* integer64 (((c-pointer File) file))
                                          "PHYSFS_uint64 val = 0;
                                           PHYSFS_readUBE64(file, &val);
                                           C_return(val);"))

(define writeSLE64 (foreign-lambda integer "PHYSFS_writeSLE64" (c-pointer File) integer64))

(define writeULE64 (foreign-lambda integer "PHYSFS_writeULE64" (c-pointer File) integer64))

(define writeSBE64 (foreign-lambda integer "PHYSFS_writeSBE64" (c-pointer File) integer64))

(define writeUBE64 (foreign-lambda integer "PHYSFS_writeUBE64" (c-pointer File) integer64))

(define getLastModTime (foreign-lambda integer64 "PHYSFS_getLastModTime" nonnull-c-string))

(define tell (foreign-lambda integer64 "PHYSFS_tell" (c-pointer File)))

(define fileLength (foreign-lambda integer64 "PHYSFS_fileLength" (c-pointer File)))

(define read (foreign-lambda integer64 "PHYSFS_read" (c-pointer File) nonnull-scheme-pointer unsigned-integer32 unsigned-integer32))

(define write (foreign-lambda integer64 "PHYSFS_write" (c-pointer File) nonnull-scheme-pointer unsigned-integer32 unsigned-integer32))

(define seek (foreign-lambda integer "PHYSFS_seek" (c-pointer File) unsigned-integer64))

(define setBuffer (foreign-lambda integer "PHYSFS_setBuffer" (c-pointer File) unsigned-integer64))

(define swapSLE64 (foreign-lambda integer64 "PHYSFS_swapSLE64" integer64))

(define swapULE64 (foreign-lambda unsigned-integer64 "PHYSFS_swapULE64" unsigned-integer64))

(define swapSBE64 (foreign-lambda integer64 "PHYSFS_swapSBE64" integer64))

(define swapUBE64 (foreign-lambda unsigned-integer64 "PHYSFS_swapUBE64" unsigned-integer64))

(define utf8FromUcs4 (foreign-lambda* scheme-object ((c-string src) (unsigned-integer64 len))
                                             "C_word *ptr = C_alloc(C_SIZEOF_VECTOR(len));
                                              C_word sdst = C_vector(&ptr, len);
                                              PHYSFS_utf8FromUcs4((PHYSFS_uint32 *)C_data_pointer(sdst), src, len);
                                              C_return(sdst);"))

(define utf8ToUcs4 (foreign-lambda* scheme-object ((nonnull-u32vector src) (unsigned-integer64 len))
                                           "C_word *ptr = C_alloc(C_SIZEOF_VECTOR(len));
                                              C_word sdst = C_vector(&ptr, len);
                                              PHYSFS_utf8ToUcs4((const char *)C_data_pointer(sdst), src, len);
                                              C_return(sdst);"))

(define utf8FromUcs2 (foreign-lambda* c-string* ((nonnull-u16vector src) (unsigned-integer64 len))
                                             "char *dst = (char *)C_alloc(len);
                                              PHYSFS_utf8FromUcs2(src, dst, len);;
                                              C_return(dst);"))

(define utf8ToUcs2 (foreign-lambda* scheme-object ((nonnull-u16vector src) (unsigned-integer64 len))
                                           "C_word *ptr = C_alloc(C_SIZEOF_VECTOR(len));
                                              C_word sdst = C_vector(&ptr, len);
                                              PHYSFS_utf8ToUcs2((const char *)C_data_pointer(sdst), src, len);
                                              C_return(sdst);"))

(define utf8FromLatin1 (foreign-lambda* c-string* ((blob src) (unsigned-integer64 len))
                                               "char *dst = (char *)C_alloc(sizeof(char) * len);
                                              PHYSFS_utf8FromLatin1((char *)src, dst, len);;
                                              C_return(dst);"))

;; typedef void (*PHYSFS_StringCallback)(void *data, const char *str)
;; typedef void (*PHYSFS_EnumFilesCallback)(void *data, const char *origdir, const char *fname)
;; extern void PHYSFS_getCdRomDirsCallback(PHYSFS_StringCallback c, void *d)
;; extern void PHYSFS_enumerateFilesCallback(const char *dir, PHYSFS_EnumFilesCallback c, void *d)
;; extern void PHYSFS_getSearchPathCallback(PHYSFS_StringCallback c, void *d)

)