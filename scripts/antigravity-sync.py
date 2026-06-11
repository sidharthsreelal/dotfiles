#!/usr/bin/env python3
import os
import json
import sqlite3
import re
import datetime
import glob

BRAIN_DIR = "/home/sidsrlal/.gemini/antigravity-ide/brain"
CONVS_DIR = "/home/sidsrlal/.gemini/antigravity-ide/conversations"
GLOBAL_DB = "/home/sidsrlal/.config/Antigravity IDE/User/globalStorage/state.vscdb"

INDEX_KEY = "chat.ChatSessionStore.index"
SUMMARIES_KEY = "antigravityUnifiedStateSync.trajectorySummaries"

def extract_title(content):
    if not content:
        return ""
    # Try to extract between <USER_REQUEST> and </USER_REQUEST>
    match = re.search(r"<USER_REQUEST>(.*?)</USER_REQUEST>", content, re.DOTALL)
    if match:
        text = match.group(1).strip()
    else:
        text = content.strip()
    
    # Strip any additional XML-like tags
    text = re.sub(r"<[^>]+>", "", text)
    
    # Replace multiple whitespaces/newlines with a single space
    text = " ".join(text.split())
    
    # Truncate to a reasonable length
    if len(text) > 100:
        text = text[:97] + "..."
    return text

def reconstruct_index():
    entries = {}
    
    if not os.path.isdir(CONVS_DIR):
        print(f"Conversations directory {CONVS_DIR} not found. Skipping reconstruction.")
        return None
        
    pb_files = [f for f in os.listdir(CONVS_DIR) if f.endswith(".pb")]
    print(f"Found {len(pb_files)} .pb files. Reconstructing index...")
    
    for filename in pb_files:
        conv_id = filename[:-3] # remove .pb
        pb_path = os.path.join(CONVS_DIR, filename)
        
        # Default times based on file timestamps
        mtime = os.path.getmtime(pb_path)
        created_ms = int(mtime * 1000)
        modified_ms = int(mtime * 1000)
        title = "Antigravity Conversation"
        
        # Try to parse the brain log file
        log_path = os.path.join(BRAIN_DIR, conv_id, ".system_generated", "logs", "transcript.jsonl")
        if os.path.exists(log_path):
            try:
                with open(log_path, "r", errors="replace") as f:
                    for line in f:
                        step = json.loads(line)
                        if step.get("type") == "USER_INPUT" and step.get("source") == "USER_EXPLICIT":
                            raw_content = step.get("content", "")
                            title = extract_title(raw_content)
                            
                            ts = step.get("created_at")
                            if ts:
                                try:
                                    dt = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
                                    created_ms = int(dt.timestamp() * 1000)
                                except Exception:
                                    pass
                            break
            except Exception as e:
                pass
                
        # Always set modified_ms to the actual .pb file mtime
        modified_ms = int(os.path.getmtime(pb_path) * 1000)
        
        entries[conv_id] = {
            "id": conv_id,
            "title": title,
            "lastModified": modified_ms,
            "createdAt": created_ms
        }
        
    return {
        "version": 1,
        "entries": entries
    }

def main():
    print("=== Antigravity Pre-Launch Sync ===")
    
    # 1. Reconstruct index
    index_data = reconstruct_index()
    if not index_data:
        return
        
    index_json = json.dumps(index_data)
    
    # 2. Extract trajectorySummaries from global database if available
    summaries_val = None
    if os.path.exists(GLOBAL_DB):
        try:
            conn = sqlite3.connect(GLOBAL_DB)
            cur = conn.cursor()
            cur.execute("SELECT value FROM ItemTable WHERE key=?", (SUMMARIES_KEY,))
            row = cur.fetchone()
            if row:
                summaries_val = row[0]
            conn.close()
        except Exception as e:
            print(f"Error reading global trajectorySummaries: {e}")
            
    # 3. Gather all state.vscdb files (global and workspace-specific)
    dbs = glob.glob("/home/sidsrlal/.config/Antigravity IDE/User/workspaceStorage/*/state.vscdb") + [GLOBAL_DB]
    
    # 4. Inject reconstructed index and trajectorySummaries into all databases
    for db in dbs:
        if not os.path.exists(db):
            continue
        try:
            conn = sqlite3.connect(db)
            cur = conn.cursor()
            
            # Inject chat index
            cur.execute("INSERT OR REPLACE INTO ItemTable (key, value) VALUES (?, ?)", (INDEX_KEY, index_json))
            
            # Inject trajectory summaries if we extracted them
            if summaries_val:
                cur.execute("INSERT OR REPLACE INTO ItemTable (key, value) VALUES (?, ?)", (SUMMARIES_KEY, summaries_val))
                
            conn.commit()
            conn.close()
            print(f"Successfully synced: {os.path.basename(os.path.dirname(db))}")
        except Exception as e:
            print(f"Failed to sync {db}: {e}")
            
    print("=== Sync Completed ===")

if __name__ == "__main__":
    main()
