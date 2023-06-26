import sys
import zipfile
import glob
import os
import struct


ignore_extentions = [
    ".dbs",
    ".bak",
    ".backup1",
    ".backup2",
    ".backup3",
    ".aseprite",
]


wad_header_s = struct.Struct("<4sII")
wad_file_header_s = struct.Struct("<II8s")


def read_wad(fp):
    out = {}
    with open(fp, "rb") as f:
        _, filecount, tocloc = wad_header_s.unpack(f.read(wad_header_s.size))
        f.seek(tocloc)
        for _ in range(filecount):
            loc, size, name = wad_file_header_s.unpack(
                f.read(wad_file_header_s.size))
            retloc = f.tell()
            f.seek(loc)
            out[str(name, "ascii")] = f.read(size)
            f.seek(retloc)
    return out


def get_zip_path(file_path: str) -> str:
    return file_path


with zipfile.ZipFile(sys.argv[2], "w", allowZip64=False, compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
    os.chdir(sys.argv[1])
    files = glob.glob("**/*", recursive=True)
    for folder in os.walk("."):
        folder_name = folder[0].removeprefix("." + os.path.sep)
        if folder_name != ".":
            zf.writestr(folder_name + "/", "")

        # Check if this is a skin
        skins = glob.glob(os.path.join(folder_name, "S_SKIN*"))
        s_count = len(skins)
        is_skin_folder = False
        if s_count == 1:
            # This is a skin
            is_skin_folder = True
            zf.write(skins[0])
        elif s_count > 1:
            # Please do not add more than one skin to a folder
            exit(
                "ERROR: More than one S_SKIN in folder. Put all seporate skins in seporate folders")

        for file in folder[2]:
            full_filepath = os.path.join(folder_name, file)
            # zf.write(os.path.join(folder[0], file))

            ext = os.path.splitext(file)[1].lower()
            if ext in ignore_extentions\
                    or file.startswith("S_SKIN"):
                continue
            elif ext == ".wad":
                # extract wad and dump it in
                folder = os.path.splitext(file)[0]
                zf.writestr(folder_name + "/" + folder + "/", "")
                lumps: dict[str, bytes] = read_wad(full_filepath)
                for lump, data in lumps.items():
                    zf.writestr(folder_name + "/" + folder + "/" + lump, data)
            else:
                zf.write(full_filepath)
