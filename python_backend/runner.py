import sys
import json
import logging
from scanner import MalwareScanner

logging.basicConfig(level=logging.INFO)

def main():
    scanner = MalwareScanner()
    if len(sys.argv) < 2:
        print("No command provided")
        return

    command = sys.argv[1]
    try:
        if command == 'scan_processes':
            result = scanner.scan_processes()
        elif command == 'scan_logs':
            result = scanner.scan_logs()
        elif command == 'scan_files':
            if len(sys.argv) < 3:
                print("File path required for scan_files")
                return
            result = scanner.scan_files(sys.argv[2])
        else:
            print("Invalid command")
            return

        print(json.dumps(result))
    except Exception as e:
        logging.exception("Error during scanning")
        print(json.dumps({'error': str(e)}))

if __name__ == "__main__":
    main() 