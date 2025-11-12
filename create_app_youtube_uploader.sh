#!/bin/bash

# ===============================================
# Youtube Uploader Generator
# ===============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║               Youtube Uploader Generator                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Ask for project name
read -p "Enter your project folder name (default: youtube-uploader): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-youtube-uploader}

# Check if folder exists
if [ -d "$PROJECT_NAME" ]; then
    read -p "Folder '$PROJECT_NAME' already exists. Remove it? (y/N): " REMOVE
    REMOVE=${REMOVE:-N}
    if [[ "$REMOVE" == "y" || "$REMOVE" == "Y" ]]; then
        echo "Removing existing folder '$PROJECT_NAME'..."
        rm -rf "$PROJECT_NAME"
    else
        echo "Exiting to avoid overwriting."
        exit 1
    fi
fi

echo "Creating Python project in folder: $PROJECT_NAME"
mkdir -p "$PROJECT_NAME/upload" "$PROJECT_NAME/upload-complete"
cd "$PROJECT_NAME" || exit

# Create requirements.txt
echo -e "${CYAN}📝 Creating requirements.txt...${NC}"
cat << 'EOL' > requirements.txt
yt-dlp
pydub
soundfile 
lameenc
numpy
audioread
pillow
beautifulsoup4
tqdm
google-auth-oauthlib
google-api-python-client
EOL

# Create requirements.txt
echo -e "${CYAN}📝 Creating requirements.txt...${NC}"
cat << 'EOL' > ytreuploader_client_secrets.json
#ADD HERE th client secret frm OAuth from Google
#TO GENERATE GO TO README.html
#example
#{"installed":{"client_id":"1111232-gkkasd921.apps.googleusercontent.com","project_id":"ytreupload-12341","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"sadsr","redirect_uris":["http://localhost"]}}
EOL

# Create main Python script
echo -e "${CYAN}📝 Creating main Python script...${NC}"
cat << 'EOL' > ytuploader.py
#!/usr/bin/env python3.10
import os
import sys
import json
import time
from pathlib import Path
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# --- Settings ---
SCOPES = ['https://www.googleapis.com/auth/youtube.upload']
UPLOAD_DIR = Path("upload")
COMPLETED_DIR = Path("upload-complete")
LOG_FILE = Path("uploaded_log.json")

# --- Utilities ---
def sanitize_filename(name):
    return "".join(c for c in name if c not in '\\/*?:"<>|').strip()

# --- YouTube Upload ---
def authenticate_youtube():
    flow = InstalledAppFlow.from_client_secrets_file(
        'ytreuploader_client_secrets.json', SCOPES
    )
    credentials = flow.run_local_server(port=0)  # Opens browser for OAuth
    return build('youtube', 'v3', credentials=credentials)

def upload_video(youtube, file_path, title, description="", privacy="private"):
    body = {
        'snippet': {
            'title': title,
            'description': description,
            'categoryId': '22'
        },
        'status': {
            'privacyStatus': privacy,
            "selfDeclaredMadeForKids": False  # COPPA setting
        }
    }

    media = MediaFileUpload(file_path, chunksize=-1, resumable=True)

    print(f"\nUploading '{title}' to YouTube...")
    request = youtube.videos().insert(
        part="snippet,status",
        body=body,
        media_body=media
    )

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"Uploaded {int(status.progress() * 100)}%")

    print("Upload complete. Video ID:", response['id'])
    return response['id']

