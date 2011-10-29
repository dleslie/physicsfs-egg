[[tags: egg physicsfs physfs zip 7z archive game]]

== physicsfs

PhysicsFS bindings for Chicken.

[[toc:]]

== Disclaimer

For now, the egg is available at:
https://github.com/dleslie/physicsfs-egg

The interface adheres closely to the stock PhysicsFS interface; with all but the callback requiring functions available.

Much thanks to Ryan C. Gordon for the original library.

== Overview

The latest version of PhysicsFS can be found at [[http://icculus.org/physfs/|Icculus.org]]

With PhysicsFS, you have a single writing directory and multiple directories (the "search path") for reading. You can think of this as a filesystem within a filesystem. If (on Windows) you were to set the writing directory to "C:\MyGame\MyWritingDirectory", then no PHYSFS calls could touch anything above this directory, including the "C:\MyGame" and "C:\" directories. This prevents an application's internal scripting language from piddling over c:\\config.sys, for example. If you'd rather give PHYSFS full access to the system's REAL file system, set the writing dir to "C:\", but that's generally A Bad Thing for several reasons.

Drive letters are hidden in PhysicsFS once you set up your initial paths. The search path creates a single, hierarchical directory structure. Not only does this lend itself well to general abstraction with archives, it also gives better support to operating systems like MacOS and Unix.

Generally speaking, you shouldn't ever hardcode a drive letter; not only does this hurt portability to non-Microsoft OSes, but it limits your win32 users to a single drive, too. Use the PhysicsFS abstraction functions and allow user-defined configuration options, too. When opening a file, you specify it like it was on a Unix filesystem: if you want to write to "C:\MyGame\MyConfigFiles\game.cfg", then you might set the write dir to "C:\MyGame" and then open "MyConfigFiles/game.cfg". This gives an abstraction across all platforms. Specifying a file in this way is termed "platform-independent notation" in this documentation. Specifying a filename in a form such as "C:\mydir\myfile" or "MacOS hard drive:My Directory:My File" is termed "platform-dependent notation". The only time you use platform-dependent notation is when setting up your write directory and search path; after that, all file access into those directories are done with platform-independent notation.

All files opened for writing are opened in relation to the write directory which is the root of the writable filesystem. When opening a file for reading, PhysicsFS goes through the search path. This is NOT the same thing as the PATH environment variable. An application using PhysicsFS specifies directories to be searched which may be actual directories, or archive files that contain files and subdirectories of their own. See the end of these docs for currently supported archive formats.

Once the search path is defined, you may open files for reading. If you've got the following search path defined (to use a win32 example again):
 *  C:\\mygame
 *  C:\\mygame\\myuserfiles
 *  D:\\mygamescdromdatafiles
 *  C:\\mygame\\installeddatafiles.zip

Then a call to (openRead "textfiles/myfile.txt") (note the directory separator, lack of drive letter, and lack of dir separator at the start of the string; this is platform-independent notation) will check for

 *  C:\\mygame\\textfiles\\myfile.txt, then
 *  C:\\mygame\\myuserfiles\\textfiles\\myfile.txt, then
 *  D:\\mygamescdromdatafiles\\textfiles\\myfile.txt, then, finally, for
 *  textfiles\\myfile.txt inside of C:\\mygame\\installeddatafiles.zip.

Remember that most archive types and platform filesystems store their filenames in a case-sensitive manner, so you should be careful to specify it correctly.

Files opened through PhysicsFS may NOT contain "." or ".." or ":" as dir elements. Not only are these meaningless on MacOS Classic and/or Unix, they are a security hole. Also, symbolic links (which can be found in some archive types and directly in the filesystem on Unix platforms) are NOT followed until you call (permitSymbolicLinks #t). That's left to your own discretion, as following a symlink can allow for access outside the write dir and search paths. For portability, there is no mechanism for creating new symlinks in PhysicsFS.

The write dir is not included in the search path unless you specifically add it. While you CAN change the write dir as many times as you like, you should probably set it once and stick to it. Remember that your program will not have permission to write in every directory on Unix and NT systems.

All files are opened in binary mode; there is no endline conversion for textfiles. Other than that, PhysicsFS has some convenience functions for platform-independence. There is a function to tell you the current platform's dir separator ("\\" on windows, "/" on Unix, ":" on MacOS), which is needed only to set up your search/write paths. There is a function to tell you what CD-ROM drives contain accessible discs, and a function to recommend a good search path, etc.

A recommended order for the search path is the write dir, then the base dir, then the cdrom dir, then any archives discovered. Quake 3 does something like this, but moves the archives to the start of the search path. Build Engine games, like Duke Nukem 3D and Blood, place the archives last, and use the base dir for both searching and writing. There is a helper function (setSaneConfig) that puts together a basic configuration for you, based on a few parameters. Also see the comments on (getBaseDir), and (getUserDir) for info on what those are and how they can help you determine an optimal search path.

PhysicsFS 2.0 adds the concept of "mounting" archives to arbitrary points in the search path. If a zipfile contains "maps/level.map" and you mount that archive at "mods/mymod", then you would have to open "mods/mymod/maps/level.map" to access the file, even though "mods/mymod" isn't actually specified in the .zip file. Unlike the Unix mentality of mounting a filesystem, "mods/mymod" doesn't actually have to exist when mounting the zipfile. It's a "virtual" directory. The mounting mechanism allows the developer to seperate archives in the tree and avoid trampling over files when added new archives, such as including mod support in a game...keeping external content on a tight leash in this manner can be of utmost importance to some applications.

PhysicsFS is mostly thread safe. The error messages returned by (getLastError) are unique by thread, and library-state-setting functions are mutex'd. For efficiency, individual file accesses are not locked, so you can not safely read/write/seek/close/etc the same  file from two threads at the same time. Other race conditions are bugs  that should be reported/patched.

While you CAN use stdio/syscall file access in a program that has physfs calls, doing so is not recommended, and you can not use system filehandles with PhysicsFS and vice versa.

Note that archives need not be named as such: if you have a ZIP file and rename it with a .PKG extension, the file will still be recognized as a ZIP archive by PhysicsFS; the file's contents are used to determine its type where possible.

Currently supported archive types:
 *    .ZIP (pkZip/WinZip/Info-ZIP compatible)
 *    .GRP (Build Engine groupfile archives)
 *    .PAK (Quake I/II archive format)
 *    .HOG (Descent I/II HOG file archives)
 *    .MVL (Descent II movielib archives)
 *    .WAD (DOOM engine archives)

String policy for PhysicsFS 2.0 and later:

PhysicsFS 1.0 could only deal with null-terminated ASCII strings. All high ASCII chars resulted in undefined behaviour, and there was no Unicode support at all. PhysicsFS 2.0 supports Unicode without breaking binary compatibility with the 1.0 API by using UTF-8 encoding of all strings passed in and out of the library.

All strings passed through PhysicsFS are in null-terminated UTF-8 format. This means that if all you care about is English (ASCII characters <= 127) then you just use regular C strings. If you care about Unicode (and you should!) then you need to figure out what your platform wants, needs, and offers. If you are on Windows and build with Unicode support, your TCHAR strings are two bytes per character (this is called "UCS-2 encoding"). You should convert them to UTF-8 before handing them to PhysicsFS with (utf8FromUcs2). If you're using Unix or Mac OS X, your wchar_t strings are four bytes per character ("UCS-4 encoding"). Use (utf8FromUcs4). Mac OS X can give you UTF-8 directly from a CFString, and many Unixes generally give you C strings in UTF-8 format everywhere. If you have a single-byte high ASCII charset, like so-many European "codepages" you may be out of luck. We'll convert from "Latin1" to UTF-8 only, and never back to Latin1. If you're above ASCII 127, all bets are off: move to Unicode or use your platform's facilities. Passing a C string with high-ASCII data that isn't UTF-8 encoded will NOT do what you expect!

Naturally, there's also (utf8ToUcs2) and (utf8ToUcs4) to get data back into a format you like. Behind the scenes, PhysicsFS will use Unicode where possible: the UTF-8 strings on Windows will be converted and used with the multibyte Windows APIs, for example.

PhysicsFS offers basic encoding conversion support, but not a whole string library. Get your stuff into whatever format you can work with.

Some platforms and archivers don't offer full Unicode support behind the scenes. For example, OS/2 only offers "codepages" and the filesystem itself doesn't support multibyte encodings. We make an earnest effort to convert to/from the current locale here, but all bets are off if you want to hand an arbitrary Japanese character through to these systems. Modern OSes (Mac OS X, Linux, Windows, PocketPC, etc) should all be fine.

Many game-specific archivers are seriously unprepared for Unicode (the Descent HOG/MVL and Build Engine GRP archivers, for example, only offer a DOS 8.3 filename, for example). Nothing can be done for these, but they tend to be legacy formats for existing content that was all ASCII (and thus, valid UTF-8) anyhow. Other formats, like .ZIP, don't explicitly offer Unicode support, but unofficially expect filenames to be UTF-8 encoded, and thus Just Work. Most everything does the right thing without bothering you, but it's good to be aware of these nuances in case they don't.

== Reference

=== File
; File : A PhysicsFS file handle.

You get a pointer to one of these when you open a file for reading, writing, or appending via PhysicsFS.

As you can see from the lack of meaningful fields, you should treat this as opaque data. Don't try to manipulate the file handle, just pass the pointer you got, unmolested, to various PhysicsFS APIs.

=== ArchiveInfo

; ArchiveInfo : Information on various PhysicsFS-supported archives.

This structure gives you details on what sort of archives are supported by this implementation of PhysicsFS. Archives tend to be things like ZIP files and such.

Available fields:
* extension : Archive file extension: "ZIP", for example.
* description : Human-readable archive description.
* author : Person who did support for this archive.
* url : URL related to this archive

; Version : Information the version of PhysicsFS in use.

Represents the library's version as three levels: major revision (increments with massive changes, additions, and enhancements), minor revision (increments with backwards-compatible changes to the major revision), and patchlevel (increments with fixes to the minor revision).

Available fields:
* major : major revision
* minor : minor revision
* patch : patchlevel

=== PhysicsFS state

; (getLinkedVersion) : Get the version of PhysicsFS that is linked against your program.

If you are using a shared library (DLL) version of PhysFS, then it is possible that it will be different than the version you compiled against.

This function may be called safely at any time, even before PHYSFS_init().

; (init) : Initialize the PhysicsFS library.

This must be called before any other PhysicsFS function.

This should be called prior to any attempts to change your process's current working directory.

Returns nonzero on success, zero on error. Specifics of the error can be gleaned from (getLastError).

; (deinit) : Deinitialize the PhysicsFS library.

This closes any files opened via PhysicsFS, blanks the search/write paths, frees memory, and invalidates all of your file handles.

Note that this call can FAIL if there's a file open for writing that refuses to close (for example, the underlying operating system was buffering writes to network filesystem, and the fileserver has crashed, or a hard drive has failed, etc). It is usually best to close all write handles yourself before calling this function, so that you can gracefully handle a specific failure.

Once successfully deinitialized, PHYSFS_init() can be called again to restart the subsystem. All default API states are restored at this point, with the exception of any custom allocator you might have specified, which survives between initializations.

Returns nonzero on success, zero on error. Specifics of the error can be gleaned from (getLastError). If failure, state of PhysFS is undefined, and probably badly screwed up.

; (supportedArchiveTypes) : Get a list of supported archive types.

Get a list of archive types supported by this implementation of PhysicFS. These are the file formats usable for search path entries. This is for informational purposes only. Note that the extension listed is merely convention: if we list "ZIP", you can open a PkZip-compatible archive with an extension of "XYZ", if you like.

The returned value is a list of ArchiveInfo records.

; (getLastError) :  Get human-readable error information.

Get the last PhysicsFS error message as a human-readable string. This will be empty if there's been no error since the last call to this function. The pointer returned by this call points to an internal buffer. Each thread has a unique error state associated with it, but each time a new error message is set, it will overwrite the previous one associated with that thread. It is safe to call this function at anytime, even before (init).

It is not wise to expect a specific string of characters here, since the error message may be localized into an unfamiliar language. These strings are meant to be passed on directly to the user.

; (getDirSeparator) : Get platform-dependent dir separator string.

This returns "\\" on win32, "/" on Unix, and ":" on MacOS. It may be more than one character, depending on the platform, and your code should take that into account. Note that this is only useful for setting up the search/write paths, since access into those dirs always use '/' (platform-independent notation) to separate directories. This is also handy for getting platform-independent access when using stdio calls.

; (permitSymbolicLinks bool) : Enable or disable following of symbolic links.

Some physical filesystems and archives contain files that are just pointers to other files. On the physical filesystem, opening such a link will (transparently) open the file that is pointed to.

By default, PhysicsFS will check if a file is really a symlink during open calls and fail if it is. Otherwise, the link could take you outside the write and search paths, and compromise security.

If you want to take that risk, call this function with a non-zero parameter. Note that this is more for sandboxing a program's scripting language, in case untrusted scripts try to compromise the system. Generally speaking, a user could very well have a legitimate reason to set up a symlink, so unless you feel there's a specific danger in allowing them, you should permit them.

Symlinks are only explicitly checked when dealing with filenames in platform-independent notation. That is, when setting up your search and write paths, etc, symlinks are never checked for.

Symbolic link permission can be enabled or disabled at any time after you've called (init), and is disabled by default.

; (getCdRomDirs) : Get an array of paths to available CD-ROM drives.

The dirs returned are platform-dependent ("D:\" on Win32, "/cdrom" or whatnot on Unix). Dirs are only returned if there is a disc ready and accessible in the drive. So if you've got two drives (D: and E:), and only E: has a disc in it, then that's all you get. If the user inserts a disc in D: and you call this function again, you get both drives. If, on a Unix box, the user unmounts a disc and remounts it elsewhere, the next call to this function will reflect that change.

This function refers to "CD-ROM" media, but it really means "inserted disc media," such as DVD-ROM, HD-DVD, CDRW, and Blu-Ray discs. It looks for filesystems, and as such won't report an audio CD, unless there's a mounted filesystem track on it.

This call may block while drives spin up. Be forewarned.

; (getBaseDir) : Get the path where the application resides.

Helper function.

Get the "base dir". This is the directory where the application was run from, which is probably the installation directory, and may or may not be the process's current working directory.

You should probably use the base dir in your search path.

; (getUserDir) : Get the path where user's home directory resides.

Helper function.

Get the "user dir". This is meant to be a suggestion of where a specific user of the system can store files. On Unix, this is her home directory. On systems with no concept of multiple home directories (MacOS, win95), this will default to something like "C:\mybasedir\users\username" where "username" will either be the login name, or "default" if the platform doesn't support multiple users, either.

You should probably use the user dir as the basis for your write dir, and also put it near the beginning of your search path.

; (getWriteDir) : Get path where PhysicsFS will allow file writing.

Get the current write dir. The default write dir is NULL.

; (setWriteDir dir) : Tell PhysicsFS where it may write files.

Set a new write dir. This will override the previous setting.

This call will fail (and fail to change the write dir) if the current write dir still has files open in it.

; (addToSearchPath newDir appendToPath)

Add an archive or directory to the search path.

This is a legacy call in PhysicsFS 2.0, equivalent to: (mount newDir "" appendToPath)

You must use this and not (mount) if binary compatibility with PhysicsFS 1.0 is important (which it may not be for many people).

; (removeFromSearchPath oldDir) : Remove a directory or archive from the search path.

This must be a (case-sensitive) match to a dir or archive already in the search path, specified in platform-dependent notation.

This call will fail (and fail to remove from the path) if the element still has files open in it.

; (getSearchPath) : Get the current search path.

The default search path is an empty list.

; (setSaneConfig organization appName archiveExt includeCdRoms archivesFirst) : Set up sane, default paths.

Helper function.

The write dir will be set to "userdir/.organization/appName", which is created if it doesn't exist.

The above is sufficient to make sure your program's configuration directory is separated from other clutter, and platform-independent. The period before "mygame" even hides the directory on Unix systems.

The search path will be:

* The Write Dir (created if it doesn't exist)
* The Base Dir (getBaseDir)
* All found CD-ROM dirs (optionally)

These directories are then searched for files ending with the extension (archiveExt), which, if they are valid and supported archives, will also be added to the search path. If you specified "PKG" for (archiveExt), and there's a file named data.PKG in the base dir, it'll be checked. Archives can either be appended or prepended to the search path in alphabetical order, regardless of which directories they were found in.

All of this can be accomplished from the application, but this just does it all for you. Feel free to add more to the search path manually, too.
=== Directory Management

; (mkdir dirName) : Create a directory.

This is specified in platform-independent notation in relation to the write dir. All missing parent directories are also created if they
 don't exist.

So if you've got the write dir set to "C:\mygame\writedir" and call (mkdir "downloads/maps") then the directories "C:\mygame\writedir\downloads" and "C:\mygame\writedir\downloads\maps" will be created if possible. If the creation of "maps" fails after we have successfully created "downloads", then the function leaves the created directory behind and reports failure.

; (delete filename) : Delete a file or directory.

(filename) is specified in platform-independent notation in relation to the write dir.

A directory must be empty before this call can delete it.

Deleting a symlink will remove the link, not what it points to, regardless of whether you "permitSymLinks" or not.

So if you've got the write dir set to "C:\mygame\writedir" and call (delete "downloads/maps/level1.map") then the file "C:\mygame\writedir\downloads\maps\level1.map" is removed from the physical filesystem, if it exists and the operating system permits the deletion.

Note that on Unix systems, deleting a file may be successful, but the actual file won't be removed until all processes that have an open filehandle to it (including your program) close their handles.

Chances are, the bits that make up the file still exist, they are just made available to be written over at a later point. Don't consider this a security method or anything.  :)

; (getRealDir filename) : Figure out where in the search path a file resides.

The file is specified in platform-independent notation. The returned filename will be the element of the search path where the file was found,
 which may be a directory, or an archive. Even if there are multiple matches in different parts of the search path, only the first one found is used, just like when opening a file.

So, if you look for "maps/level1.map", and C:\\mygame is in your search path and C:\\mygame\\maps\\level1.map exists, then "C:\mygame" is returned.

If a any part of a match is a symbolic link, and you've not explicitly permitted symlinks, then it will be ignored, and the search for a match will continue.

If you specify a fake directory that only exists as a mount point, it'll be associated with the first archive mounted there, even though that directory isn't necessarily contained in a real archive.

; (enumerateFiles dir) : Get a file listing of a search path's directory.

Matching directories are interpolated.

Feel free to sort the list however you like. We only promise there will be no duplicates, but not what order the final list will come back in.

; (exists filename) : Determine if a file exists in the search path.

Reports true if there is an entry anywhere in the search path by the name of (filename).

Note that entries that are symlinks are ignored if (permitSymbolicLinks #t) hasn't been called, so you might end up further down in the search path than expected.

; (isDirectory filename) : Determine if a file in the search path is really a directory.

Determine if the first occurence of (fname) in the search path is really a directory entry.

Note that entries that are symlinks are ignored if (permitSymbolicLinks #t) hasn't been called, so you might end up further down in the search path than expected.

; (isSymbolicLink filename) : Determine if a file in the search path is really a symbolic link.

Determine if the first occurence of (filename) in the search path is really a symbolic link.

Note that entries that are symlinks are ignored if (permitSymbolicLinks #t) hasn't been called, and as such, this function will always return 0 in that case.

; (getLastModTime filename) : Get the last modification time of a file.

The modtime is returned as a number of seconds since the epoch (Jan 1, 1970). The exact derivation and accuracy of this time depends on the particular archiver. If there is no reasonable way to obtain this information for a particular archiver, or there was some sort of error, this function returns (-1).

=== Input/Output

; (openWrite filename) : Open a file for writing.

Open a file for writing, in platform-independent notation and in relation to the write dir as the root of the writable filesystem. The specified file is created if it doesn't exist. If it does exist, it is truncated to zero bytes, and the writing offset is set to the start.

Note that entries that are symlinks are ignored if (permitSymbolicLinks #t) hasn't been called, and opening a symlink with this function will fail in such a case.

; (openAppend filename) : Open a file for appending.

Open a file for writing, in platform-independent notation and in relation to the write dir as the root of the writable filesystem. The specified file is created if it doesn't exist. If it does exist, the writing offset is set to the end of the file, so the first write will be the byte after the end.

Note that entries that are symlinks are ignored if (permitSymbolicLinks #t) hasn't been called, and opening a symlink with this function will fail in such a case.

; (openRead filename) : Open a file for reading.

Open a file for reading, in platform-independent notation. The search path is checked one at a time until a matching file is found, in which case an abstract filehandle is associated with it, and reading may be done. The reading offset is set to the first byte of the file.

Note that entries that are symlinks are ignored if (permitSymbolicLinks #t) hasn't been called, and opening a symlink with this function will fail in such a case.

; (close handle) : Close a PhysicsFS filehandle.

This call is capable of failing if the operating system was buffering writes to the physical media, and, now forced to write those changes to physical media, can not store the data for some reason. In such a case, the filehandle stays open. A well-written program should ALWAYS check the return value from the close call in addition to every writing call!

; (read handle buffer objSize objCount) : Read data from a PhysicsFS filehandle

The file must be opened for reading.

; (write handle buffer objSize objCount) : Write data to a PhysicsFS filehandle

The file must be opened for writing.

=== File Positioning

; (eof handle) : Check for end-of-file state on a PhysicsFS filehandle.

Determine if the end of file has been reached in a PhysicsFS filehandle.

; (tell handle) : Determine current position within a PhysicsFS filehandle.

; (seek handle pos) : Seek to a new position within a PhysicsFS filehandle.

The next read or write will occur at that place. Seeking past the beginning or end of the file is not allowed, and causes an error.

; (fileLength handle) : Get total length of a file in bytes.

Note that if the file size can't be determined (since the archive is "streamed" or whatnot) than this will report (-1). Also note that if another process/thread is writing to this file at the same time, then the information this function supplies could be incorrect before you get it. Use with caution, or better yet, don't use at all.

=== Buffering

; (setBuffer handle bufsize) : Set up buffering for a PhysicsFS file handle.

Define an i/o buffer for a file handle. A memory block of (bufsize) bytes will be allocated and associated with (handle).

For files opened for reading, up to (bufsize) bytes are read from (handle) and stored in the internal buffer. Calls to PHYSFS_read() will pull from this buffer until it is empty, and then refill it for more reading. Note that compressed files, like ZIP archives, will decompress while buffering, so this can be handy for offsetting CPU-intensive operations. The buffer isn't filled until you do your next read.

For files opened for writing, data will be buffered to memory until the buffer is full or the buffer is flushed. Closing a handle implicitly causes a flush...check your return values!

Seeking, etc transparently accounts for buffering.

You can resize an existing buffer by calling this function more than once on the same file. Setting the buffer size to zero will free an existing buffer.

PhysicsFS file handles are unbuffered by default.

Please check the return value of this function! Failures can include not being able to seek backwards in a read-only file when removing the buffer, not being able to allocate the buffer, and not being able to flush the buffer to disk, among other unexpected problems.

; (flush handle) : Flush a buffered PhysicsFS file handle.

For buffered files opened for writing, this will put the current contents of the buffer to disk and flag the buffer as empty if possible.

For buffered files opened for reading or unbuffered files, this is a safe no-op, and will report success.

=== Byte Ordering

; (swapSLE16 val) : Swap littleendian signed 16 to platform's native byte order.

Take a 16-bit signed value in littleendian format and convert it to the platform's native byte order.

; (swapULE16 val) : Swap littleendian unsigned 16 to platform's native byte order.

Take a 16-bit unsigned value in littleendian format and convert it to the platform's native byte order.

; (swapSLE32 val) : Swap littleendian signed 32 to platform's native byte order.

Take a 32-bit signed value in littleendian format and convert it to the platform's native byte order.

; (swapULE32 val) : Swap littleendian unsigned 32 to platform's native byte order.

Take a 32-bit unsigned value in littleendian format and convert it to the platform's native byte order.

; (swapSLE64 val) : Swap littleendian signed 64 to platform's native byte order.

Take a 64-bit signed value in littleendian format and convert it to the platform's native byte order.

; (swapULE64 val) : Swap littleendian unsigned 64 to platform's native byte order.

Take a 64-bit unsigned value in littleendian format and convert it to the platform's native byte order.

; (swapSBE16 val) : Swap bigendian signed 16 to platform's native byte order.

Take a 16-bit signed value in bigendian format and convert it to the platform's native byte order.

; (swapUBE16 val) : Swap bigendian unsigned 16 to platform's native byte order.

Take a 16-bit unsigned value in bigendian format and convert it to the platform's native byte order.

; (swapSBE32 val) : Swap bigendian signed 32 to platform's native byte order.

Take a 32-bit signed value in bigendian format and convert it to the platform's native byte order.

; (swapUBE32 val) : Swap bigendian unsigned 32 to platform's native byte order.

Take a 32-bit unsigned value in bigendian format and convert it to the platform's native byte order.

; (swapSBE64 val) : Swap bigendian signed 64 to platform's native byte order.

Take a 64-bit signed value in bigendian format and convert it to the platform's native byte order.

; (swapUBE64 val) : Swap bigendian unsigned 64 to platform's native byte order.

Take a 64-bit unsigned value in bigendian format and convert it to the platform's native byte order.

; (readSLE16 file) : Read and convert a signed 16-bit littleendian value.

Convenience function. Read a signed 16-bit littleendian value from a file and convert it to the platform's native byte order.

; (readULE16 file) : Read and convert an unsigned 16-bit littleendian value.

Convenience function. Read an unsigned 16-bit littleendian value from a file and convert it to the platform's native byte order.

; (readSBE16 file) : Read and convert a signed 16-bit bigendian value.

Convenience function. Read a signed 16-bit bigendian value from a file and convert it to the platform's native byte order.

; (readUBE16 file) : Read and convert an unsigned 16-bit bigendian value.

Convenience function. Read an unsigned 16-bit bigendian value from a file and convert it to the platform's native byte order.

; (readSLE32 file) : Read and convert a signed 32-bit littleendian value.

Convenience function. Read a signed 32-bit littleendian value from a file and convert it to the platform's native byte order.

; (readULE32 file) : Read and convert an unsigned 32-bit littleendian value.

Convenience function. Read an unsigned 32-bit littleendian value from a file and convert it to the platform's native byte order.

; (readSBE32 file) : Read and convert a signed 32-bit bigendian value.

Convenience function. Read a signed 32-bit bigendian value from a file and convert it to the platform's native byte order.

; (readUBE32 file) : Read and convert an unsigned 32-bit bigendian value.

Convenience function. Read an unsigned 32-bit bigendian value from a file and convert it to the platform's native byte order.

; (readSLE64 file) : Read and convert a signed 64-bit littleendian value.

Convenience function. Read a signed 64-bit littleendian value from a file and convert it to the platform's native byte order.

; (readULE64 file) : Read and convert an unsigned 64-bit littleendian value.

Convenience function. Read an unsigned 64-bit littleendian value from a file and convert it to the platform's native byte order.

; (readSBE64 file) : Read and convert a signed 64-bit bigendian value.

Convenience function. Read a signed 64-bit bigendian value from a file and convert it to the platform's native byte order.

; (readUBE64 file) : Read and convert an unsigned 64-bit bigendian value.

Convenience function. Read an unsigned 64-bit bigendian value from a file and convert it to the platform's native byte order.

; (writeSLE16 file val) : Convert and write a signed 16-bit littleendian value.

Convenience function. Convert a signed 16-bit value from the platform's native byte order to littleendian and write it to a file.

; (writeULE16 file val) : Convert and write an unsigned 16-bit littleendian value.

Convenience function. Convert an unsigned 16-bit value from the platform's native byte order to littleendian and write it to a file.

; (writeSBE16 file val) : Convert and write a signed 16-bit bigendian value.

Convenience function. Convert a signed 16-bit value from the platform's native byte order to bigendian and write it to a file.

; (writeUBE16 file val) : Convert and write an unsigned 16-bit bigendian value.

Convenience function. Convert an unsigned 16-bit value from the platform's native byte order to bigendian and write it to a file.

; (writeSLE32 file val) : Convert and write a signed 32-bit littleendian value.

Convenience function. Convert a signed 32-bit value from the platform's native byte order to littleendian and write it to a file.

; (writeULE32 file val) : Convert and write an unsigned 32-bit littleendian value.

Convenience function. Convert an unsigned 32-bit value from the platform's native byte order to littleendian and write it to a file.

; (writeSBE32 file val) : Convert and write a signed 32-bit bigendian value.

Convenience function. Convert a signed 32-bit value from the platform's native byte order to bigendian and write it to a file.

; (writeUBE32 file val) : Convert and write an unsigned 32-bit bigendian value.

Convenience function. Convert an unsigned 32-bit value from the platform's native byte order to bigendian and write it to a file.

; (writeSLE64 file val) : Convert and write a signed 64-bit littleendian value.

Convenience function. Convert a signed 64-bit value from the platform's native byte order to littleendian and write it to a file.

; (writeULE64 file val) : Convert and write an unsigned 64-bit littleendian value.

Convenience function. Convert an unsigned 64-bit value from the platform's native byte order to littleendian and write it to a file.

; (writeSBE64 file val) : Convert and write a signed 64-bit bigending value.

Convenience function. Convert a signed 64-bit value from the platform's native byte order to bigendian and write it to a file.

; (writeUBE64 file val) : Convert and write an unsigned 64-bit bigendian value.

Convenience function. Convert an unsigned 64-bit value from the platform's native byte order to bigendian and write it to a file.

== PhysicsFS 2.0 Functionality

; (isInit) : Determine if the PhysicsFS library is initialized.

Once (init) returns successfully, this will return non-zero. Before a successful (init) and after (deinit) returns successfully, this will return zero. This function is safe to call at any time.

; (symbolicLinksPermitted) : Determine if the symbolic links are permitted.

This reports the setting from the last call to (permitSymbolicLinks). If (permitSymbolicLinks) hasn't been called since the library was last initialized, symbolic links are implicitly disabled.

; (mount newDir mountPoint appendToPath) : Add an archive or directory to the search path.

If this is a duplicate, the entry is not added again, even though the function succeeds. You may not add the same archive to two different mountpoints: duplicate checking is done against the archive and not the mountpoint.

When you mount an archive, it is added to a virtual file system...all files in all of the archives are interpolated into a single hierachical file tree. Two archives mounted at the same place (or an archive with files overlapping another mountpoint) may have overlapping files: in such a case, the file earliest in the search path is selected, and the other files are inaccessible to the application. This allows archives to be used to override previous revisions; you can use the mounting mechanism to place archives at a specific point in the file tree and prevent overlap; this is useful for downloadable mods that might trample over application data or each other, for example.

The mountpoint does not need to exist prior to mounting, which is different than those familiar with the Unix concept of "mounting" may not expect. As well, more than one archive can be mounted to the same mountpoint, or mountpoints and archive contents can overlap...the interpolation mechanism still functions as usual.

; (getMountPoint dir) : Determine a mounted archive's mountpoint.

You give this function the name of an archive or dir you successfully added to the search path, and it reports the location in the interpolated tree where it is mounted. Files mounted with a NULL mountpoint or through (addToSearchPath) will report "/". The return value is READ ONLY and valid until the archive is removed from the search path.

=== UTF8 Functions

; (utf8FromUcs4 src len) : Convert a UCS-4 string to a UTF-8 string.

UCS-4 strings are 32-bits per character: \c wchar_t on Unix.

; (utf8ToUcs4 src len) : Convert a UTF-8 string to a UCS-4 string.

UCS-4 strings are 32-bits per character: \c wchar_t on Unix.

; (utf8FromUcs2 src len) : Convert a UCS-2 string to a UTF-8 string.

UCS-2 strings are 16-bits per character: \c TCHAR on Windows, when building with Unicode support.

Please note that UCS-2 is not UTF-16; we do not support the "surrogate" values at this time.

; (utf8ToUcs2 src len) : Convert a UTF-8 string to a UCS-2 string.

UCS-2 strings are 16-bits per character: \c TCHAR on Windows, when building with Unicode support.

Please note that UCS-2 is not UTF-16; we do not support the "surrogate" values at this time.

; (utf8FromLatin1 src len) : Convert a UTF-8 string to a Latin1 string.

Latin1 strings are 8-bits per character: a popular "high ASCII" encoding.

Please note that we do not supply a UTF-8 to Latin1 converter, since Latin1 can't express most Unicode codepoints. It's a legacy encoding; you should be converting away from it at all times.

== Author

Dan Leslie (dan@ironoxide.ca)

== Version history

; 1.0 : First release, interfaces conform to The Scheme Way
; 0.1 : Alpha release, version with tests coming soon

== License

Copyright 2011 Daniel J. Leslie. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY DANIEL J. LESLIE ''AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DANIEL J. LESLIE OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of Daniel J. Leslie.
