#!/usr/bin/env python3
# generate header file for C++, using DRAWF information from .debug files

import os
import sys
import re
import pickle

DEFAULT_FILENAME = "./UnrealGame-Linux-Shipping.debug"
DEFAULT_SEARCH_DIR = "../deps/first/Unreal/generated_include"
DEFAULT_GENERATED_DIR = "../generated"

FUNCTION_TEMPLATE = """if (auto it = {ClassName}::VTableLayoutMap.find(STR("{FunctionName}")); it == {ClassName}::VTableLayoutMap.end())
{{
    {ClassName}::VTableLayoutMap.emplace(STR("{FunctionName}"), 0x{FunctionOffset:02x});
}}
"""

MEMBER_TEMPLATE = """if (auto it = {ClassName}::MemberOffsets.find(STR("{MemberName}")); it == {ClassName}::MemberOffsets.end())
{{
    UWorld::MemberOffsets.emplace(STR("{MemberName}"), 0x{MemberOffset:02x});
}}
"""

Version = "5_01"

class CMember:
    def __init__(self, name, offset):
        self.name = name
        self.offset = offset

    def GenerateMember(self, className, count = None):
        if count and count != 0:
            return MEMBER_TEMPLATE.format(ClassName = className, MemberName =  f"{self.name}_{count}", MemberOffset = self.offset)
        else:
            return MEMBER_TEMPLATE.format(ClassName = className, MemberName = self.name, MemberOffset = self.offset)
    
class CVFunc:
    def __init__(self, mangledname, name, slotoffset):
        self.mangledname = mangledname
        self.name = name
        self.slotoffset = slotoffset

    def GenerateVFunc(self, className, count = None):
        if count and count != 0:
            return FUNCTION_TEMPLATE.format(ClassName = className, FunctionName = f"{self.name}_{count}", FunctionOffset = self.slotoffset)
        else:
            return FUNCTION_TEMPLATE.format(ClassName = className, FunctionName = self.name, FunctionOffset = self.slotoffset)

class CClass:
    def __init__(self, name):
        self.name = name
        self.members = {}
        self.vfuncs = {}

    def AddMember(self, member, offset):
        if member not in self.members:
            self.members[member] = CMember(member, offset)
    
    def AddVFunc(self, mangledname, vfunc, offset):
        if mangledname not in self.vfuncs:
            self.vfuncs[mangledname] = CVFunc(mangledname, vfunc, offset)

    def GenerateMember(self):
        vals = list(self.members.values())
        vals.sort(key = lambda x: x.offset)
        return "\n".join([member.GenerateMember(self.name) for member in vals])

    def GenerateVTable(self):
        generatedName = {}
        results = []
        vals = list(self.vfuncs.values())
        vals.sort(key = lambda x: x.slotoffset)
        for vfunc in vals:
            if vfunc.name in generatedName:
                generatedName[vfunc.name] += 1
            else:
                generatedName[vfunc.name] = 0
            results.append(vfunc.GenerateVFunc(self.name, generatedName[vfunc.name]))
        return "\n".join(results)

class Database:
    def __init__(self):
        self.classes = {}

    def GetClass(self, name):
        if name not in self.classes:
            self.classes[name] = CClass(name)
        return self.classes[name]

    def GenerateMember(self):
        return { name: cls.GenerateMember() for name, cls in self.classes.items() }
        
    def GenerateVTable(self):
        return { name: cls.GenerateVTable() for name, cls in self.classes.items() }

def GetClassNames(search_dir = DEFAULT_SEARCH_DIR):
    # glob all file with pattern "MemberVariableLayout_HeaderWrapper_{ClassName}.hpp"
    # return list of class names
    """
    import glob
    tabA = [re.search(rf"{Version}_VTableOffsets_(.*)_FunctionBody\.cpp", file).group(1) for file in glob.glob(f"{search_dir}/FunctionBodies/{Version}_VTableOffsets_*.cpp")]
    tabB = [re.search(rf"{Version}_MemberVariableLayout_DefaultSetter_(.*)\.cpp", file).group(1) for file in glob.glob(f"{search_dir}/FunctionBodies/{Version}_MemberVariableLayout_DefaultSetter_*.cpp")]
    return list(dict.fromkeys(tabA + tabB))
    """

    return  ['FArchiveState', 'UDataTable', 'FConsoleManager', 'UPlayer', 'UObjectBaseUtility', 'AGameMode', 'FMalloc', 'UField', 'UGameViewportClient', 'FField', 'FNumericProperty', 'IConsoleVariable', 'AGameModeBase', 'FMulticastDelegateProperty', 'UObject', 'AActor', 'IConsoleManager', 'IConsoleObject', 'FArchive', 'FConsoleVariableBase', 'FOutputDevice', 'ITextData', 'FProperty', 'FObjectPropertyBase', 'ULocalPlayer', 'UScriptStruct__ICppStructOps', 'UObjectBase', 'FConsoleCommandBase', 'UConsole', 'UStruct', 'IConsoleCommand', 'FInterfaceProperty', 'FByteProperty', 'FSoftClassProperty', 'FStructProperty', 'UEnum', 'FBoolProperty', 'UWorld', 'UClass', 'FEnumProperty', 'FClassProperty', 'FFieldPathProperty', 'FArrayProperty', 'FMapProperty', 'FSetProperty', 'UScriptStruct', 'FDelegateProperty', 'UFunction']

from elftools.dwarf.die import DIE
from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