# --- Main Processing ---
def main():
    if not UPLOAD_DIR.exists() or not UPLOAD_DIR.is_dir():
        print(f"Error: '{UPLOAD_DIR}' folder does not exist.")
        sys.exit(1)

    video_files = [f for f in UPLOAD_DIR.iterdir() if f.suffix.lower() in ['.mp4', '.mov']]
    if not video_files:
        print(f"Error: No .mp4 or .mov files found in '{UPLOAD_DIR}'")
        sys.exit(1)

    COMPLETED_DIR.mkdir(exist_ok=True)

    # Load previous log
    uploaded_log = {}
    if LOG_FILE.exists():
        uploaded_log = json.loads(LOG_FILE.read_text())

    youtube = authenticate_youtube()

    for video_file in video_files:
        title = sanitize_filename(video_file.stem)
        if str(video_file) in uploaded_log:
            print(f"Already uploaded: {video_file.name}")
            continue

        try:
            privacy = 'unlisted'  # set to 'public', 'unlisted', or 'private'
            video_id = upload_video(youtube, video_file, title, description=f"Backup of {video_file.name}", privacy=privacy)
            uploaded_log[str(video_file)] = video_id

            # Save log
            LOG_FILE.write_text(json.dumps(uploaded_log, indent=2))

            # Move uploaded file to completed folder
            completed_path = COMPLETED_DIR / video_file.name
            video_file.rename(completed_path)
            print(f"Moved '{video_file.name}' to '{COMPLETED_DIR}'")

            time.sleep(2)  # avoid quota issues

        except Exception as e:
            print(f"Error uploading {video_file.name}: {e}")

if __name__ == "__main__":
    main()
EOL

