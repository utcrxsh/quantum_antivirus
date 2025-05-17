import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import joblib
import os

def create_sample_data():
    """Create sample data for training the model"""
    # Generate synthetic data for demonstration
    np.random.seed(42)
    n_samples = 1000
    
    # Features for benign samples
    benign_features = np.random.normal(loc=0.3, scale=0.2, size=(n_samples // 2, 8))
    benign_labels = np.zeros(n_samples // 2)
    
    # Features for malicious samples
    malicious_features = np.random.normal(loc=0.7, scale=0.2, size=(n_samples // 2, 8))
    malicious_labels = np.ones(n_samples // 2)
    
    # Combine the data
    X = np.vstack([benign_features, malicious_features])
    y = np.hstack([benign_labels, malicious_labels])
    
    return X, y

def train_model():
    """Train the random forest model and save it"""
    print("Creating sample data...")
    X, y = create_sample_data()
    
    print("Training model...")
    # Create and train the model
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    
    # Create and fit the scaler
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Train the model
    model.fit(X_scaled, y)
    
    # Create model directory if it doesn't exist
    model_dir = os.path.join(os.path.dirname(__file__), 'model')
    os.makedirs(model_dir, exist_ok=True)
    
    # Save the model and scaler
    print("Saving model and scaler...")
    model_path = os.path.join(model_dir, 'malware_detector.pkl')
    scaler_path = os.path.join(model_dir, 'scaler.pkl')
    
    joblib.dump(model, model_path)
    joblib.dump(scaler, scaler_path)
    
    print(f"Model saved to: {model_path}")
    print(f"Scaler saved to: {scaler_path}")
    
    # Test the model
    print("\nTesting model...")
    test_pred = model.predict_proba(X_scaled[:5])
    print("Sample predictions (probability of malicious):")
    print(test_pred[:, 1])

if __name__ == "__main__":
    train_model() 