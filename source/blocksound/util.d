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
module blocksound.util;

/// Vector 3 struct with floats.
struct Vec3 {
    /// X coordinate
    float x;
    /// Y coordinate
    float y;
    /// Z coordinate
    float z;
}

/++
    Helper class which emulates an ArrayList due to
    dynamic arrays not having a remove function for
    elements.

    Uses an associative array to emulate.
+/
synchronized class ArrayList(T) {
    private shared size_t counter = 0;
    private shared T[size_t] list;

    /// Representation of the ArrayList as an Array. Returns a copy.
    @property T[] array() @trusted {
        return cast(T[]) list.values();
    }

    /++
        Adds the element to the array at the next
        position.

        Params:
                element =   The element to be added.
    +/
    void add(T element) @trusted {
        import core.atomic;
        atomicOp!"+="(counter, 1);

        list[counter] = cast(shared) element;
    }

    /++
        Removes the element from the array.
        
        Params:
                element =   The element to be removed.
    +/
    void remove(T element) @trusted {
        size_t posToRemove;
        foreach(key, val; list) {
            if((cast(T) val) == element) {
                posToRemove = key;
                break;
            }
        }
        list.remove(posToRemove);
    }
}

/++
    Converts a D string (immutable(char[])) to a C string
    (char*).

    Params:
            dString =   The D string to be converted.

    Returns: A C string (char array).
+/
char* toCString(in string dString) @trusted {
    import std.string : toStringz;
    return cast(char*) toStringz(dString);
}

/++
    Converts a C string (char array) to a D string
    (immutable(char[]))

    Params:
            cString =   The C string to be converted.

    Returns: A D string (immutable(char[]))
+/
string toDString(char* cString) @trusted {
    import std.string : fromStringz;
    return cast(string) fromStringz(cString);
}