# Create README.md
echo -e "${CYAN}📝 Creating README.html...${NC}"
cat << 'EOL' > README.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Google OAuth Setup for YouTube Uploader</title>
    <style>
        :root {
            --primary: #4285f4;
            --secondary: #ea4335;
            --accent: #fbbc05;
            --success: #34a853;
            --dark: #202124;
            --light: #f8f9fa;
            --gray: #dadce0;
            --text: #3c4043;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
        }
        
        body {
            background-color: var(--light);
            color: var(--text);
            line-height: 1.6;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
        }
        
        header {
            background: linear-gradient(135deg, var(--primary), #5c6bc0);
            color: white;
            padding: 40px 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .logo-container {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-bottom: 20px;
        }
        
        .logo {
            height: 60px;
            background: white;
            padding: 10px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .logo img {
            height: 100%;
        }
        
        h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .subtitle {
            font-size: 1.2rem;
            opacity: 0.9;
        }
        
        .step {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 25px;
            border-left: 4px solid var(--primary);
        }
        
        .step-number {
            display: inline-block;
            background: var(--primary);
            color: white;
            width: 30px;
            height: 30px;
            border-radius: 50%;
            text-align: center;
            line-height: 30px;
            margin-right: 10px;
            font-weight: bold;
        }
        
        .step-title {
            font-size: 1.3rem;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
        }
        
        .step-content {
            margin-left: 40px;
        }
        
        .step-content ol {
            margin-left: 20px;
            margin-bottom: 15px;
        }
        
        .step-content li {
            margin-bottom: 8px;
        }
        
        .code-block {
            background: var(--dark);
            color: white;
            padding: 15px;
            border-radius: 5px;
            font-family: monospace;
            overflow-x: auto;
            margin: 15px 0;
        }
        
        .warning {
            background: #fff8e1;
            border-left: 4px solid var(--accent);
            padding: 15px;
            margin: 15px 0;
            border-radius: 0 5px 5px 0;
        }
        
        .warning-title {
            font-weight: bold;
            color: #e65100;
            display: flex;
            align-items: center;
            margin-bottom: 5px;
        }
        
        .success {
            background: #e8f5e9;
            border-left: 4px solid var(--success);
            padding: 15px;
            margin: 15px 0;
            border-radius: 0 5px 5px 0;
        }
        
        .verification-section {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 30px;
            border: 2px solid var(--accent);
        }
        
        .verification-header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
            color: #e65100;
        }
        
        .verification-header h2 {
            margin-left: 10px;
        }
        
        footer {
            text-align: center;
            padding: 20px;
            margin-top: 40px;
            border-top: 1px solid var(--gray);
            color: #5f6368;
        }
        
        .note {
            background: #e3f2fd;
            border-left: 4px solid var(--primary);
            padding: 15px;
            margin: 15px 0;
            border-radius: 0 5px 5px 0;
        }
        
        .command {
            background: #f5f5f5;
            padding: 10px 15px;
            border-radius: 5px;
            font-family: monospace;
            margin: 10px 0;
            border-left: 3px solid var(--primary);
        }
        
        a {
            color: var(--primary);
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        .verification-substep {
            margin-left: 20px;
            margin-top: 15px;
        }
        
        .verification-substep h4 {
            margin-bottom: 10px;
            color: var(--primary);
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="logo-container">
                <div class="logo">
                    <img src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fvectorseek.com%2Fwp-content%2Fuploads%2F2022%2F02%2FYoutube-Studio-Logo-Vector.png&f=1&nofb=1&ipt=80be3d39cb1d5b60c662900aa6c978be7e7a7c80673e11cab1579bbcdad52949" alt="YouTube Studio">
                </div>
                <div class="logo">
                    <img src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fwww.pngmart.com%2Ffiles%2F23%2FGoogle-Cloud-Logo-PNG-HD.png&f=1&nofb=1&ipt=7c610b0145672b53d4254c60cadeb02909e1fc00ca8c0c28916594e9f8182218" alt="Google Cloud">
                </div>
            </div>
            <h1>Google OAuth Setup for YouTube Uploader</h1>
            <p class="subtitle">Complete guide to set up authentication for uploading videos to YouTube</p>
        </header>
        
        <div class="note">
            <p><strong>Note:</strong> This guide walks you through setting up Google OAuth for the YouTube Uploader script. Follow each step carefully to ensure proper authentication.</p>
        </div>
        
        <section class="verification-section">
            <div class="verification-header">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="#e65100">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
                </svg>
                <h2>Important: YouTube Channel Verification for Higher Upload Limits</h2>
            </div>
            <p>To upload more content and access advanced YouTube features, you need to verify your YouTube channel. This is separate from Google OAuth setup.</p>
            
            <div class="verification-substep">
                <h4>Access Intermediate Features (Phone Verification)</h4>
                <p>Complete phone verification to get access to intermediate features:</p>
                <ol>
                    <li>On a computer, sign in to <a href="https://studio.youtube.com" target="_blank">YouTube Studio</a></li>
                    <li>Click <strong>Settings</strong></li>
                    <li>Click <strong>Channel</strong></li>
                    <li>Click <strong>Feature eligibility</strong> → <strong>Intermediate features</strong> → <strong>VERIFY PHONE NUMBER</strong></li>
                    <li>Enter your phone number. YouTube will send a verification code by text or voice call</li>
                </ol>
            </div>
            
            <div class="verification-substep">
                <h4>Access Advanced Features</h4>
                <p>Advanced features include pinned comments and higher daily upload limits. To access these:</p>
                <ul>
                    <li>Complete phone verification (as above)</li>
                    <li>Build sufficient channel history OR verify identity using a valid ID or video</li>
                </ul>
                <div class="warning">
                    <div class="warning-title">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="#e65100">
                            <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
                        </svg>
                        Important Note
                    </div>
                    <p>ID and video verification isn't available to all creators. Not complying with YouTube's Community Guidelines delays feature eligibility. For creators with advanced feature access already, you can lose feature eligibility by not complying with Community Guidelines and not maintaining a positive channel history.</p>
                </div>
            </div>
            
            <p>For more information, visit: <a href="https://support.google.com/youtube/answer/9891124" target="_blank">YouTube Feature Eligibility</a></p>
        </section>
        
        <h2 style="margin-bottom: 20px;">Setup Steps</h2>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">1</span>
                <h3>Create a Google Cloud Project</h3>
            </div>
            <div class="step-content">
                <ol>
                    <li>Go to <a href="https://console.cloud.google.com/" target="_blank">Google Cloud Console</a></li>
                    <li>Sign in with your Google account</li>
                    <li>Click <strong>Select a project</strong> → <strong>New Project</strong></li>
                    <li>Name it (e.g., <code>YouTubeUploader</code>) and create</li>
                </ol>
            </div>
        </div>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">2</span>
                <h3>Enable YouTube Data API</h3>
            </div>
            <div class="step-content">
                <ol>
                    <li>In the Google Cloud Console, go to <strong>APIs & Services → Library</strong></li>
                    <li>Search for <strong>YouTube Data API v3</strong></li>
                    <li>Click <strong>Enable</strong></li>
                </ol>
            </div>
        </div>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">3</span>
                <h3>Configure OAuth Consent Screen</h3>
            </div>
            <div class="step-content">
                <ol>
                    <li>Go to <strong>APIs & Services → OAuth consent screen</strong></li>
                    <li>Choose <strong>External</strong> (unless for company domain)</li>
                    <li>Fill out app name, email, and developer contact info</li>
                    <li>Add required scopes: <code>https://www.googleapis.com/auth/youtube.upload</code></li>
                    <li>Save and continue</li>
                </ol>
            </div>
        </div>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">4</span>
                <h3>Add Test Users</h3>
            </div>
            <div class="step-content">
                <ol>
                    <li>Under <strong>Test users</strong>, click <strong>Add users</strong></li>
                    <li>Enter your Gmail account (e.g., <code>youremail@gmail.com</code>)</li>
                    <li>Save</li>
                </ol>
                <div class="warning">
                    <div class="warning-title">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="#e65100">
                            <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
                        </svg>
                        Important
                    </div>
                    <p>If you don't add yourself here, you'll see <strong>"Access blocked: app has not completed verification"</strong> when running the script.</p>
                </div>
            </div>
        </div>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">5</span>
                <h3>Create OAuth Credentials</h3>
            </div>
            <div class="step-content">
                <ol>
                    <li>Go to <strong>APIs & Services → Credentials</strong></li>
                    <li>Click <strong>Create Credentials → OAuth client ID</strong></li>
                    <li>Choose <strong>Desktop app</strong> as application type</li>
                    <li>Name it (e.g., <code>YouTubeUploaderDesktop</code>)</li>
                    <li>Click <strong>Download JSON</strong> → this is your <code>ytreuploader_client_secrets.json</code></li>
                </ol>
            </div>
        </div>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">6</span>
                <h3>Place the Secret File</h3>
            </div>
            <div class="step-content">
                <p>Move the downloaded JSON into your project folder:</p>
                <div class="command">
                    mv ~/Downloads/client_secret_*.json ytreuploader_client_secrets.json
                </div>
            </div>
        </div>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">7</span>
                <h3>How to Use the YouTube Uploader</h3>
            </div>
            <div class="step-content">
                <p>Once you've completed the OAuth setup, you can use the YouTube Uploader script:</p>
                <div class="code-block">
                    python3.10 -m venv myenv<br>
                    source myenv/bin/activate<br>
                    docker run --rm jrottenberg/ffmpeg:latest -version<br>
                    python3.10 -m pip install -r requirements.txt<br>
                    python3.10 ytreuploader.py ytreuploader_reupload.json
                </div>
                <div class="success">
                    <p><strong>✅ Success!</strong> Now when you run ytreuploader.py, a browser will open for authentication. Since you added your Gmail as a test user, you'll be able to grant access and the script will upload videos.</p>
                </div>
            </div>
        </div>
        
        <div class="step">
            <div class="step-title">
                <span class="step-number">8</span>
                <h3>Important: OAuth App Verification for Production</h3>
            </div>
            <div class="step-content">
                <p>For production use (uploading more than 100 videos or making your app available to others), you must complete the OAuth verification process.</p>
                
                <div class="verification-substep">
                    <h4>When Verification is Required</h4>
                    <ul>
                        <li>Publishing your app to other users</li>
                        <li>Accessing sensitive scopes (like YouTube upload)</li>
                        <li>Exceeding 100 user limit for unverified apps</li>
                        <li>Needing increased API quotas</li>
                    </ul>
                </div>
                
                <div class="verification-substep">
                    <h4>Verification Requirements</h4>
                    <ul>
                        <li>Provide a detailed explanation of your app's purpose</li>
                        <li>Submit a video showing your app in use</li>
                        <li>Verify your domain (if applicable)</li>
                        <li>Provide a privacy policy URL</li>
                        <li>Complete the OAuth consent screen configuration</li>
                    </ul>
                </div>
                
                <div class="verification-substep">
                    <h4>Submit for Verification</h4>
                    <ol>
                        <li>Go to Google Cloud Console → APIs & Services → OAuth consent screen</li>
                        <li>Click "Submit for verification"</li>
                        <li>Fill out the application form completely</li>
                        <li>Upload a demonstration video</li>
                        <li>Submit and wait for review (can take several weeks)</li>
                    </ol>
                </div>
                
                <div class="warning">
                    <div class="warning-title">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="#e65100">
                            <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
                        </svg>
                        Important Note About Verification
                    </div>
                    <p>For testing purposes, you can skip verification by adding yourself as a test user. However, for production use with multiple users, verification is mandatory.</p>
                </div>
            </div>
        </div>
        
        <footer>
            <p>Google OAuth Setup Guide for YouTube Uploader | This is a simplified guide for educational purposes</p>
        </footer>
    </div>
</body>
</html>
EOL

# Create README.md
echo -e "${CYAN}📝 Creating README.md...${NC}"
cat << 'EOL' > README.md
# 🔑 Google OAuth Setup for YouTube Uploader

To upload videos to YouTube, you need to set up a **Google Cloud Project** and obtain OAuth credentials.  
Follow these steps carefully:

---

HOW TO USE?

```bash
python3.10 -m venv myenv
source myenv/bin/activate
python3.10 -m pip install -r requirements.txt
python3.10 ytuploader.py
```

## 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Sign in with your Google account.
3. Click **Select a project** → **New Project**.
4. Name it (e.g., `YouTubeUploader`) and create.

---

## 2. Enable the YouTube Data API v3

1. In the Google Cloud Console, go to **APIs & Services → Library**.
2. Search for **YouTube Data API v3**.
3. Click **Enable**.

---

## 3. Configure the OAuth Consent Screen

1. In the left menu, go to **APIs & Services → OAuth consent screen**.
2. Choose **External** (unless this is for a company domain).
3. Fill out the app name, email, and developer contact info.
4. Save and continue until you reach **Test users**.

---

## 4. Add Yourself as a Test User

1. Under **Test users**, click **Add users**.
2. Enter the Gmail account you’ll use (e.g., `youremail@gmail.com`).
3. Save.

⚠️ If you don’t add yourself here, you’ll see **“Access blocked: app has not completed verification”** when running the script.

---

## 5. Create OAuth Credentials

1. Go to **APIs & Services → Credentials**.
2. Click **Create Credentials → OAuth client ID**.
3. Choose **Desktop app** as the application type.
4. Name it (e.g., `YouTubeUploaderDesktop`).
5. Click **Download JSON** → this file is your `ytreuploader_client_secrets.json`.

---

## 6. Place the Secret File

- Move the downloaded JSON into your project folder:
  ```bash
  mv ~/Downloads/client_secret_*.json ytreuploader_client_secrets.json
  ```

```

✅ Now when you run ytreuploader.py, a browser will open for authentication.
Since you added your Gmail as a test user, you’ll be able to grant access and the script will upload videos.



```
EOL

# Create LICENSE.md
cat <<EOL > LICENSE.md
MIT License

Copyright (c) $(date +%Y) Gabriel Majorsky

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EOL

echo -e "${CYAN}📦 Installing Python dependencies...${NC}"
# Create virtual environment in backend directory
python3.10 -m venv myenv
source myenv/bin/activate
python3.10 -m pip install -r requirements.txt
python3.10 ytuploader.py


echo -e "${GREEN}✅ Youtube Uploader template created in '$PROJECT_NAME'${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "0. You need to create a youtube channel and an OAUth login - README.md"
echo -e "1. ${CYAN}cd $PROJECT_NAME${NC}"
echo -e "2. Add MP4 videos to the /upload directory to automatically upload"
echo -e "3. ${CYAN}python ytuploader.py${NC} (to run your application)"
echo -e "4. Confirm Gmail login to start upload"
echo ""
echo -e "${GREEN}🚀 Your Python project is ready!${NC}"