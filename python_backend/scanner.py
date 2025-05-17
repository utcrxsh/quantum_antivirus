import os
import psutil
import joblib
import win32evtlog
import numpy as np
from datetime import datetime
import PyPDF2
import docx
import hashlib

def load_hashes():
    hash_path = os.path.join(os.path.dirname(__file__), 'malware_hashes.txt')
    if not os.path.exists(hash_path):
        return set()
    with open(hash_path, 'r') as f:
        return set(line.strip() for line in f if len(line.strip()) == 64)

MALWARE_HASHES = load_hashes()

def compute_sha256(filepath):
    h = hashlib.sha256()
    try:
        with open(filepath, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return None

class MalwareScanner:
    def __init__(self, threshold=0.9):
        """
        Initialize the MalwareScanner with only the classic model and scaler.
        Args:
            threshold (float): Threshold for classifying threats (default: 0.9)
        """
        self.threshold = threshold
        classic_model_path = os.path.join(os.path.dirname(__file__), 'model', 'malware_detector.pkl')
        classic_scaler_path = os.path.join(os.path.dirname(__file__), 'model', 'scaler.pkl')
        try:
            if not os.path.exists(classic_model_path):
                raise FileNotFoundError(f"Classic model file not found at {classic_model_path}")
            if not os.path.exists(classic_scaler_path):
                raise FileNotFoundError(f"Classic scaler file not found at {classic_scaler_path}")
            self.classic_model = joblib.load(classic_model_path)
            self.classic_scaler = joblib.load(classic_scaler_path)
        except Exception as e:
            print(f"Error loading models or scalers: {str(e)}")
            raise
        print("Classic model and scaler loaded successfully")

    def get_model_scaler(self, mode: str):
        # Always use classic model/scaler regardless of mode
        return self.classic_model, self.classic_scaler

    def scan_processes(self, mode: str = 'classic'):
        """Scan running processes for potential threats."""
        try:
            data_with_meta = self.collect_process_data()
            if data_with_meta:
                features = [item[0] for item in data_with_meta]
                metadata = [item[1] for item in data_with_meta]
                return self.predict_threats(np.array(features), 'process', metadata, mode)
            return []
        except Exception as e:
            msg = str(e)
            if 'refused the network connection' in msg or 'AccessDenied' in msg:
                print("Error scanning processes: Permission denied or remote connection refused. Try running as Administrator and ensure you are scanning the local machine.")
            else:
                print(f"Error scanning processes: {e}")
            return []

    def scan_logs(self, mode: str = 'classic'):
        print("[DEBUG] scan_logs called")
        """Scan system logs for suspicious activity."""
        try:
            data_with_meta = self.collect_log_data()
            print(f"[DEBUG] scan_logs: data_with_meta length = {len(data_with_meta)}")
            if data_with_meta:
                features = [item[0] for item in data_with_meta]
                metadata = [item[1] for item in data_with_meta]
                results = self.predict_threats(np.array(features), 'log', metadata, mode)
                print(f"[DEBUG] scan_logs: predict_threats returned {len(results)} results.")
                return results
            print("[DEBUG] scan_logs: No log data to scan.")
            return []
        except Exception as e:
            msg = str(e)
            if 'refused the network connection' in msg or 'AccessDenied' in msg:
                print("Error scanning logs: Permission denied or remote connection refused. Try running as Administrator and ensure you are scanning the local machine.")
            else:
                print(f"Error scanning logs: {e}")
            return []

    def scan_files(self, path, mode: str = 'classic'):
        """Scan files in a directory for potential malware."""
        if not os.path.exists(path):
            raise FileNotFoundError(f"Path not found: {path}")
        try:
            data_with_meta = self.collect_file_data(path)
            if data_with_meta:
                features = [item[0] for item in data_with_meta]
                metadata = [item[1] for item in data_with_meta]
                return self.predict_threats(np.array(features), 'file', metadata, mode)
            return []
        except Exception as e:
            print(f"Error scanning files: {e}")
            return []

    def collect_process_data(self):
        process_data = []
        for proc in psutil.process_iter(['pid', 'name', 'exe', 'username']):
            try:
                info = proc.info
                # Get connections safely
                try:
                    num_connections = len(proc.connections())
                except (psutil.AccessDenied, psutil.NoSuchProcess):
                    num_connections = 0
                
                # Enhanced feature vector for processes
                features = [
                    float(info['pid']),
                    len(info['name']) if info['name'] else 0,
                    1 if info['username'] and 'SYSTEM' in info['username'].upper() else 0,
                    float(proc.cpu_percent() or 0),
                    float(proc.memory_percent() or 0),
                    float(num_connections),
                    1 if info['exe'] and info['exe'].lower().endswith('.exe') else 0,
                    proc.num_threads() if hasattr(proc, 'num_threads') else 0
                ]
                metadata = {
                    'pid': info['pid'],
                    'process_name': info['name']
                }
                process_data.append((features, metadata))
            except (psutil.NoSuchProcess, psutil.AccessDenied, Exception) as e:
                continue
        return process_data

    def collect_log_data(self):
        log_data = []
        server = 'localhost'
        hand = None
        try:
            hand = win32evtlog.OpenEventLog(server, 'Security')
            flags = win32evtlog.EVENTLOG_BACKWARDS_READ | win32evtlog.EVENTLOG_SEQUENTIAL_READ
            events = win32evtlog.ReadEventLog(hand, flags, 0)
            print(f"[DEBUG] Collected {len(events)} events from Windows Event Log.")
            for event in events[:50]:  # Limit to 50 events
                features = [
                    float(event.EventID & 0xFFFF),
                    float(event.EventType),
                    len(event.SourceName),
                    1 if event.EventType in [1, 2] else 0,  # Error or Warning
                    float(len(str(event.StringInserts)) if event.StringInserts else 0),
                    float(event.TimeGenerated.hour),
                    1 if 'SYSTEM' in str(event.SourceName).upper() else 0,
                    float(len(str(event.Data)) if event.Data else 0)
                ]
                metadata = {
                    'event_id': int(event.EventID & 0xFFFF),
                    'event_type': int(event.EventType),
                    'source_name': event.SourceName,
                    'time_generated': event.TimeGenerated.strftime('%Y-%m-%d %H:%M:%S'),
                    'event_category': getattr(event, 'EventCategory', None),
                    'event_data': str(event.Data) if event.Data else '',
                    'string_inserts': str(event.StringInserts) if event.StringInserts else ''
                }
                log_data.append((features, metadata))
            print(f"[DEBUG] Prepared {len(log_data)} log data entries for prediction.")
        except Exception as e:
            print(f"Error reading event log: {e}")
        finally:
            if hand:
                win32evtlog.CloseEventLog(hand)
        return log_data

    def collect_file_data(self, path):
        file_data = []
        suspicious_keywords = [
            'malware', 'virus', 'trojan', 'worm', 'exploit', 'payload', 'ransomware',
            'keylogger', 'backdoor', 'rootkit', 'phishing', 'attack', 'hacker', 'botnet'
        ]
        malware_hashes = load_hashes()  # Reload hashes every scan
        if os.path.isfile(path):
            files_to_scan = [(os.path.dirname(path), [os.path.basename(path)])]
        else:
            files_to_scan = [(root, files) for root, _, files in os.walk(path)]

        for root, files in files_to_scan:
            for file in files:
                try:
                    full_path = os.path.join(root, file)
                    stat = os.stat(full_path)
                    file_hash = compute_sha256(full_path)
                    # --- HASH CHECK ---
                    if file_hash and file_hash in malware_hashes:
                        metadata = {
                            'file_name': file,
                            'file_path': full_path,
                            'hash': file_hash,
                            'detection': 'hash',
                        }
                        # Use a dummy feature vector (not used)
                        features = [0.0] * 8
                        file_data.append((features, metadata))
                        continue  # skip ML for this file
                    suspicious_content = 0
                    if file.lower().endswith('.pdf'):
                        try:
                            with open(full_path, 'rb') as f:
                                reader = PyPDF2.PdfReader(f)
                                text = " ".join(page.extract_text() or '' for page in reader.pages)
                                if any(word in text.lower() for word in suspicious_keywords):
                                    suspicious_content = 1
                        except Exception:
                            pass
                    elif file.lower().endswith('.docx'):
                        try:
                            doc = docx.Document(full_path)
                            text = " ".join([para.text for para in doc.paragraphs])
                            if any(word in text.lower() for word in suspicious_keywords):
                                suspicious_content = 1
                        except Exception:
                            pass
                    features = [
                        float(stat.st_size),
                        1 if file.lower().endswith(('.exe', '.dll', '.sys')) else 0,
                        1 if file.startswith('.') else 0,
                        float(stat.st_mtime - stat.st_ctime),
                        float(stat.st_atime - stat.st_mtime),
                        float(len(file)),
                        float(stat.st_nlink),
                        1 if os.access(full_path, os.X_OK) else 0,
                    ]
                    metadata = {
                        'file_name': file,
                        'file_path': full_path,
                        'hash': file_hash,
                        'detection': 'ml',
                    }
                    file_data.append((features, metadata))
                except Exception:
                    continue
        return file_data

    def predict_threats(self, data, scan_type, metadata_list=None, mode: str = 'classic'):
        """
        Predict threats from the given feature data using the selected mode.
        Args:
            data (numpy.ndarray): Feature vector or array of feature vectors
            scan_type (str): Type of scan ('process', 'file', or 'log')
            metadata_list (list): List of dictionaries containing metadata for each threat
            mode (str): 'classic' or 'quantum'
        Returns:
            list: List of dictionaries containing threat information
        """
        try:
            if len(data.shape) == 1:
                data = data.reshape(1, -1)
            model, scaler = self.get_model_scaler(mode)
            results = []
            current_time = datetime.now().isoformat()
            # Whitelists
            system_processes = {'system', 'svchost.exe', 'wininit.exe', 'csrss.exe', 'winlogon.exe', 'services.exe', 'lsass.exe', 'smss.exe'}
            safe_file_exts = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico', '.dll', '.sys', '.txt', '.md', '.pdf'}
            for i in range(len(data)):
                meta = metadata_list[i] if metadata_list and i < len(metadata_list) else {}
                # If detected by hash, skip ML and flag as malicious
                if meta.get('detection') == 'hash':
                    result = {
                        'threat_score': 1.0,
                        'scan_type': scan_type,
                        'timestamp': current_time,
                        'feature_vector': [],
                        'conclusion': 'malicious',
                        'hash': meta.get('hash'),
                        **meta
                    }
                    results.append(result)
                    continue
                # Otherwise, run ML
                scaled_data = scaler.transform(data[i].reshape(1, -1))
                score = model.predict_proba(scaled_data)[:, 1][0]
                conclusion = 'malicious' if score >= self.threshold else 'benign'
                # Whitelist logic
                if scan_type == 'file':
                    fname = meta.get('file_name', '').lower()
                    ext = os.path.splitext(fname)[1]
                    if ext in safe_file_exts:
                        conclusion = 'benign'
                result = {
                    'threat_score': float(score),
                    'scan_type': scan_type,
                    'timestamp': current_time,
                    'feature_vector': data[i].tolist(),
                    'conclusion': conclusion,
                    'hash': meta.get('hash'),
                    **meta
                }
                results.append(result)
            return results
        except Exception as e:
            print(f"Error in predict_threats: {str(e)}")
            return [] 