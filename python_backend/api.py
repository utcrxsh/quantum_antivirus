from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from scanner import MalwareScanner
import uvicorn
from typing import Dict, List
from pydantic import BaseModel

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize scanner
scanner = MalwareScanner()

class ScanRequest(BaseModel):
    path: str = ""  # Optional for process and log scans

@app.post("/scan/processes")
async def scan_processes() -> Dict:
    try:
        results = scanner.scan_processes()
        return {"status": "success", "threats": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/scan/logs")
async def scan_logs() -> Dict:
    try:
        results = scanner.scan_logs()
        return {"status": "success", "threats": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/scan/files")
async def scan_files(request: ScanRequest) -> Dict:
    try:
        if not request.path:
            raise HTTPException(status_code=400, detail="Path is required")
        results = scanner.scan_files(request.path)
        return {"status": "success", "threats": results}
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000) 