def ScanCU(database, classes, cu):
    for ch in cu.get_top_DIE().iter_children():
        if ch.tag == 'DW_TAG_class_type':
            if ch.attributes.get('DW_AT_name'):
                name = ch.attributes['DW_AT_name'].value.decode('utf-8')
                if name in classes:
                    print(name)
                    klass = database.GetClass(name)
                    for m in ch.iter_children():
                        name_m = m.attributes.get('DW_AT_name')
                        if not name_m:
                            continue
                        name_m = name_m.value.decode('utf-8')
                        if m.tag == 'DW_TAG_member': 
                            if m.attributes.get('DW_AT_data_member_location'):
                                print(f"  member: {name_m} @ {m.attributes['DW_AT_data_member_location'].value}")
                                klass.AddMember(name_m, m.attributes['DW_AT_data_member_location'].value)
                        if m.tag == "DW_TAG_subprogram":
                            # check if DW_AT_vtable_elem_location exists
                            if m.attributes.get('DW_AT_vtable_elem_location'):
                                # is a virtual function
                                link_name = m.attributes.get('DW_AT_linkage_name')
                                if link_name:
                                    link_name = link_name.value.decode('utf-8')
                                else:
                                    link_name = name_m
                                
                                print(f"  vfunc: {name_m} aka {link_name} @ {m.attributes['DW_AT_vtable_elem_location'].value[1] * 8}")
                                klass.AddVFunc(link_name, name_m, m.attributes['DW_AT_vtable_elem_location'].value[1] * 8)
                    print()

def ProcessFile(filename = DEFAULT_FILENAME, outfile= "database.pkl", target_class = GetClassNames()):
    with open(filename, 'rb') as f:
        elffile = ELFFile(f)
        dwarfinfo = elffile.get_dwarf_info()
    
    # if database_.pkl exists, load it and resume from last progress
    started = True
    if os.path.exists(outfile):
        with open(outfile, "rb") as f:
            database = pickle.load(f)
            progress = pickle.load(f)
            started = False
    else:
        database = Database()

    for cu in dwarfinfo.iter_CUs():
        if cu.get_top_DIE().attributes.get('DW_AT_name').value.decode('utf-8') == progress:
            started = True
            continue
        if not started:
            continue

        ScanCU(database, target_class, cu)
        # pickle dump
        with open(outfile, "wb") as f:
            pickle.dump(database, f)
            pickle.dump(cu.get_top_DIE().attributes['DW_AT_name'].value.decode('utf-8'), f) # dump progress
        print(f"{cu.get_top_DIE().attributes['DW_AT_name'].value.decode('utf-8')} done...")
    
    print("CU scan done")

    return database

def GenerateHeaderFile(target_dir = DEFAULT_GENERATED_DIR, database = "database.pkl"):
    print("Generating header files...")
    if isinstance(database, str):
        with open(database, "rb") as f:
            import pickle
            database = pickle.load(f)
    # generate header files
    VFunc = "Linux_5_01_VTableOffsets_{ClassName}_FunctionBody.cpp"
    Member = "Linux_5_01_MemberVariableLayout_DefaultSetter_{ClassName}.cpp"
    for c in database.classes.values():
        print(f"Generating {c.name}...")
        with open(target_dir + VFunc.format(ClassName=c.name), "w") as f:
            f.write(c.GenerateVTable())
        with open(target_dir + Member.format(ClassName=c.name), "w") as f:
            f.write(c.GenerateMember())
            

def resolve_path(path):
    return os.path.abspath(os.path.expanduser(path))

if __name__ == "__main__":
    # -help/--help for usage
    # -s in scan mode, args are [scan debug file] -o for output file -c for target class, can have a -g for generate header file
    # -g for generate header mode, args are [database.pkl] -t for target directory
    import argparse
    parser = argparse.ArgumentParser(description="Generate header file for C++, using DRAWF information from .debug files")
    parser.add_argument("-s", "--scan", help="Scan mode", action="store_true")
    parser.add_argument("-g", "--generate", help="Generate header file", action="store_true")
    parser.add_argument("-i", "--info", help="Print infos", action="store_true")
    parser.add_argument("-v", "--version", help="Set version", nargs="?", default=Version)

    parser.add_argument("-o", "--output", help="Output file", nargs="?", default="database.pkl")
    parser.add_argument("-c", "--class", help="Target class", nargs="+", metavar="class_", default=GetClassNames())
    parser.add_argument("-t", "--target", help="Target directory", nargs="?", default=DEFAULT_GENERATED_DIR)
    parser.add_argument("filename", help="Filename", nargs="?", default=DEFAULT_FILENAME)
    args = parser.parse_args()

    if args.version:
        # valid version = "\d_\d\d"
        if not re.match(r"\d_\d\d", args.version):
            print("Invalid version")
            sys.exit(1)
        Version = args.version

    if args.info:
        print("  Class names: ", GetClassNames())
        print("  Default search dir: ", resolve_path(DEFAULT_SEARCH_DIR))
        print("  Default generated dir: ", resolve_path(DEFAULT_GENERATED_DIR))
        sys.exit(0)

    if args.scan:
        if not args.output:
            print("Output file not specified")
            sys.exit(1)
        if not args.class_:
            print("Target class not specified")
            sys.exit(1)
        if args.generate:
            if not args.target:
                print("Target directory not specified")
        database = ProcessFile(args.filename, args.output, args.class_)
        if args.generate:
            GenerateHeaderFile(args.target, database)
    else:
        if args.generate:
            if not args.target:
                print("Target directory not specified")
            fn = args.filename
            if fn == DEFAULT_FILENAME:
                fn = "database.pkl"
            GenerateHeaderFile(args.target, args.filename)
