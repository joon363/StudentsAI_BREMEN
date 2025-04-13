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
![screenshot](./screenshot.png)  
[Optional demo video link: e.g., YouTube]

### 🧩 Tech Stack
- **Frontend**: Flutter Web
- **Backend**: Flask
- **Database**: N/A (local JSON-based storage)
- **Others**: Upstage API, Perplexity API, BeautifulSoup, PDF.js

### 🏗️ Project Structure

📁 updocs/ ├── lib/ # Flutter frontend ├── templates/ # HTML viewer (PDF-like) ├── static/ # Uploaded PDFs ├── data/ # Extracted JSON data ├── app.py # Flask server ├── perplexity_utils.py # Summary-to-coordinate mapping logic └── README.md


### 🔧 Setup & Installation

```bash
# Clone the repository
git clone https://github.com/UpstageAI/cookbook/usecase/agi-agent-application/updocs.git

# Move to the frontend directory and run
cd students_ai_app

# Move to the backend directory and run
cd students_ai_app
pip install -r requirements.txt
python app.py run
```

📁 Dataset & References
Dataset used: Public IEEE paper PDFs, internal sample drafts from team members

References / Resources:
https://docs.upstage.ai
https://docs.perplexity.ai
https://mozilla.github.io/pdf.js/

🙌 Team Members


⏰ Development Period
Last updated: 2025-04-13

📄 License
This project is licensed under the MIT license.
See the LICENSE file for more details.

💬 Additional Notes
Let AI read, compare, and improve your writing — so you can focus on your ideas, not formatting.

🙌 Team Members
Name   Role   GitHub
Junhyeok Park   Frontend   @joon363
Jaehyun Choi    AI, Backend   @minhjih
Minkyu Park     Backend   @jadestar
Hyein You       Designer, PM @mehyein

⏰ Development Period
Last updated: 2025-04-13

📄 License
This project is licensed under the MIT license.
See the LICENSE file for more details.

💬 Additional Notes
Let AI read, compare, and improve your writing — so you can focus on your ideas, not formatting.
=======
# 🧠 UpDocs: AGI-based Document Feedback Assistant

Welcome to **UpDocs**, an AI-powered document assistant created by **Team Bremen** as part of the Upstage track at the STUDENTS@AI SEOUL Hackathon.

## 🚀 Overview
UpDocs helps users — especially students, researchers, and new hires — improve their documents with minimal manual effort. 
By uploading a draft, users receive structured, insightful feedback based on high-quality references, all powered by Upstage APIs and AGI reasoning.

---

## 🧩 Problem Statement
In academic labs and corporate environments, newcomers face challenges in writing structured, high-quality documents. Common struggles include:

- Finding and analyzing well-written reference documents
- Understanding structure, tone, and logical flow
- Receiving timely feedback from mentors or seniors

> 🧪 A global survey (n=24) revealed:
> - 50%+ of respondents struggle to compare and structure documents
> - 80%+ spend over 50% of their time iterating on writing tasks

---

## 💡 Our Solution
UpDocs tackles these challenges by:

1. Parsing uploaded PDFs using Upstage APIs
2. Extracting structure, content, and style info
3. Matching similar reference documents
4. Comparing tone, structure, and flow
5. Generating visual feedback and improvement suggestions
6. Supporting interactive chatbot revision (via Perplexity)

---

## 🎯 MVP Focus: Academic Papers
Our MVP targets **IEEE-style academic papers**, because:
- They follow strict formats
- Public datasets are accessible
- They pose high writing complexity

---

## 🛠 Architecture
**User Flow**
1. Upload paper (PDF)
2. Upstage APIs: `ocr`, `parsing`, `info extraction`, `chat bot`
3. Match similar papers that are accepted by target journal
4. Compare and annotate suggestions
5. Ask/Revise through Perplexity chatbot

---

## 🔥 Why It Matters
UpDocs empowers users by:
- Reducing time spent on formatting
- Improving writing quality
- Accelerating feedback cycles
- Supporting independent learning

---

## 🛠 Post-Hackathon Plans
We aim to:
- Expand beyond academic papers
- Support corporate reports, resumes, and more
- Build a full-scale intelligent document agent

---

## 👥 About Team Bremen
***We are Team Bremen*** that composed of three undergraduate students from POSTECH and one graduate student from Seoul National University.
We have participated in and won various hackathons, while also working on individual and team-based projects.

---

## 🙏 Thank You
> "Let AI read, compare, and improve your writing — so you can focus on your ideas, not formatting."

We’re happy to answer any questions!

---
