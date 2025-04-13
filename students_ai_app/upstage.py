# Flask 및 필요 라이브러리 임포트
from flask import Flask, request, jsonify, render_template, send_from_directory
import os
import requests
import json
from dotenv import load_dotenv
from flask_cors import CORS
from openai import OpenAI
import base64
from bs4 import BeautifulSoup
from flask_cors import cross_origin

# .env 파일에서 API Key 로드
load_dotenv()
API_KEY = os.getenv("UPSTAGE_API_KEY")
PERPLEXITY_API_KEY = 1

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
    
    # 파일 이름에서 확장자 제거
    basename = os.path.splitext(file.filename)[0]
    # universal json 파일 경로 확인
    universal_json_path = os.path.join(PREVIEW_DATA_DIR, f'{basename}_universal.json')
    
    # 이미 존재하는 universal json 파일이 있는지 확인
    if os.path.exists(universal_json_path):
        # 이미 존재하는 universal json 파일 사용
        with open(universal_json_path, 'r', encoding='utf-8') as f:
            result = {
                "filename": file.filename,
                "output_file": f'{basename}_universal.json',
                "status": "success",
                "result": json.load(f)
            }
    else:
        print("없으면 파일 저장하고 추출")
        # 없으면 파일 저장하고 새로 추출
        save_path = os.path.join(INPUT_DIR, file.filename)
        file.save(save_path)
        result = process_universal_extraction(save_path, schema)  # schema 파라미터 추가
    # 참조 논문 처리
    reference_results = []
    
    # 참조 논문 파일 경로
    reference_files = [
        os.path.join(INPUT_DIR, '3.pdf'),
        os.path.join(INPUT_DIR, '4.pdf'),
        os.path.join(INPUT_DIR, '5.pdf')
    ]
    
    # 각 참조 논문에 대해 동일한 스키마로 추출 진행
    for i, ref_file in enumerate(reference_files, 1):
        if os.path.exists(ref_file):
            # 파일 이름에서 확장자 제거
            ref_basename = os.path.splitext(os.path.basename(ref_file))[0]
            # universal json 파일 경로 확인
            universal_json_path = os.path.join(PREVIEW_DATA_DIR, f'{ref_basename}_universal.json')
            
            if os.path.exists(universal_json_path):
                # 이미 존재하는 universal json 파일 사용
                with open(universal_json_path, 'r', encoding='utf-8') as f:
                    ref_result = {
                        "filename": os.path.basename(ref_file),
                        "output_file": f'{ref_basename}_universal.json',
                        "status": "success",
                        "result": json.load(f)
                    }
            else:
                # 없으면 새로 추출
                ref_result = process_universal_extraction(ref_file, schema)
                
            ref_result['reference_id'] = i
            reference_results.append(ref_result)
        else:
            print(f"참조 논문 파일이 존재하지 않습니다: {ref_file}")
    
    print(result)
    # 참조 논문 결과는 별도로 반환
    # Perplexity API 호출을 위한 코드
    try:
        if not PERPLEXITY_API_KEY:
            print("Perplexity API 키가 설정되지 않았습니다.")
        else:
            # 메인 논문과 참조 논문 데이터 준비
            main_paper_data = json.loads(result['result']['choices'][0]['message']['content'])
            reference_papers_data = []
            
            for ref in reference_results:
                if 'result' in ref and 'choices' in ref['result'] and len(ref['result']['choices']) > 0:
                    ref_content = json.loads(ref['result']['choices'][0]['message']['content'])
                    reference_papers_data.append({
                        "reference_id": ref.get('reference_id', 0),
                        "content": ref_content
                    })
            
            # Perplexity API 요청 데이터 구성 - JSON 형식으로 응답 요청
            prompt = f"""
            다음은 학술 논문과 참조 논문들의 분석 결과입니다:
            
            메인 논문:
            {json.dumps(main_paper_data, indent=2, ensure_ascii=False)}
            
            참조 논문들:
            {json.dumps(reference_papers_data, indent=2, ensure_ascii=False)}
            
            참조논문들은 이미 저널에 게제된 검증된 논문들입니다. 다른 소스는 참고하지 말고, 해당 논문들을 레퍼런스로 하여 메인 논문의 허점을 찾고 개선 방향을 찾아주세요.
            위 데이터를 바탕으로 다음 사항을 분석해주세요. 반드시 JSON 형식으로 응답해주세요:
            {{
              "subsections_comments": [메인 논문의 각 섹션에 대한 참조 논문들에 비해 부족한 점이나 괜찮은 점 코멘트 배열],
              "figures_comments": [메인 논문의 그림에 대한 참조 논문들에 비해 부족한 점이나 괜찮은 점 코멘트 배열],
              "equations_comments": [메인 논문의 수식에 대한 참조 논문들에 비해 부족한 점이나 괜찮은 점 코멘트 배열],
              "methods_comparison": [메인 논문의 방법들의 참신성을 기존의 논문들에 없던 새로운 내용들을 비교하며 코멘트 배열],
              "metrics_comparison": [메인 논문과 참조 논문들의 평가 지표의 양이나 정확도 비교 코멘트 배열],
              "academic_improvements": [메인 논문의 비학술적 표현 수정 제안 배열],
              "key_differences": [메인 논문과 참조 논문들 간의 주요 차이점을 포함한 배열],
              "accept_probability": [잘쓴 논문의 accept rate 기준이 50의 accept rate 가진다는 것을 토대로 계산, 일단 50에서 감점 방식으로 subsections_comments, figures_comments, equations_comments, methods_comparison, metrics_comparison, academic_improvements, key_differences 에서 마이너한(사소하더라도) critic 있을 때마다 4씩 감점, 메이저(내용과 관련된 심각한 결함) critic있으면 10씩 감점]
              "accept_probability_metrics": [어떤 메이저한 크리틱과 어떤 마이너한 크리틱이있었는지 보여주면서 이유 설명해주기.]
            }}
            
            각 배열의 항목은 문자열이며, 영어로 작성해야 합니다. 다른 형식이나 추가 설명 없이 오직 위 JSON 형식으로만 응답해주세요. 
            """
            
            # Perplexity API 호출
            headers = {
                "Authorization": f"Bearer {PERPLEXITY_API_KEY}",
                "Content-Type": "application/json"
            }
            
            api_data = {
                "model": "sonar",
                "messages": [{"role": "user", "content": prompt}]
            }
            
            perplexity_response = requests.post(
                "https://api.perplexity.ai/chat/completions",
                headers=headers,
                json=api_data
            )
            
            if perplexity_response.status_code == 200:
                perplexity_result = perplexity_response.json()
                
                # JSON 응답 파싱 시도
                try:
                    content = perplexity_result['choices'][0]['message']['content']
                    # JSON 문자열 추출 (만약 추가 텍스트가 있는 경우 처리)
                    json_str = content
                    if "```json" in content:
                        json_str = content.split("```json")[1].split("```")[0].strip()
                    elif "```" in content:
                        json_str = content.split("```")[1].split("```")[0].strip()
                    
                    # JSON 파싱
                    analysis_data = json.loads(json_str)
                    print(analysis_data)
                    # 원본 데이터와 분석 결과를 함께 저장
                    combined_result = {
                        "original_data": main_paper_data,
                        "analysis": analysis_data
                    }
                    
                    # 결과에 추가
                    print(combined_result)
                    print("✅ Perplexity API 호출 및 JSON 파싱 성공")
                except Exception as json_error:
                    print(f"❌ Perplexity 응답 JSON 파싱 실패: {str(json_error)}")
                    # 원본 응답 저장
                    result['perplexity_raw_response'] = perplexity_result
                    result['perplexity_error'] = str(json_error)
            else:
                print(f"❌ Perplexity API 호출 실패: {perplexity_response.text}")
                result['perplexity_error'] = perplexity_response.text
    except Exception as e:
        print(f"❌ Perplexity API 처리 중 오류 발생: {str(e)}")
        result['perplexity_error'] = str(e)
    return jsonify({
        "result": result,
        "reference_results": reference_results
    })

@app.route('/universal-data/<filename>')
def get_universal_data(filename):
    path = os.path.join(PREVIEW_DATA_DIR, filename)
    if not os.path.exists(path):
        return jsonify({"error": "file not found"}), 404
    with open(path, 'r', encoding='utf-8') as f:
        return jsonify(json.load(f))

# Flask 앱 실행 (플러터로부터 호출될 때만 실행)
if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "run":
        app.run(debug=True, port=8000, host='0.0.0.0')
