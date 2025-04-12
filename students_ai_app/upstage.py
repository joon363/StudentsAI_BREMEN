from flask import Flask, request, jsonify
import os
import requests
from dotenv import load_dotenv

# .env에서 환경 변수 로드
load_dotenv()
API_KEY = os.getenv("UPSTAGE_API_KEY")
API_URL = "https://api.upstage.ai/v1/document/parse"

# Flask 앱 설정
app = Flask(__name__)

INPUT_DIR = "input_pdfs"
OUTPUT_DIR = "output_html"
os.makedirs(INPUT_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

def process_pdf(file_path):
    filename = os.path.basename(file_path)
    with open(file_path, 'rb') as f:
        files = {'file': (filename, f, 'application/pdf')}
        headers = {'Authorization': f'Bearer {API_KEY}'}

        response = requests.post(API_URL, headers=headers, files=files)

        if response.status_code == 200:
            html_output = response.json().get('html', '')
            html_filename = os.path.splitext(filename)[0] + '.html'
            output_path = os.path.join(OUTPUT_DIR, html_filename)

            with open(output_path, 'w', encoding='utf-8') as html_file:
                html_file.write(html_output)

            return {"filename": filename, "html_file": html_filename, "status": "success"}
        else:
            return {"filename": filename, "error": response.text, "status": "failed"}

@app.route('/upload-pdf', methods=['POST'])
def upload_pdf():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    save_path = os.path.join(INPUT_DIR, file.filename)
    file.save(save_path)

    result = process_pdf(save_path)
    return jsonify(result)

if __name__ == '__main__':
    app.run(debug=True, port=8000)
