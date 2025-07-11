# 🛠️ UpDocs: AGI-based Document Feedback Assistant
Welcome to UpDocs, an AI-powered document assistant created by Team Bremen as part of the Upstage track at the STUDENTS@AI SEOUL Hackathon.

### 📌 Overview
UpDocs helps users — especially students, researchers, and new hires — improve their documents with minimal manual effort. By uploading a draft, users receive structured, insightful feedback based on high-quality references, all powered by Upstage APIs and AGI reasoning.

### 🖼️ Demo
([youtube](https://www.youtube.com/watch?v=Eb8e1YXw-F4)) 

## 🧩 Problem Statement
In academic labs and corporate environments, newcomers face challenges in writing structured, high-quality documents. Common struggles include:

- Finding and analyzing well-written reference documents
- Understanding structure, tone, and logical flow
- Receiving timely feedback from mentors or seniors

> 🧪 A global survey (n=24) revealed:
> - 50%+ of respondents struggle to compare and structure documents
> - 80%+ spend over 50% of their time iterating on writing tasks



## 💡 Our Solution
UpDocs tackles these challenges by:

1. Parsing uploaded PDFs using Upstage APIs
2. Extracting structure, content, and style info
3. Matching similar reference documents
4. Comparing tone, structure, and flow
5. Generating visual feedback and improvement suggestions
6. Supporting interactive chatbot revision (via Perplexity)


## 🎯 MVP Focus: Academic Papers
Our MVP targets **IEEE-style academic papers**, because:
- They follow strict formats
- Public datasets are accessible
- They pose high writing complexity


## 🎯 MVP Focus: Academic Papers
Our MVP targets **IEEE-style academic papers**, because:
- They follow strict formats
- Public datasets are accessible
- They pose high writing complexity


## 🛠 Architecture
**User Flow**
1. Upload paper (PDF)
2. Upstage APIs: `ocr`, `parsing`, `info extraction`, `chat bot`
3. Match similar papers that are accepted by target journal
4. Compare and annotate suggestions
5. Ask/Revise through Perplexity chatbot


## 🔥 Why It Matters
UpDocs empowers users by:
- Reducing time spent on formatting
- Improving writing quality
- Accelerating feedback cycles
- Supporting independent learning


## 🛠 Post-Hackathon Plans
We aim to:
- Expand beyond academic papers
- Support corporate reports, resumes, and more
- Build a full-scale intelligent document agent


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

## 👥 About Team Bremen
***We are Team Bremen*** that composed of three undergraduate students from POSTECH and one graduate student from Seoul National University.
We have participated in and won various hackathons, while also working on individual and team-based projects.

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
