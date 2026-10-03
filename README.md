# Smart Office Queue & Token Management System

A full-stack queue and token management system designed for office visitors and staff. The system allows visitors to generate department-specific tokens and enables staff/admin users to manage queues in real time.

## Demo Login Credentials

### Admin

- Email: `admin@smartoffice.com`
- Password: `admin123`
- Role: Admin

### Staff

- Email: `staff@smartoffice.com`
- Password: `staff123`
- Role: Staff

### Visitor

No login is required. Select **Continue as Visitor** from the login screen.

## Features

### Visitor Features

- Generate queue tokens without login
- Select department
- Automatic department-specific token numbers
- Priority token support
- View current queue position
- View people ahead in the queue
- View estimated waiting time
- Cancel token
- Track token status
- Automatically updated queue information

### Staff Features

- Staff login
- View department queue
- View currently serving token
- Call Next token
- Complete token
- Mark visitor as No Show
- Transfer token to another department
- View queue statistics

### Admin Features

- Admin login
- View dashboard statistics
- Manage department queues
- Pause/resume departments
- Call Next
- Complete tokens
- Mark No Show
- Transfer tokens
- Monitor waiting, serving and completed tokens

### Queue Management Logic

- Priority tokens are served before normal tokens.
- A priority token does not interrupt a token currently being served.
- First No Show moves the token to the end of the queue.
- Second No Show automatically cancels the token.
- Paused departments cannot generate new tokens.
- Transferring a token creates a new token number for the destination department.
- Queue position and estimated waiting time update when the queue changes.
- Only one token can be actively served in a department at a time.

## Departments

The system currently supports:

| Department     | Code |
|----------------|------|
| IT Support     | IT   |
| HR             | HR   |
| Accounts       | ACC  |
| Administration | ADM  |

## Technology Stack

### Frontend

- Flutter
- Dart
- Material 3
- HTTP / REST API

### Backend

- Go (Golang)
- REST API
- JWT Authentication
- bcrypt Password Hashing

### Database

- PostgreSQL

### Development Tools

- Visual Studio Code
- Android Studio / Flutter SDK
- WSL Ubuntu
- Git & GitHub

## Environment Configuration

Create a file named `backend/.env` before running the backend:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_postgres_password
DB_NAME=smart_office_queue
JWT_SECRET=your_secret_key
```

Do not commit the `.env` file to GitHub.

## Database Setup

Create the PostgreSQL database:

```sql
CREATE DATABASE smart_office_queue;
```

Then execute the database schema:

```text
database/schema.sql
```

The schema creates the required tables, indexes, departments, and initial users.

## Backend Setup

Open WSL Ubuntu and navigate to the backend directory:

```bash
cd /mnt/c/Users/LAXMI/smart-office-queue/backend
```

Install Go dependencies:

```bash
go mod tidy
```

Start the backend server:

```bash
go run .
```

The backend will run at:

```text
http://localhost:8080
```

## Frontend Setup

Open a new terminal and navigate to the Flutter project:

```bash
cd C:\Users\LAXMI\smart-office-queue\frontend\smart_office_queue
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the application in Chrome:

```bash
flutter run -d chrome
```

## Application Access

### Admin

Use the admin credentials to access the full dashboard and department management features.

```text
Email: admin@smartoffice.com
Password: admin123
```

### Staff

Use the staff credentials to manage the assigned department queue.

```text
Email: staff@smartoffice.com
Password: staff123
```

### Visitor

Visitors do not need to log in.

From the login screen, select:

**Continue as Visitor**

Visitors can then generate and track their queue token.

## Screenshots

### Visitor Token Generation

![Visitor Token Generation](screenshots/visitor-token.png)

### Queue Status

![Queue Status](screenshots/queue-status.png)

### Staff Dashboard

![Staff Dashboard](screenshots/staff-dashboard.png)

### Call Next

![Call Next](screenshots/call-next.png)

### No Show and Complete

![No Show and Complete](screenshots/no-show-complete.png)

### Token Transfer

![Token Transfer](screenshots/transfer.png)

### Department Pause and Resume

![Department Pause and Resume](screenshots/pause-resume.png)

### Admin Dashboard

![Admin Dashboard](screenshots/admin-dashboard.png)

### Department Status

![Department Status](screenshots/department_status.png)

## Project Structure

```text
smart-office-queue/
│
├── backend/
│   ├── database/
│   ├── handlers/
│   ├── middleware/
│   ├── models/
│   ├── repository/
│   ├── services/
│   ├── utils/
│   ├── go.mod
│   └── main.go
│
├── frontend/
│   └── smart_office_queue/
│       ├── lib/
│       ├── android/
│       ├── ios/
│       ├── web/
│       └── pubspec.yaml
│
├── database/
│   └── schema.sql
│
├── screenshots/
│   ├── visitor-token.png
│   ├── queue-status.png
│   ├── staff-dashboard.png
│   ├── call-next.png
│   ├── no-show-complete.png
│   ├── transfer.png
│   ├── pause-resume.png
│   ├── admin-dashboard.png
│   └── department_status.png
│
├── .gitignore
└── README.md
```

## API Endpoints

### Public Endpoints

```text
POST /api/auth/login
GET  /api/departments
POST /api/tokens
GET  /api/queue
GET  /api/tokens/status
POST /api/queue/cancel
```

### Staff / Admin Endpoints

```text
GET  /api/dashboard
POST /api/queue/next
POST /api/queue/complete
POST /api/queue/no-show
POST /api/queue/transfer
```

### Admin Only

```text
POST /api/departments/pause
```

## Queue Flow

```text
Visitor
   ↓
Select Department
   ↓
Generate Token
   ↓
Join Queue
   ↓
View Queue Position & ETA
   ↓
Staff Calls Next
   ↓
Currently Serving
   ↓
Complete / No Show / Transfer
   ↓
Queue Updated
```

## Security

- JWT-based authentication for staff/admin users
- Role-based authorization
- Passwords protected using bcrypt hashing
- Protected staff/admin queue operations
- Visitor token generation does not require login
- Database credentials are stored in `.env` and excluded from Git

## Future Improvements

- WebSocket-based real-time queue updates
- SMS/email notifications
- Advanced analytics
- Multi-branch office support
- Mobile APK deployment
- Cloud deployment

## Author

**Laxmi Pal**

- GitHub: https://github.com/laxmi-ux
- LinkedIn: https://www.linkedin.com/in/laxmi-pal-13a738267
- Portfolio: https://laxmipal2026.netlify.app/
