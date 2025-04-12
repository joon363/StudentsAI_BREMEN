from flask import Flask, request, jsonify, render_template
import os
import requests
import json
from dotenv import load_dotenv
from flask_cors import CORS

load_dotenv()
API_KEY = os.getenv("UPSTAGE_API_KEY")
API_URL = "https://api.upstage.ai/v1/document-digitization"

app = Flask(__name__, template_folder="templates")
CORS(app, resources={r"/upload-pdf": {"origins": "*"}}, supports_credentials=True)

INPUT_DIR = "input_pdfs"
OUTPUT_DIR = "output_html"
PREVIEW_DATA_DIR = "output_data"
os.makedirs(INPUT_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(PREVIEW_DATA_DIR, exist_ok=True)

def process_pdf(file_path):
    filename = os.path.basename(file_path)
    basename = os.path.splitext(filename)[0]
    with open(file_path, 'rb') as f:
        files = {
            'document': (filename, f, 'application/pdf')
        }
        data = {
            'ocr': 'force',
            'base64_encoding': "['table']",
            'model': 'document-parse'
        }
        headers = {'Authorization': f'Bearer {API_KEY}'}

        response = requests.post(API_URL, headers=headers, files=files, data=data)

        print(f"📬 응답 코드: {response.status_code}")
        print(f"📬 응답 내용: {response.text}")

        if response.status_code == 200:
            result = response.json()
            html_output = result.get("content", {}).get("html", "") or str(result)
            html_filename = basename + '.html'
            output_path = os.path.join(OUTPUT_DIR, html_filename)

            with open(output_path, 'w', encoding='utf-8') as html_file:
                html_file.write(html_output)

            # ✅ preview 파일을 고유 이름으로 저장
            preview_data = {
                "elements": result.get("elements", []),
                "tables": result.get("tables", [])
            }
            preview_path = os.path.join(PREVIEW_DATA_DIR, f'{basename}.json')
            with open(preview_path, 'w', encoding='utf-8') as json_file:
                json.dump(preview_data, json_file, ensure_ascii=False, indent=2)

            return {
                "filename": filename,
                "html_file": html_filename,
                "status": "success"
            }
        else:
            return {
                "filename": filename,
                "error": response.text,
                "status": "failed"
            }

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

# ✅ HTML Viewer 페이지
@app.route('/view-html/<filename>')
def view_html(filename):
    return render_template('viewer.html')  # templates/viewer.html

# ✅ JSON 데이터 반환
@app.route('/data/<filename>.json')
def get_json_data(filename):
    path = os.path.join(PREVIEW_DATA_DIR, f'{filename}.json')
    if not os.path.exists(path):
        return jsonify({"error": "file not found"}), 404
    with open(path, 'r', encoding='utf-8') as f:
        return jsonify(json.load(f))

if __name__ == '__main__':
    app.run(debug=True, port=8000, host='0.0.0.0')
