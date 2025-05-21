# Fleet Monitoring App

A Flutter-based mobile application for real-time fleet tracking and monitoring. This app allows users to track vehicle locations, status, and movement in real-time using Google Maps integration.

## Features

- **Real-time Vehicle Tracking**: Monitor the location and status of all vehicles in your fleet
- **Interactive Map**: View all vehicles on an interactive Google Maps interface
- **Detailed Vehicle Information**: Get detailed information about each vehicle including:
  - Current speed
  - Status (Moving, Stopped, Idle)
  - GPS coordinates
  - Last updated timestamp
- **Filtering Options**: Filter vehicles by status (All, Moving, Stopped, Idle)
- **Search Functionality**: Quickly find specific vehicles by name
- **Live Updates**: Automatic polling every 10 seconds to ensure data is current
- **Vehicle List View**: Toggle between map view and list view of all vehicles
- **Vehicle Details Screen**: Dedicated screen for each vehicle with tracking capability
- **Map Controls**: Center view, fit all markers, and zoom controls

## Screenshots

*[Screenshots would be included here]*

## System Requirements

- Flutter 3.27.3 or compatible version
- Dart 3.6.1 or higher
- Android 5.0+ (API level 21+) or iOS 11.0+
- Google Maps API key

## Installation

1. **Clone the repository**
   ```
   git clone https://github.com/MugemaneBertin2001/car_tracker.git
   cd car_tracker
   ```

2. **Install dependencies**
   ```
   flutter pub get
   ```

3. **Google Maps API Key**

   A testing API key for Google Maps is already included in the source code, so you don't need to provide your own key for initial testing and development.

4. **Run the app**
   ```
   flutter run
   ```



## How It Works

### Home Screen

The Home Screen (`home_screen.dart`) serves as the main interface with the following components:

1. **Google Maps View**: Displays all vehicles as markers on the map
   - Green markers: Moving vehicles
   - Red markers: Stopped vehicles
   - Blue markers: Idle vehicles

2. **Search Bar**: Filter vehicles by name

3. **Status Filters**: Filter vehicles by their current status (All, Moving, Stopped, Idle)

4. **Vehicle List Panel**: Sliding panel showing all vehicles in list format

5. **Control Buttons**:
   - Refresh: Manually refresh vehicle data
   - Center Map: Reset map zoom
   - Fit All Markers: Adjust view to show all vehicles
   - Toggle List View: Show/hide the vehicle list panel

### Car Details Screen

The Car Details Screen (`car_details_screen.dart`) provides detailed information about a specific vehicle:

1. **Vehicle Information Card**: Displays vehicle name, status, speed, and coordinates

2. **Dedicated Map**: Shows the selected vehicle's location with automatic tracking

3. **Tracking Toggle**: Enables/disables live tracking of the vehicle

### Data Flow

1. The app initializes by fetching vehicle data through the `CarProvider` class
2. Vehicle data is regularly updated through a polling mechanism (every 10 seconds)
3. When a vehicle's location or status changes, the map and information displays are updated
4. Users can interact with the map or list to view specific vehicle details

## Backend Configuration

The app is configured to connect to the following backend endpoint:
```
https://cars-pooling.onrender.com/cars
```

This endpoint provides the vehicle data in the required format. No additional backend configuration is needed to run the application.

## Customization

- **Polling Interval**: Modify the `_pollingInterval` variable in `HomeScreen` to change how frequently the app fetches new data
- **Map Styling**: Customize the Google Maps appearance by adding map styles to the `GoogleMap` widget
- **Status Colors**: Modify the marker and icon colors in `_buildMarkers` method to match your branding

## Contact

- Mugemane Bertin: bertin.m2001@gmail.com
- Phone: (+250)781120876