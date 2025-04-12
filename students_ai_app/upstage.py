from flask import Flask, request, jsonify
import os
import requests
from dotenv import load_dotenv
from flask_cors import CORS

load_dotenv()
API_KEY = os.getenv("UPSTAGE_API_KEY")
API_URL = "https://api.upstage.ai/v1/document-digitization"

app = Flask(__name__)
CORS(app, resources={r"/upload-pdf": {"origins": "*"}}, supports_credentials=True)

INPUT_DIR = "input_pdfs"
OUTPUT_DIR = "output_html"
os.makedirs(INPUT_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

def process_pdf(file_path):
    filename = os.path.basename(file_path)
    with open(file_path, 'rb') as f:
        files = {
            'document': (filename, f, 'application/pdf')  #필드명 주의!
        }
        data = {
            'ocr': 'force',
            'base64_encoding': "['table']",
            'model': 'document-parse'
        }
        headers = {'Authorization': f'Bearer {API_KEY}'}

        response = requests.post("https://api.upstage.ai/v1/document-digitization",
                                 headers=headers, files=files, data=data)

        print(f"📬 응답 코드: {response.status_code}")
        print(f"📬 응답 내용: {response.text}")

        if response.status_code == 200:
            result = response.json()
            # 결과가 어떻게 오느냐에 따라 저장 방식 다름 (예시: HTML로 저장)
            html_output = result.get('html', '') or str(result)

            html_filename = os.path.splitext(filename)[0] + '.html'
            output_path = os.path.join(OUTPUT_DIR, html_filename)

            with open(output_path, 'w', encoding='utf-8') as html_file:
                html_file.write(html_output)

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

#라우트 추가: 업로드 및 변환
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

#서버 실행
if __name__ == '__main__':
    app.run(debug=True, port=8000, host='0.0.0.0')
