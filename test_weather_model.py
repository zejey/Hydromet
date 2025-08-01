"""
Test script to validate the weather model fix
"""

import pandas as pd
import numpy as np
from improved_weather_model import FeatureEngineer, ImprovedWeatherForecaster


def test_precipitation_patterns():
    """Test that the precipitation pattern calculations work correctly"""
    print("Testing precipitation pattern calculations...")
    
    # Create test data with known patterns
    dates = pd.date_range(start='2023-01-01', periods=10, freq='D')
    precipitation = [0, 0, 5, 0, 0, 0, 0, 15, 2, 0]  # Known pattern
    
    test_data = pd.DataFrame({
        'temperature': np.random.normal(20, 5, 10),
        'pressure': np.random.normal(1013, 10, 10),
        'humidity': np.random.normal(60, 15, 10),
        'wind_speed': np.random.exponential(5, 10),
        'precipitation': precipitation
    }, index=dates)
    
    # Test the feature engineering
    fe = FeatureEngineer()
    result = fe.create_trend_features(test_data)
    
    # Validate dry_days_7d calculation
    print("Original precipitation data:")
    print(precipitation)
    print("\nCalculated dry_days_7d:")
    print(result['dry_days_7d'].tolist())
    
    # Manual verification for the last few days
    expected_dry_days_7d_last = sum([p == 0 for p in precipitation[-7:]])  # Last 7 days
    calculated_dry_days_7d_last = result['dry_days_7d'].iloc[-1]
    
    print(f"\nManual calculation for last 7 days: {expected_dry_days_7d_last}")
    print(f"Model calculation for last 7 days: {calculated_dry_days_7d_last}")
    
    assert abs(expected_dry_days_7d_last - calculated_dry_days_7d_last) < 0.001, "Dry days calculation is incorrect!"
    
    # Validate wet_days_7d calculation  
    expected_wet_days_7d_last = sum([p > 0 for p in precipitation[-7:]])  # Last 7 days
    calculated_wet_days_7d_last = result['wet_days_7d'].iloc[-1]
    
    print(f"Manual calculation for wet days (last 7): {expected_wet_days_7d_last}")
    print(f"Model calculation for wet days (last 7): {calculated_wet_days_7d_last}")
    
    assert abs(expected_wet_days_7d_last - calculated_wet_days_7d_last) < 0.001, "Wet days calculation is incorrect!"
    
    # Validate light rain days
    light_rain_days = sum([0 < p <= 2.5 for p in precipitation[-7:]])
    calculated_light_rain = result['light_rain_days_7d'].iloc[-1]
    
    print(f"Manual calculation for light rain days (last 7): {light_rain_days}")
    print(f"Model calculation for light rain days (last 7): {calculated_light_rain}")
    
    assert abs(light_rain_days - calculated_light_rain) < 0.001, "Light rain days calculation is incorrect!"
    
    # Validate heavy rain days
    heavy_rain_days = sum([p > 10 for p in precipitation[-7:]])
    calculated_heavy_rain = result['heavy_rain_days_7d'].iloc[-1]
    
    print(f"Manual calculation for heavy rain days (last 7): {heavy_rain_days}")
    print(f"Model calculation for heavy rain days (last 7): {calculated_heavy_rain}")
    
    assert abs(heavy_rain_days - calculated_heavy_rain) < 0.001, "Heavy rain days calculation is incorrect!"
    
    print("\n✓ All precipitation pattern calculations are correct!")


def test_full_model_pipeline():
    """Test the complete model pipeline"""
    print("\nTesting complete model pipeline...")
    
    # Create larger test dataset
    np.random.seed(42)
    dates = pd.date_range(start='2023-01-01', periods=100, freq='D')
    
    test_data = pd.DataFrame({
        'temperature': np.random.normal(20, 5, 100),
        'pressure': np.random.normal(1013, 10, 100),
        'humidity': np.clip(np.random.normal(60, 15, 100), 0, 100),
        'wind_speed': np.clip(np.random.exponential(5, 100), 0, 30),
        'precipitation': np.random.exponential(2, 100) * np.random.choice([0, 1], 100, p=[0.7, 0.3])
    }, index=dates)
    
    # Create target (next day temperature)
    target = test_data['temperature'].shift(-1).dropna()
    features = test_data.iloc[:-1]
    
    # Test model training and prediction
    model = ImprovedWeatherForecaster()
    model.fit(features, target)
    
    # Make predictions
    predictions = model.predict(features.iloc[-10:])  # Predict on last 10 days
    
    print(f"Successfully made {len(predictions)} predictions")
    print(f"Prediction range: {predictions.min():.2f} to {predictions.max():.2f}")
    
    # Get feature importance
    importance = model.get_feature_importance()
    print(f"\nModel uses {len(importance)} features")
    print("Top 5 features:")
    print(importance.head(5))
    
    print("\n✓ Complete model pipeline works correctly!")


if __name__ == "__main__":
    test_precipitation_patterns()
    test_full_model_pipeline()
    print("\n🎉 All tests passed! The weather model fix is working correctly.")