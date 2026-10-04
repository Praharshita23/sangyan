🛡️ Sangyan
Sangyan is a scam detection application that helps users identify potentially suspicious messages, images, and links using AI-powered analysis.

✨ Features
🔍 Message Scanner — Analyze suspicious text messages.
🖼️ Image Scanner — Scan screenshots and images for suspicious content.
🔗 Link Scanner — Check suspicious URLs.
📱 Flutter App — Cross-platform user interface.
🌐 Web Support — Access the application through a browser.
⚡ FastAPI Backend — Handles scanning and analysis requests.
☁️ Cloud Deployment — Frontend and backend can be deployed independently.
🏗️ Project Structure
sangyan/
│
├── app/                    # Flutter frontend
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   └── services/
│   └── build/
│       └── web/            # Production web build
│
├── backend/                # Python FastAPI backend
│
├── .gitignore
└── README.md
🛠️ Tech Stack
Frontend
Flutter
Dart
Backend
Python
FastAPI
Deployment
GitHub
Render
🔄 How Sangyan Works
        User
          │
          ▼
   ┌───────────────┐
   │ Sangyan App   │
   └───────┬───────┘
           │
     ┌─────┼─────┐
     ▼     ▼     ▼
  Message Image  Link
   Scan   Scan   Scan
     │     │     │
     └─────┼─────┘
           ▼
    ┌───────────────┐
    │ Sangyan API   │
    └───────┬───────┘
            ▼
       AI Analysis
            │
            ▼
      Scan Result
🌐 API Endpoints
The Flutter application communicates with the Sangyan backend through the following endpoints:

POST /scan
POST /scan-image
POST /scan-link
💻 Run Locally
Backend
Create a virtual environment:

python -m venv venv

Activate it on Windows:

venv\Scripts\activate

Install dependencies:

pip install -r backend/requirements.txt

Configure your environment variables in a local .env file.

Start the backend:

uvicorn backend.main:app --reload

Flutter App
Go to the Flutter application:

cd app

Install dependencies:

flutter pub get

Run the application:

flutter run

To build the web version:

flutter build web --release

The production web files will be generated in:

app/build/web
🔐 Environment Variables
Sensitive information such as API keys and credentials should never be committed to GitHub.

Create a local .env file for your secrets.

Example:

API_KEY=your_api_key_here
The .env file is excluded from Git using .gitignore.

☁️ Deployment
Sangyan can be deployed using GitHub and Render.

The frontend and backend can be hosted separately, with the Flutter application communicating with the deployed Sangyan API.

⚠️ Disclaimer
Sangyan is designed to assist users in identifying potentially suspicious or fraudulent content.

Scan results should not be treated as a guaranteed determination that content is safe or malicious. Users should always exercise caution when opening links, replying to messages, or providing personal information.

⭐ If you find Sangyan useful, consider giving the repository a star!

