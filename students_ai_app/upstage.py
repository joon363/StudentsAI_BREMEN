# Flask 및 필요 라이브러리 임포트
from flask import Flask, request, jsonify, render_template, send_from_directory
import os
import requests
import json
from dotenv import load_dotenv
from flask_cors import CORS
from bs4 import BeautifulSoup
from flask_cors import cross_origin

# .env 파일에서 API Key 로드
load_dotenv()
API_KEY = os.getenv("UPSTAGE_API_KEY")
API_URL = "https://api.upstage.ai/v1/document-digitization"

# Flask 앱 초기화 및 CORS 설정
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

# 디렉토리 경로 설정
INPUT_DIR = "input_pdfs"
OUTPUT_DIR = "output_html"
PREVIEW_DATA_DIR = "output_data"
STATIC_PDF_DIR = os.path.join("static", "pdfs")
HIGHLIGHT_DIR = "data"

# 필요한 디렉토리들이 존재하지 않으면 생성
os.makedirs(INPUT_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(PREVIEW_DATA_DIR, exist_ok=True)
os.makedirs(STATIC_PDF_DIR, exist_ok=True)
os.makedirs(HIGHLIGHT_DIR, exist_ok=True)

# elements 항목으로부터 문장과 ID 매핑, ID와 좌표 매핑을 추출
def extract_text_and_id_maps(elements):
    text_to_id = {}
    id_to_coord = {}
    for el in elements:
        html = el.get("content", {}).get("html", "")
        if not html:
            continue
        soup = BeautifulSoup(html, "html.parser")
        text = soup.get_text(separator=' ', strip=True)
        if not text:
            continue
        eid = el.get("id")
        text_to_id[text] = eid
        id_to_coord[str(eid)] = {
            "page": el.get("page"),
            "coordinates": el.get("coordinates", [])
        }
    return text_to_id, id_to_coord

# PDF 파일을 Upstage API를 통해 분석하고, 결과를 정리 및 저장
def process_pdf(file_path):
    filename = os.path.basename(file_path)
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

        if response.status_code == 200:
            result = response.json()

            # 결과에서 필요한 매핑 정보 추출
            text_to_id, id_to_coord = extract_text_and_id_maps(result.get("elements", []))

            # JSON 파일로 저장
            with open(os.path.join(HIGHLIGHT_DIR, "text_to_id.json"), 'w', encoding='utf-8') as f:
                json.dump(text_to_id, f, ensure_ascii=False, indent=2)

            with open(os.path.join(HIGHLIGHT_DIR, "id_to_coord.json"), 'w', encoding='utf-8') as f:
                json.dump(id_to_coord, f, ensure_ascii=False, indent=2)

            # 업로드된 PDF를 static 폴더로 복사
            target_pdf_path = os.path.join(STATIC_PDF_DIR, filename)
            if not os.path.exists(target_pdf_path):
                with open(file_path, 'rb') as src, open(target_pdf_path, 'wb') as dst:
                    dst.write(src.read())

            return {
                "filename": filename,
                "status": "success"
            }
        else:
            return {
                "filename": filename,
                "error": response.text,
                "status": "failed"
            }

# PDF 업로드 라우트 (POST 요청)
@app.route("/upload-pdf", methods=['POST'])
@cross_origin()
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

# HTML 뷰어 페이지 렌더링
@app.route("/view-html/<filename>")
def view_html(filename):
    return render_template("viewer.html", filename=filename)

# 정적 PDF 파일 서빙
@app.route("/pdfs/<path:filename>")
def serve_pdf(filename):
    return send_from_directory(STATIC_PDF_DIR, filename)

# 추출 데이터(JSON) 반환
@app.route("/data/<filename>.json")
def serve_data(filename):
    path = os.path.join(PREVIEW_DATA_DIR, f"{filename}.json")
    if not os.path.exists(path):
        return jsonify({"elements": {}, "tables": []})
    with open(path, "r", encoding="utf-8") as f:
        return jsonify(json.load(f))

# Flask 앱 실행 (플러터로부터 호출될 때만 실행)
if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "run":
        app.run(debug=True, port=8000, host='0.0.0.0')
