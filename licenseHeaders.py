"""
    zlib License

    (C) 2016 jython234

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.
    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.

"""
#----------------------------------------------------------
# License Header script to update headers in source code.
#----------------------------------------------------------

import os

licenseFile = open("LICENSE.txt", 'r')
licenseLines = licenseFile.readlines()
licenseFile.close()

def formatFile(filename: str):
    f = open(filename, 'r')
    lines = f.readlines()
    f.close()
    if lines[0].startswith("/*"):
        print("file " + filename + " already has header.")
        return

    f = open(filename, 'w')

    f.write("/*\n")
    for line in licenseLines:
        f.write(" *  " + line)
    f.write("*/\n")

    for line2 in lines:
        f.write(line2)
    
    f.close()

def formatDirectory(directory: str):
    files = os.listdir(directory)

    oldDir = os.getcwd()
    os.chdir(directory)

    for f in files:
        if os.path.isdir(f):
            formatDirectory(f)
        elif ".d" in f:
            print("formatting file: " + f)
            formatFile(f)

formatDirectory("source")