#!/usr/bin/env python3
import ctypes
import os
import struct
import sys
import time
import logging
import errno

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

# Load libc
try:
    libc = ctypes.CDLL(None)
except Exception as e:
    try:
        libc = ctypes.CDLL('libc.so.6')
    except Exception as e2:
        logging.error(f"Could not load libc: {e}, {e2}")
        sys.exit(1)

# Set ctypes function prototypes
try:
    libc.inotify_init.argtypes = []
    libc.inotify_init.restype = ctypes.c_int

    libc.inotify_add_watch.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_uint32]
    libc.inotify_add_watch.restype = ctypes.c_int

    libc.inotify_rm_watch.argtypes = [ctypes.c_int, ctypes.c_int]
    libc.inotify_rm_watch.restype = ctypes.c_int
except AttributeError as ae:
    logging.error(f"Failed to set libc inotify signatures: {ae}")

# Define inotify structures and constants
IN_CLOSE_WRITE = 0x00000008
IN_MOVED_TO = 0x00000080
IN_CREATE = 0x00000100
IN_ISDIR = 0x40000000

EVENT_FMT = 'iIII'
EVENT_SIZE = struct.calcsize(EVENT_FMT)

def fsync_path(path):
    """
    Perform an explicit fsync on the given path (file or directory).
    """
    if not os.path.exists(path):
        return
    try:
        # Open in read-only mode to get a file descriptor.
        # This is safe and does not modify the file.
        fd = os.open(path, os.O_RDONLY)
        try:
            os.fsync(fd)
            logging.info(f"Fsynced: {path}")
        finally:
            os.close(fd)
    except Exception as e:
        # Avoid spamming errors if files are temporary or removed quickly
        logging.debug(f"Failed to fsync {path}: {e}")

def handle_event(parent_dir, name):
    """
    Fsync the changed file and its parent directory.
    """
    full_path = os.path.join(parent_dir, name)
    logging.info(f"Change detected: {full_path}")
    
    # First, fsync the file itself
    if os.path.isfile(full_path):
        fsync_path(full_path)
    
    # Second, fsync the parent directory to commit the directory entry changes
    fsync_path(parent_dir)

def add_watch(fd, path, watch_map):
    """
    Add a watch descriptor for a path.
    """
    # Check if we are already watching this path
    for w_id, w_path in watch_map.items():
        if w_path == path:
            return w_id

    mask = IN_CLOSE_WRITE | IN_MOVED_TO | IN_CREATE
    wd = libc.inotify_add_watch(fd, path.encode('utf-8'), mask)
    if wd < 0:
        logging.error(f"Failed to watch directory: {path}")
        return -1
    
    watch_map[wd] = path
    logging.info(f"Added watch for directory: {path} (wd={wd})")
    return wd

def add_watch_recursive(fd, base_path, watch_map):
    """
    Recursively walk base_path and add watches for all directories.
    """
    if not os.path.exists(base_path):
        logging.warning(f"Base path does not exist: {base_path}")
        return
    
    for root, dirs, files in os.walk(base_path):
        add_watch(fd, root, watch_map)

def main():
    fd = libc.inotify_init()
    if fd < 0:
        logging.error("Failed to initialize inotify")
        sys.exit(1)

    watch_map = {}
    home = os.path.expanduser("~")
    base_paths = [
        os.path.join(home, ".gemini/antigravity-ide/conversations"),
        os.path.join(home, ".config/Antigravity IDE/User/globalStorage"),
        os.path.join(home, ".gemini/antigravity-ide/brain")
    ]

    logging.info("Initializing watches...")
    for path in base_paths:
        try:
            os.makedirs(path, exist_ok=True)
            add_watch_recursive(fd, path, watch_map)
        except Exception as e:
            logging.error(f"Error initializing watches for {path}: {e}")

    logging.info("Sync daemon is active and running.")

    try:
        while True:
            try:
                data = os.read(fd, 4096)
            except OSError as e:
                if e.errno == errno.EINTR:
                    continue
                raise

            if not data:
                break

            i = 0
            while i < len(data):
                wd, mask_ev, cookie, length = struct.unpack_from(EVENT_FMT, data, i)
                name_bytes = data[i + EVENT_SIZE : i + EVENT_SIZE + length]
                name = name_bytes.split(b'\x00')[0].decode('utf-8', errors='replace')
                i += EVENT_SIZE + length

                if wd not in watch_map:
                    continue

                parent_dir = watch_map[wd]

                # Dynamic recursion: if a new directory is created, watch it.
                if (mask_ev & IN_CREATE) and (mask_ev & IN_ISDIR) and name:
                    new_dir = os.path.join(parent_dir, name)
                    logging.info(f"New directory detected: {new_dir}")
                    add_watch(fd, new_dir, watch_map)
                    # fsync the parent directory to commit the subdirectory entry
                    fsync_path(parent_dir)
                    continue

                if name:
                    if (mask_ev & IN_CLOSE_WRITE) or (mask_ev & IN_MOVED_TO):
                        handle_event(parent_dir, name)

    except KeyboardInterrupt:
        logging.info("Shutting down sync daemon...")
    except Exception as e:
        logging.error(f"Sync daemon encountered a fatal error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
