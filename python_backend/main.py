from fastapi import FastAPI, UploadFile, File, Form, Query
from fastapi.middleware.cors import CORSMiddleware
from scanner import MalwareScanner
import tempfile
import shutil
import os
import threading
import time

app = FastAPI()

# Allow CORS for local Flutter dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

scanner = MalwareScanner()

@app.get("/scan_processes")
def scan_processes(mode: str = Query('classic')):
    try:
        threats = scanner.scan_processes(mode=mode)
        return {"status": "success", "threats": threats}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/scan_files")
def scan_files(path: str, mode: str = Query('classic')):
    try:
        threats = scanner.scan_files(path, mode=mode)
        return {"status": "success", "threats": threats}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/scan_logs")
def scan_logs(mode: str = Query('classic')):
    try:
        threats = scanner.scan_logs(mode=mode)
        return {"status": "success", "threats": threats}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.post("/scan_file")
async def scan_file(
    file: UploadFile = File(...),
    original_path: str = Form(None),
    mode: str = Query('classic')
):
    # Save uploaded file to a temp location
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        shutil.copyfileobj(file.file, tmp)
        tmp_path = tmp.name
    try:
        # Scan the uploaded file directly
        threats = scanner.scan_files(tmp_path, mode=mode)
        # If original_path is provided, update the metadata
        if original_path:
            for t in threats:
                t['original_path'] = original_path
        return {"status": "success", "threats": threats}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        os.remove(tmp_path) 