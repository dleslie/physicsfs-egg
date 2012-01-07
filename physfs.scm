(module physfs 
        (archive-info?
         archive-info-author
         archive-info-author-set!
         archive-info-description
         archive-info-description-set!
         archive-info-extension
         archive-info-extension-set!
         archive-info-url
         archive-info-url-set!
         add-to-search-path
         close
         deinit
         delete
         directory?
         enumerate-files
         eof
         exists
         file-length
         file-opaque
         flush
         get-base-dir
         get-cdrom-dirs
         get-dir-separator
         get-last-error
         get-last-mod-time
         get-mount-point
         get-real-dir
         get-search-path
         get-user-dir
         get-write-dir
         init
         init?
         linked-version
         make-archive-info
         make-version
         mkdir
         mount
         open-append
         open-read
         open-write
         permit-symbolic-links
         read-from-file
         read-sbe16
         read-sbe32
         read-sle16
         read-sle32
         read-ube16
         read-ube32
         read-ule16
         read-ule32
         remove-from-search-path
         seek
         set-buffer
         set-sane-config
         set-write-dir
         supported-archive-types
         swap-sbe16
         swap-sbe32
         swap-sbe64
         swap-sle16
         swap-sle32
         swap-sle64
         swap-ube16
         swap-ube32
         swap-ube64
         swap-ule16
         swap-ule32
         swap-ule64
         symbolic-link?
         symbolic-links-permitted
         tell
         utf8-from-latin1
         utf8-from-ucs2
         utf8-from-ucs4
         utf8-to-ucs2
         utf8-to-ucs4
         version?
         version-major
         version-minor
         version-patch
         write-sbe16
         write-sbe32
         write-sbe64
         write-sle16
         write-sle32
         write-sle64
         write-to-file
         write-ube16
         write-ube32
         write-ube64
         write-ule16
         write-ule32
         write-ule64)

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

typedef struct PHYSFS_File
{
    void *opaque;
} PHYSFS_File;

extern void PHYSFS_permitSymbolicLinks(bool allow);
extern bool PHYSFS_deinit();
extern bool PHYSFS_setWriteDir(const char *newDir);
extern bool PHYSFS_removeFromSearchPath(const char *oldDir);
extern bool PHYSFS_mkdir(const char *dirName);
extern bool PHYSFS_delete(const char *filename);
extern bool PHYSFS_exists(const char *fname);
extern bool PHYSFS_isDirectory(const char *fname);
extern bool PHYSFS_isSymbolicLink(const char *fname);
extern bool PHYSFS_close(PHYSFS_File *handle);
extern bool PHYSFS_eof(PHYSFS_File *handle);
extern bool PHYSFS_flush(PHYSFS_File *handle);
extern bool PHYSFS_setSaneConfig(const char *organization, const char *appName, const char *archiveExt, bool includeCdRoms, bool archivesFirst);
extern bool PHYSFS_addToSearchPath(const char *newDir, bool appendToPath);
extern bool PHYSFS_writeSLE16(PHYSFS_File *file, PHYSFS_sint16 val);
extern bool PHYSFS_writeULE16(PHYSFS_File *file, PHYSFS_uint16 val);
extern bool PHYSFS_writeSBE16(PHYSFS_File *file, PHYSFS_sint16 val);
extern bool PHYSFS_writeUBE16(PHYSFS_File *file, PHYSFS_uint16 val);
extern bool PHYSFS_writeSLE32(PHYSFS_File *file, PHYSFS_sint32 val);
extern bool PHYSFS_writeULE32(PHYSFS_File *file, PHYSFS_uint32 val);
extern bool PHYSFS_writeSBE32(PHYSFS_File *file, PHYSFS_sint32 val);
extern bool PHYSFS_writeUBE32(PHYSFS_File *file, PHYSFS_uint32 val);
extern bool PHYSFS_isInit();
extern bool PHYSFS_symbolicLinksPermitted();
extern bool PHYSFS_mount(const char *newDir, const char *mountPoint, bool appendToPath);
extern const char *PHYSFS_getDirSeparator();
extern const char *PHYSFS_getBaseDir();
extern const char *PHYSFS_getUserDir();
extern const char *PHYSFS_getWriteDir();
extern const char *PHYSFS_getRealDir(const char *filename);
extern PHYSFS_File *PHYSFS_openWrite(const char *filename);
extern PHYSFS_File *PHYSFS_openAppend(const char *filename);
extern PHYSFS_File *PHYSFS_openRead(const char *filename);
extern PHYSFS_sint16 PHYSFS_swapSLE16(PHYSFS_sint16 val);
extern PHYSFS_uint16 PHYSFS_swapULE16(PHYSFS_uint16 val);
extern PHYSFS_sint32 PHYSFS_swapSLE32(PHYSFS_sint32 val);
extern PHYSFS_uint32 PHYSFS_swapULE32(PHYSFS_uint32 val);
extern PHYSFS_sint16 PHYSFS_swapSBE16(PHYSFS_sint16 val);
extern PHYSFS_uint16 PHYSFS_swapUBE16(PHYSFS_uint16 val);
extern PHYSFS_sint32 PHYSFS_swapSBE32(PHYSFS_sint32 val);
extern PHYSFS_uint32 PHYSFS_swapUBE32(PHYSFS_uint32 val);
extern const char *PHYSFS_getMountPoint(const char *dir);
#endif

#ifdef CHICKEN
bool init();
#else
int init()
{
    if (C_main_argv != NULL)
	return PHYSFS_init(C_main_argv[0]);
    else
	return PHYSFS_init(NULL);
}
#endif

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

(define getLastError (foreign-lambda nonnull-c-string "PHYSFS_getLastError"))

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
                                           if (0 != PHYSFS_readSLE16(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readULE16 (foreign-lambda* unsigned-short (((c-pointer File) file))
                                          "PHYSFS_uint16 val = 0;
                                           if (0 != PHYSFS_readULE16(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readSBE16 (foreign-lambda* short (((c-pointer File) file))
                                          "PHYSFS_sint16 val = 0;
                                           if (0 != PHYSFS_readSBE16(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readUBE16 (foreign-lambda* unsigned-short (((c-pointer File) file))
                                          "PHYSFS_uint16 val = 0;
                                           if (0 != PHYSFS_readUBE16(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readSLE32 (foreign-lambda* integer32 (((c-pointer File) file))
                                          "PHYSFS_sint32 val = 0;
                                           if (0 != PHYSFS_readSLE32(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readULE32 (foreign-lambda* unsigned-integer32 (((c-pointer File) file))
                                          "PHYSFS_uint32 val = 0;
                                           if (0 != PHYSFS_readULE32(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readSBE32 (foreign-lambda* integer32 (((c-pointer File) file))
                                          "PHYSFS_sint32 val = 0;
                                           if (0 != PHYSFS_readSBE32(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readUBE32 (foreign-lambda* unsigned-integer32 (((c-pointer File) file))
                                          "PHYSFS_uint32 val = 0;
                                           if (0 != PHYSFS_readUBE32(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))



(define readSLE64 (foreign-lambda* integer64 (((c-pointer File) file))
                                          "PHYSFS_sint64 val = 0;
                                           if (0 != PHYSFS_readSLE64(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readULE64 (foreign-lambda* unsigned-integer64 (((c-pointer File) file))
                                          "PHYSFS_uint64 val = 0;
                                           if (0 != PHYSFS_readULE64(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readSBE64 (foreign-lambda* integer64 (((c-pointer File) file))
                                          "PHYSFS_sint64 val = 0;
                                           if (0 != PHYSFS_readSBE64(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

(define readUBE64 (foreign-lambda* integer64 (((c-pointer File) file))
                                          "PHYSFS_uint64 val = 0;
                                           if (0 != PHYSFS_readUBE64(file, &val))
                                             C_return(val);
                                           else
                                             C_return(C_SCHEME_FALSE);"))

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

;;; Scheme style renames for library functions. Here goes!
(define permit-symbolic-links permitSymbolicLinks)
(define set-write-dir setWriteDir)
(define remove-from-search-path removeFromSearchPath)
(define directory? isDirectory)
(define symbolic-link? isSymbolicLink)
(define set-sane-config setSaneConfig)
(define add-to-search-path addToSearchPath)
(define write-sle16 writeSLE16)
(define write-ule16 writeULE16)
(define write-sbe16 writeSBE16)
(define write-ube16 writeUBE16)
(define write-sle32 writeSLE32)
(define write-ule32 writeULE32)
(define write-sbe32 writeSBE32)
(define write-ube32 writeUBE32)
(define init? isInit)
(define symbolic-links-permitted symbolicLinksPermitted)
(define get-dir-separator getDirSeparator)
(define get-base-dir getBaseDir)
(define get-user-dir getUserDir)
(define get-write-dir getWriteDir)
(define get-real-dir getRealDir)
(define open-write openWrite)
(define open-append openAppend)
(define open-read openRead)
(define swap-sle16 swapSLE16)
(define swap-ule16 swapULE16)
(define swap-sbe16 swapSBE16)
(define swap-ube16 swapUBE16)
(define swap-sle32 swapSLE32)
(define swap-ule32 swapULE32)
(define swap-sbe32 swapSBE32)
(define swap-ube32 swapUBE32)
(define get-mount-point getMountPoint)
(define linked-version linkedVersion)
(define get-last-error getLastError)
(define supported-archive-types supportedArchiveTypes)
(define get-cdrom-dirs getCdRomDirs)
(define get-search-path getSearchPath)
(define enumerate-files enumerateFiles)
(define read-sle16 readSLE16)
(define read-sbe16 readSBE16)
(define read-ule16 readULE16)
(define read-ube16 readUBE16)
(define read-sle32 readSLE32)
(define read-sbe32 readSBE32)
(define read-ule32 readULE32)
(define read-ube32 readUBE32)
(define write-sle64 writeSLE64)
(define write-ule64 writeULE64)
(define write-sbe64 writeSBE64)
(define write-ube64 writeUBE64)
(define get-last-mod-time getLastModTime)
(define file-length fileLength)
(define set-buffer setBuffer)
(define swap-sle64 swapSLE64)
(define swap-ule64 swapULE64)
(define swap-sbe64 swapSBE64)
(define swap-ube64 swapUBE64)
(define utf8-from-ucs4 utf8FromUcs4)
(define utf8-to-ucs4 utf8ToUcs4)
(define utf8-from-ucs2 utf8FromUcs2)
(define utf8-to-ucs2 utf8ToUcs2)
(define utf8-from-latin1 utf8FromLatin1)
(define archive-info? ArchiveInfo?)
(define make-archive-info make-ArchiveInfo)
(define archive-info-author ArchiveInfo-author)
(define archive-info-author-set! ArchiveInfo-author-set!)
(define archive-info-description ArchiveInfo-description)
(define archive-info-description-set! ArchiveInfo-description-set!)
(define archive-info-extension ArchiveInfo-extension)
(define archive-info-extension-set! ArchiveInfo-extension-set!)
(define archive-info-url ArchiveInfo-url)
(define archive-info-url-set! ArchiveInfo-url-set!)
(define version? Version?)
(define make-version make-Version)
(define version-major Version-major)
(define version-minor Version-minor)
(define version-patch Version-patch)
(define make-file make-File)
(define file-opaque File-opaque)

(define (read-from-file file-name)
  (if (not (init?))
      (error "PhysicsFS must be initialized"))
  (if (not (string? file-name))
      (error "file-name must be a string"))
  (if (not (exists file-name))
      (error "File does not exist in mount point"))
  (let*
      ((phys-file (open-read file-name))
       (size (file-length phys-file))
       (data (make-blob size))
       (bytes-read (read phys-file data 1 size)))
    (if (>= bytes-read 0)
        (begin
          (close phys-file)
          data)
        (begin
          (close phys-file)
          #f))))

(define (write-to-file file-name data)
  (if (not (init?))
      (error "PhysicsFS must be initialized"))
  (if (not (string? file-name))
      (error "file-name must be a string"))
  (if (not (blob? data))
      (error "data must be a blob"))
  (let*
      ((phys-file (open-write file-name))
       (bytes-written (write phys-file data 1 (blob-size data))))
    (if (= bytes-written (blob-size data))
        (begin
          (close phys-file)
          bytes-written)
        (begin
          (close phys-file)
          #f))))
)
