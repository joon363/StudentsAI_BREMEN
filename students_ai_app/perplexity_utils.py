import requests
import os
import json
from dotenv import load_dotenv
from flask import Flask, jsonify

load_dotenv()

API_KEY = os.getenv("PERPLEXITY_API_KEY")
API_URL = "https://api.perplexity.ai/chat/completions"

DATA_DIR = "data"
TEXT_TO_ID_PATH = os.path.join(DATA_DIR, "text_to_id.json")
ID_TO_COORD_PATH = os.path.join(DATA_DIR, "id_to_coord.json")
SUMMARY_LIST_PATH = os.path.join(DATA_DIR, "summary_list.json")
SUMMARY_COORD_PATH = os.path.join(DATA_DIR, "summary_to_coords.json")

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

def run_perplexity():
    with open(TEXT_TO_ID_PATH, "r", encoding="utf-8") as f:
        text_to_id = json.load(f)

    with open(ID_TO_COORD_PATH, "r", encoding="utf-8") as f:
        id_to_coord = json.load(f)

    with open(SUMMARY_LIST_PATH, "r", encoding="utf-8") as f:
        summary_list = json.load(f)

    prompt = f"""
    다음은 원문 문장과 해당 문장의 ID입니다:
    {text_to_id}

    아래는 요약된 문장들의 리스트입니다.
    이 요약된 문장들이 위 원문 중 어떤 문장을 요약한 것인지 유추해서, 해당 원문의 ID를 찾아주세요.

    출력은 다음과 같은 JSON 형식으로 해주세요:

    {{
      "요약된 문장 1": ID,
      "요약된 문장 2": ID,
      ...
    }}

    요약 문장들:
    {summary_list}
    """

    payload = {
        "model": "sonar",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3
    }

    response = requests.post(API_URL, headers=headers, json=payload)
    print("🔁 Status Code:", response.status_code)

    try:
        full_text = response.json()["choices"][0]["message"]["content"]

        print("✅ Perplexity 응답:\n", full_text[:300], "...")

        start = full_text.find("```json")
        end = full_text.find("```", start + 7)

        if start != -1 and end != -1:
            json_str = full_text[start + 7:end].strip()
        else:
            raise ValueError("JSON 코드 블록을 찾을 수 없습니다.")

        matched = json.loads(json_str)

        summary_to_coords = {}

        for sentence, id_val in matched.items():
            id_str = str(id_val)
            if id_str in id_to_coord:
                summary_to_coords[sentence] = {
                    "page": id_to_coord[id_str]["page"],
                    "coordinates": id_to_coord[id_str]["coordinates"]
                }

        with open(SUMMARY_COORD_PATH, "w", encoding="utf-8") as f:
            json.dump(summary_to_coords, f, ensure_ascii=False, indent=2)

        print(f"✅ 저장 완료: {SUMMARY_COORD_PATH}")
        return True, summary_to_coords

    except Exception as e:
        print("❌ JSON 파싱 실패:", e)
        print("⚠️ 응답 내용:\n", response.text)
        return False, {"error": str(e)}


# Flask 라우트로 등록
app = Flask(__name__)

@app.route("/run-perplexity", methods=["GET"])
def run():
    success, result = run_perplexity()
    return jsonify(result), 200 if success else 500
