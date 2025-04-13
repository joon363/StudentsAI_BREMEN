> 📢 **Notice:**  
> All teams submitting their project must create a `README.md` file following this guideline.  
> Please make sure to replace all placeholder texts (e.g., [Project Title], [Describe feature]) with actual content.

# 🛠️ UpDocs: AGI-based Document Feedback Assistant

### 📌 Overview
This project was developed as part of the AGI Agent Application Hackathon. It aims to solve the bottlenecks students, researchers, and new employees face in writing high-quality structured documents without sufficient feedback or reference materials.

### 🚀 Key Features
- ✅ **Automated Document Analysis**: Parses PDF documents using Upstage APIs to extract structure, text blocks, and visual elements.
- ✅ **Similarity-Based Feedback**: Matches uploaded documents with curated reference papers and compares structure, tone, and content.
- ✅ **Interactive Revision Assistant**: Uses Perplexity API to suggest improvements and map extracted summaries to original coordinates.

### 🖼️ Demo / Screenshots
![screenshot](./1.png) 
![screenshot](./2.png) 
![youtube](https://youtu.be/Eb8e1YXw-F4) 

### 🧩 Tech Stack
- **Frontend**: Flutter Web
- **Backend**: Flask
- **Database**: N/A (local JSON-based storage)
- **Others**: Upstage API, Perplexity API, BeautifulSoup, PDF.js

### 🏗️ Project Structure
📁 students_ai_app/ 
└── lib/ # Flutter frontend 

📁 students_ai_backend/
├── app.py # Flask server
└── perplexity_utils.py # Summary-to-coordinate mapping logic 

README.md 


### 🔧 Setup & Installation

```bash
# Clone the repository
git clone https://github.com/UpstageAI/cookbook/usecase/agi-agent-application/updocs.git

# Move to the frontend directory and run
cd frontend
flutter build web

# Move to the backend directory and run
cd backend
python -m venv venv
pip install -r requirements.txt
flask run
```

### 📁 Dataset & References
Dataset used: Public IEEE paper PDFs, internal sample drafts from team members

### References / Resources:
https://docs.upstage.ai
https://docs.perplexity.ai
https://mozilla.github.io/pdf.js/

### 🙌 Team Members
Name   Role   GitHub
Junhyeok Park   Frontend   @joon363
Jaehyun Choi    AI, Backend   @minhjih
Minkyu Park     Backend   @jadestar
Hyein You       Designer, PM @mehyein

### ⏰ Development Period
2025.04.12 - 2025.04.13 (28h)

### 📄 License
This project is licensed under the MIT license.
See the LICENSE file for more details.

### 💬 Additional Notes
Let AI read, compare, and improve your writing — so you can focus on your ideas, not formatting.