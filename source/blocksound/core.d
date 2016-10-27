/*
 *  zlib License
 *  
 *  (C) 2016 jython234
 *  
 *  This software is provided 'as-is', without any express or implied
 *  warranty.  In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *  
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *  
 *  1. The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  2. Altered source versions must be plainly marked as such, and must not be
 *     misrepresented as being the original software.
 *  3. This notice may not be removed or altered from any source distribution.
*/
module blocksound.core;

import derelict.openal.al;
import derelict.sndfile.sndfile;

import blocksound.util;
import blocksound.backend.core;

/// Library Version
immutable string VERSION = "v2.0.0-alpha1";

private shared bool INIT = false;
private shared Backend backend;

/// Returns true if the library has initialized.
bool blocksound_hasInitialized() @safe nothrow {
    return INIT;
}

/// Returns the Backend that is being used by the library.
Backend blocksound_getBackend() @trusted nothrow {
    return cast(Backend) backend;
}

/++
    Init the library. This must be called before any other library
    features are used.
+/
void blocksound_Init(BlockSoundLogger logger) @trusted {
    if(INIT) return;

    logger.logInfo("BlockSound " ~ VERSION ~" compiled with " ~ __VENDOR__ ~ " on " ~ __TIMESTAMP__);

    debug(blocksound_debug) {
        logger.logDebug("Loading libraries...");
    }

    version(blocksound_ALBackend) {
        import blocksound.backend.openal : ALBackend;
        
        ALBackend bk = new ALBackend(logger);
        backend = cast(shared) bk;
        
        bk.doInit();
    } else {
        logger.logWarn("No backend has been compiled! Try compiling blocksound with the \"openal-backend\" configuration!");
    }

    INIT = true;

    debug(blocksound_debug) {
        logger.logDebug("Libraries loaded.\n");
    }
}
