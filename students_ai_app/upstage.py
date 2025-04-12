from flask import Flask, request, jsonify, render_template
import os
import requests
import json
from dotenv import load_dotenv
from flask_cors import CORS
from openai import OpenAI
import base64

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

def is_pdf_file(filename):
    return filename.lower().endswith('.pdf')

def encode_pdf_to_base64(pdf_path):
    with open(pdf_path, 'rb') as pdf_file:
        pdf_bytes = pdf_file.read()
        base64_data = base64.b64encode(pdf_bytes).decode('utf-8')
        return base64_data

def process_universal_extraction(file_path, schema):
    filename = os.path.basename(file_path)
    basename = os.path.splitext(filename)[0]
    
    # OpenAI 클라이언트 초기화
    client = OpenAI(
        api_key=API_KEY,
        base_url="https://api.upstage.ai/v1/information-extraction"
    )
    
    # PDF를 base64로 인코딩
    base64_data = encode_pdf_to_base64(file_path)
    
    try:
        # Information Extraction 요청
        extraction_response = client.chat.completions.create(
            model="information-extract",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:application/pdf;base64,{base64_data}"
                            }
                        }
                    ]
                }
            ],
            response_format={
                "type": "json_schema",
                "json_schema": schema
            }
        )
        
        # ChatCompletion 객체에서 필요한 데이터 추출
        response_data = {
            "choices": [
                {
                    "message": {
                        "content": choice.message.content,
                        "role": choice.message.role
                    }
                }
                for choice in extraction_response.choices
            ]
        }
        
        # 결과 저장
        output_path = os.path.join(PREVIEW_DATA_DIR, f'{basename}_universal.json')
        with open(output_path, 'w', encoding='utf-8') as json_file:
            json.dump(response_data, json_file, ensure_ascii=False, indent=2)
            
        return {
            "filename": filename,
            "output_file": f'{basename}_universal.json',
            "status": "success",
            "result": response_data
        }
        
    except Exception as e:
        return {
            "filename": filename,
            "error": str(e),
            "status": "failed"
        }

@app.route('/universal-extraction', methods=['POST'])
def universal_extraction():
    if 'file' not in request.files:
        return jsonify({"error": "파일이 없습니다"}), 400
        
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "선택된 파일이 없습니다"}), 400
    
    if not is_pdf_file(file.filename):
        return jsonify({"error": "PDF 파일만 업로드 가능합니다"}), 400
    
    # 스키마 검증 추가
    if 'schema' not in request.form:
        return jsonify({"error": "스키마가 필요합니다"}), 400
        
    try:
        schema = json.loads(request.form['schema'])
    except json.JSONDecodeError:
        return jsonify({"error": "잘못된 스키마 형식입니다"}), 400
    
    save_path = os.path.join(INPUT_DIR, file.filename)
    file.save(save_path)
    
    result = process_universal_extraction(save_path, schema)  # schema 파라미터 추가
    print(result)
    return jsonify(result)

@app.route('/universal-data/<filename>')
def get_universal_data(filename):
    path = os.path.join(PREVIEW_DATA_DIR, filename)
    if not os.path.exists(path):
        return jsonify({"error": "file not found"}), 404
    with open(path, 'r', encoding='utf-8') as f:
        return jsonify(json.load(f))

if __name__ == '__main__':
    app.run(debug=True, port=8000, host='0.0.0.0')
