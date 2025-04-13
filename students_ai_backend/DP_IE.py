# Flask 및 필요 라이브러리 임포트
import os
import requests
import json
from dotenv import load_dotenv
from openai import OpenAI
import base64
from bs4 import BeautifulSoup

# .env 파일에서 API Key 로드
load_dotenv()
API_KEY = os.getenv("UPSTAGE_API_KEY")
API_URL = "https://api.upstage.ai/v1/document-digitization" 

# 디렉토리 경로 설정
PAPER_DIR = "papers"
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
