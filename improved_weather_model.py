"""
Improved Weather Forecasting Model with Feature Engineering
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
import warnings

warnings.filterwarnings('ignore')


class FeatureEngineer:
    """Feature engineering class for weather data preprocessing"""
    
    def __init__(self):
        self.scaler = StandardScaler()
        
    def create_trend_features(self, df):
        """Create trend-based features from weather data"""
        # Make a copy to avoid modifying original data
        df = df.copy()
        
        # Temperature trends
        df['temp_7d_avg'] = df['temperature'].rolling(7, min_periods=1).mean()
        df['temp_30d_avg'] = df['temperature'].rolling(30, min_periods=1).mean()
        df['temp_trend'] = df['temperature'] - df['temp_7d_avg']
        
        # Pressure trends
        df['pressure_7d_avg'] = df['pressure'].rolling(7, min_periods=1).mean()
        df['pressure_trend'] = df['pressure'] - df['pressure_7d_avg']
        
        # Humidity trends
        df['humidity_7d_avg'] = df['humidity'].rolling(7, min_periods=1).mean()
        df['humidity_trend'] = df['humidity'] - df['humidity_7d_avg']
        
        # Wind speed trends
        df['wind_speed_7d_avg'] = df['wind_speed'].rolling(7, min_periods=1).mean()
        df['wind_speed_trend'] = df['wind_speed'] - df['wind_speed_7d_avg']
        
        # Precipitation patterns - FIXED: boolean comparison before rolling window
        df['dry_days_7d'] = (df['precipitation'] == 0).rolling(7, min_periods=1).sum()
        df['wet_days_7d'] = (df['precipitation'] > 0).rolling(7, min_periods=1).sum()
        df['precipitation_7d_sum'] = df['precipitation'].rolling(7, min_periods=1).sum()
        df['precipitation_30d_sum'] = df['precipitation'].rolling(30, min_periods=1).sum()
        
        # Additional precipitation patterns - FIXED: boolean comparison before rolling window
        df['light_rain_days_7d'] = ((df['precipitation'] > 0) & (df['precipitation'] <= 2.5)).rolling(7, min_periods=1).sum()
        df['heavy_rain_days_7d'] = (df['precipitation'] > 10).rolling(7, min_periods=1).sum()
        
        return df
        
    def create_lag_features(self, df, columns, lags=[1, 2, 3, 7]):
        """Create lag features for specified columns"""
        df = df.copy()
        
        for col in columns:
            for lag in lags:
                df[f'{col}_lag_{lag}'] = df[col].shift(lag)
                
        return df
        
    def create_seasonal_features(self, df):
        """Create seasonal and cyclical features"""
        df = df.copy()
        
        # Ensure index is datetime
        if not isinstance(df.index, pd.DatetimeIndex):
            df.index = pd.to_datetime(df.index)
            
        # Day of year cyclical features
        df['day_of_year_sin'] = np.sin(2 * np.pi * df.index.dayofyear / 365.25)
        df['day_of_year_cos'] = np.cos(2 * np.pi * df.index.dayofyear / 365.25)
        
        # Month features
        df['month'] = df.index.month
        df['season'] = df['month'].map({12: 0, 1: 0, 2: 0,  # Winter
                                       3: 1, 4: 1, 5: 1,    # Spring
                                       6: 2, 7: 2, 8: 2,    # Summer
                                       9: 3, 10: 3, 11: 3}) # Fall
        
        return df


class ImprovedWeatherForecaster:
    """Enhanced weather forecasting model with advanced feature engineering"""
    
    def __init__(self):
        self.feature_engineer = FeatureEngineer()
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.scaler = StandardScaler()
        self.feature_columns = None
        self.is_fitted = False
        
    def preprocess_data(self, df):
        """Preprocess weather data with feature engineering"""
        print("Starting data preprocessing...")
        
        # Create trend features
        df = self.feature_engineer.create_trend_features(df)
        
        # Create lag features for key variables
        lag_columns = ['temperature', 'pressure', 'humidity', 'wind_speed']
        df = self.feature_engineer.create_lag_features(df, lag_columns)
        
        # Create seasonal features
        df = self.feature_engineer.create_seasonal_features(df)
        
        # Drop rows with NaN values (due to rolling windows and lags)
        df = df.dropna()
        
        print(f"Preprocessing complete. Shape: {df.shape}")
        return df
        
    def fit(self, X, y):
        """Train the weather forecasting model"""
        print("Training weather forecasting model...")
        
        # Preprocess the data
        X_processed = self.preprocess_data(X)
        
        # Align y with processed X (account for dropped rows)
        y_aligned = y.loc[X_processed.index]
        
        # Store feature columns
        self.feature_columns = X_processed.columns.tolist()
        
        # Scale features
        X_scaled = self.scaler.fit_transform(X_processed)
        
        # Train model
        self.model.fit(X_scaled, y_aligned)
        self.is_fitted = True
        
        print("Model training complete.")
        
    def predict(self, X):
        """Make weather predictions"""
        if not self.is_fitted:
            raise ValueError("Model must be fitted before making predictions")
            
        # Preprocess the data
        X_processed = self.preprocess_data(X)
        
        # Ensure same features as training
        X_processed = X_processed[self.feature_columns]
        
        # Scale features
        X_scaled = self.scaler.transform(X_processed)
        
        # Make predictions
        predictions = self.model.predict(X_scaled)
        
        return predictions
        
    def get_feature_importance(self):
        """Get feature importance scores"""
        if not self.is_fitted:
            raise ValueError("Model must be fitted before getting feature importance")
            
        importance_df = pd.DataFrame({
            'feature': self.feature_columns,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        return importance_df


def create_sample_weather_data(n_days=365):
    """Create sample weather data for testing"""
    np.random.seed(42)
    
    dates = pd.date_range(start='2023-01-01', periods=n_days, freq='D')
    
    # Create realistic weather patterns
    temp_base = 20 + 10 * np.sin(2 * np.pi * np.arange(n_days) / 365.25)  # Seasonal temperature
    temp_noise = np.random.normal(0, 3, n_days)
    temperature = temp_base + temp_noise
    
    pressure = 1013 + np.random.normal(0, 10, n_days)
    humidity = np.clip(60 + np.random.normal(0, 15, n_days), 0, 100)
    wind_speed = np.clip(np.random.exponential(5, n_days), 0, 30)
    
    # Precipitation with some dry spells
    precipitation = np.random.exponential(2, n_days)
    dry_days = np.random.choice([True, False], n_days, p=[0.7, 0.3])  # 70% chance of dry day
    precipitation[dry_days] = 0
    
    df = pd.DataFrame({
        'temperature': temperature,
        'pressure': pressure,
        'humidity': humidity,
        'wind_speed': wind_speed,
        'precipitation': precipitation
    }, index=dates)
    
    return df


if __name__ == "__main__":
    # Test the weather forecasting model
    print("Creating sample weather data...")
    weather_data = create_sample_weather_data(365)
    
    print("Weather data sample:")
    print(weather_data.head())
    print(f"Data shape: {weather_data.shape}")
    
    # Create target variable (next day temperature)
    target = weather_data['temperature'].shift(-1).dropna()
    features = weather_data.iloc[:-1]  # Remove last row to align with target
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        features, target, test_size=0.2, random_state=42
    )
    
    # Initialize and train model
    forecaster = ImprovedWeatherForecaster()
    
    try:
        forecaster.fit(X_train, y_train)
        print("Model training successful!")
        
        # Make predictions
        predictions = forecaster.predict(X_test)
        print(f"Made {len(predictions)} predictions")
        
        # Show feature importance
        importance = forecaster.get_feature_importance()
        print("\nTop 10 most important features:")
        print(importance.head(10))
        
    except Exception as e:
        print(f"Error during model training/prediction: {e}")
        raise