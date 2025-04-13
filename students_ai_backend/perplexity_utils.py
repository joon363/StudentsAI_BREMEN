# 필요한 라이브러리 임포트
import requests
import os
import json
from dotenv import load_dotenv

# .env 파일에서 API 키 불러오기
load_dotenv()
API_KEY = os.getenv("PERPLEXITY_API_KEY")
API_URL = "https://api.perplexity.ai/chat/completions"

# 데이터 파일 경로 설정
DATA_DIR = "data"
TEXT_TO_ID_PATH = os.path.join(DATA_DIR, "text_to_id.json")         # 원문 문장 → ID
ID_TO_COORD_PATH = os.path.join(DATA_DIR, "id_to_coord.json")       # ID → 좌표 정보
SUMMARY_LIST_PATH = os.path.join(DATA_DIR, "summary_list.json")     # 요약 문장 리스트
SUMMARY_COORD_PATH = os.path.join(DATA_DIR, "summary_to_coords.json")  # 결과 저장 위치

# API 요청 헤더
headers = {
    "Authorization": f"Bearer {PERPLEXITY_API_KEY}",
    "Content-Type": "application/json"
}

# Perplexity API를 호출하여 요약 문장에 해당하는 원문 ID를 추정하고, 해당 ID의 좌표를 찾아 저장
def run_perplexity():
    # 사전 정리된 JSON 파일들 로딩
    with open(TEXT_TO_ID_PATH, "r", encoding="utf-8") as f:
        text_to_id = json.load(f)
    with open(ID_TO_COORD_PATH, "r", encoding="utf-8") as f:
        id_to_coord = json.load(f)
    with open(SUMMARY_LIST_PATH, "r", encoding="utf-8") as f:
        summary_list = json.load(f)

    # LLM 프롬프트 구성
    prompt = f"""
    다음은 원문 문장과 해당 문장의 ID입니다:
    {text_to_id}

    아래는 요약된 문장과 그 요약된 문장에서 비롯된 코멘트들의 리스트입니다.
    이 코멘트나 요약된 문장이 위 원문 중 어떤 문장을 요약한 것인지 유추해서, 해당 원문의 ID를 찾아주세요.

    출력은 다음과 같은 JSON 형식으로 해주세요:
    **영어로 대답해 주세요.**

    {{
      "코멘트 1": ID,
      "코멘트 2": ID,
      ...
    }}

    코멘트들:
    {summary_list}
    """

    # Perplexity API에 요청 전송
    payload = {
        "model": "sonar",  # 사용할 모델 이름
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3
    }

    response = requests.post(PERP_API_URL, headers=headers, json=payload)

    try:
        # 응답에서 JSON 형태 결과 텍스트만 추출
        full_text = response.json()["choices"][0]["message"]["content"]
        print("✅ Perplexity 응답:\n", full_text[:300], "...")

        # 응답 텍스트에서 JSON 코드 블록만 추출
        start = full_text.find("```json")
        end = full_text.find("```", start + 7)

        if start != -1 and end != -1:
            json_str = full_text[start + 7:end].strip()
        else:
            raise ValueError("JSON 코드 블록을 찾을 수 없습니다.")

        matched = json.loads(json_str)

        # ID를 바탕으로 해당 문장의 좌표 및 페이지 정보 추출
        summary_to_coords = {}
        for sentence, id_val in matched.items():
            id_str = str(id_val)
            if id_str in id_to_coord:
                summary_to_coords[sentence] = {
                    "page": id_to_coord[id_str]["page"],
                    "coordinates": id_to_coord[id_str]["coordinates"]
                }

        # 결과 저장
        with open(SUMMARY_COORD_PATH, "w", encoding="utf-8") as f:
            json.dump(summary_to_coords, f, ensure_ascii=False, indent=2)

        print(f"✅ 저장 완료: {SUMMARY_COORD_PATH}")
        return True, summary_to_coords

    except Exception as e:
        # 예외 발생 시 로깅 및 에러 메시지 반환
        print("❌ JSON 파싱 실패:", e)
        print("⚠️ 응답 내용:\n", response.text)
        return False, {"error": str(e)}
