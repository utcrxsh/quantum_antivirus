from scanner import MalwareScanner
import os

def test_scanner():
    try:
        # Initialize scanner
        print("Initializing MalwareScanner...")
        scanner = MalwareScanner()
        
        # Test process scanning
        print("\nTesting process scanning...")
        process_results = scanner.scan_processes()
        print(f"Process scan results: {len(process_results)} potential threats found")
        if process_results:
            print("Sample threat:", process_results[0])
        
        # Test file scanning (scanning the current directory)
        print("\nTesting file scanning...")
        current_dir = os.path.dirname(os.path.abspath(__file__))
        file_results = scanner.scan_files(current_dir)
        print(f"File scan results: {len(file_results)} potential threats found")
        if file_results:
            print("Sample threat:", file_results[0])
        
        # Test log scanning
        print("\nTesting log scanning...")
        log_results = scanner.scan_logs()
        print(f"Log scan results: {len(log_results)} potential threats found")
        if log_results:
            print("Sample threat:", log_results[0])
            
        print("\nAll tests completed successfully!")
        
    except Exception as e:
        print(f"Error during testing: {str(e)}")

if __name__ == "__main__":
    test_scanner() 