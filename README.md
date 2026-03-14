# Lott Super - Lottery Management System

A comprehensive lottery management system with a Flutter Android app and Django backend.

## Features
- **User Hierarchy**: Super Admin, Admin, Agent, Dealer, Sub Dealer.
- **Game Management**: Add games with name and time.
- **Betting**: Support for 1-Digit, 2-Digit, and 3-Digit bets.
- **Reports**: Daily Sales, Count, Winning, and Net reports.
- **Dashboard**: Real-time balance and sales tracking.
- **Theme**: Premium Deep Red (#9c212c) aesthetics.

## Tech Stack
- **Frontend**: Flutter (Android)
- **Backend**: Django, Django Rest Framework
- **Database**: SQLite (default)

## Setup Instructions

### Backend
1. Navigate to the `backend` folder.
2. Activate the virtual environment: `.\venv\Scripts\activate`
3. Run migrations: `python manage.py migrate`
4. Run the seed script to create the admin user: `python seed.py`
5. Start the server: `python manage.py runserver 0.0.0.0:8000`

**Admin Credentials:**
- Username: `admin`
- Password: `admin123`

### Frontend
1. Navigate to the `frontend` folder.
2. Run `flutter pub get`.
3. Ensure an Android Emulator is running.
4. Run the app: `flutter run`

*Note: The API base URL is set to `http://10.0.2.2:8000` for Android Emulator.*
