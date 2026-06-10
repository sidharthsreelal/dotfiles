import ctypes
import os
import struct
import sys

# Load libc
try:
    libc = ctypes.CDLL(None)
except Exception as e:
    try:
        libc = ctypes.CDLL('libc.so.6')
    except Exception as e2:
        print(f"Could not load libc: {e}, {e2}")
        sys.exit(1)

# Define inotify structures and constants
IN_CLOSE_WRITE = 0x00000008
IN_MOVED_TO = 0x00000080
IN_CREATE = 0x00000100

EVENT_FMT = 'iIII'
EVENT_SIZE = struct.calcsize(EVENT_FMT)

def watch_dir(path):
    fd = libc.inotify_init()
    if fd < 0:
        print("Failed to initialize inotify")
        return

    # Watch for CLOSE_WRITE and MOVED_TO (since file writes might write and close, or write temp file and rename)
    mask = IN_CLOSE_WRITE | IN_MOVED_TO | IN_CREATE
    wd = libc.inotify_add_watch(fd, path.encode('utf-8'), mask)
    if wd < 0:
        print(f"Failed to add watch for {path}")
        return

    print(f"Watching {path} for changes...")
    try:
        while True:
            # Read events from inotify fd
            data = os.read(fd, 4096)
            if not data:
                break
            
            i = 0
            while i < len(data):
                wd_ev, mask_ev, cookie, length = struct.unpack_from(EVENT_FMT, data, i)
                name_bytes = data[i + EVENT_SIZE : i + EVENT_SIZE + length]
                name = name_bytes.split(b'\x00')[0].decode('utf-8')
                i += EVENT_SIZE + length

                if name:
                    full_path = os.path.join(path, name)
                    print(f"Event detected on {name} (mask: {mask_ev})")
                    # Try to fsync the file
                    try:
                        if os.path.isfile(full_path):
                            fd_file = os.open(full_path, os.O_RDONLY)
                            try:
                                os.fsync(fd_file)
                                print(f"Successfully fsynced file: {full_path}")
                            finally:
   
<truncated 869 bytes