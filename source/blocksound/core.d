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

public import blocksound.util;

/// Library Version
immutable string VERSION = "v2.0.0-alpha1";

package shared bool INIT = false;

/++
    Init the library. This must be called before any other library
    features are used.
+/
void blocksound_Init() @trusted {
    debug(blocksound_verbose) {
        import std.stdio : writeln;
        import blocksound.backend.types : BACKEND;

        writeln("\n[BlockSound]: BlockSound ", VERSION, " compiled with ", BACKEND, " backend.");
        writeln("[BlockSound]: Loading libraries...");
    }

    version(blocksound_ALBackend) {
        import blocksound.backend.openal : loadLibraries;
        loadLibraries(); //TODO: skipALload, skipSFload
    } else {
        writeln("[BlockSound]: WARNING: No backend detected! Try compiling blocksound with the \"openal-backend\" configuration!");
    }

    INIT = true;

    debug(blocksound_verbose) {
        import std.stdio : writeln;
        writeln("[BlockSound]: Libraries loaded.\n");
    }
}
