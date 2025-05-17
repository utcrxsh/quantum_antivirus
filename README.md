# Quantum Antivirus Project

A cross-platform malware scanning and prediction tool with a Flutter frontend and a native Python backend.

## Project Structure

```
/quantum_antivirus_project/
├── flutter_app/
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
├── python_backend/
│   ├── model/
│   │   └── malware_detector.pkl
│   ├── scanner.py
│   ├── runner.py
│   ├── requirements.txt
│   └── utils.py
├── integration/
│   └── glue_code.py
└── README.md
```

## Setup

### Python Backend
1. Navigate to `python_backend/`.
2. Create a virtual environment and activate it:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Place your trained model as `model/malware_detector.pkl`.

### Flutter Frontend
1. Navigate to `flutter_app/`.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run -d windows
   ```

## Usage
- The Flutter app communicates with the Python backend using `Process.run()`.
- Use the UI to trigger scans (processes, files, logs).
- Results are displayed in the app.

## Notes
- For advanced integration, consider using Platform Channels or a local REST API.
- Ensure Python is installed and available in your system PATH.

No supported devices connected.

The following devices were found, but are not supported by this project:
Windows (desktop) • windows • windows-x64    • Microsoft Windows [Version 10.0.26100.3915]
Chrome (web)      • chrome  • web-javascript • Google Chrome 135.0.7049.115
Edge (web)        • edge    • web-javascript • Microsoft Edge 135.0.3179.98
If you would like your app to run on web or windows, consider running `flutter create .` to generate projects for these platforms. 