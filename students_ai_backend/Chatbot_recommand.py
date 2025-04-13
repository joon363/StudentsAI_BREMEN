import pandas as pd
import pymysql
import json
import os
from openai import OpenAI
 

UPSTAGE_API_KEY = os.getenv("UPSTAGE_API_KEY")

# 1. 프롬프트에서 조건 추출
def extract_conditions(prompt):
    system_prompt = f"""
    당신은 논문 추천 조건을 추출하는 시스템입니다.
    가능한 키는 min_year, max_year, journal_name, keywords, min_citation입니다.
    JSON 형식으로만 응답하세요.
    아래 프롬프트에 대해 위 키들을 지정하세요. 만약 명시되어 있지 않다면 넣지 않아도 됩니다.

    프롬프트: "{prompt}"
    """
    client = OpenAI(
        api_key=UPSTAGE_API_KEY,
        base_url="https://api.upstage.ai/v1"
    )
    
    stream = client.chat.completions.create(
        model="solar-pro",
        messages=[
            {
                "role": "user",
                "content": system_prompt
            }
        ],
        stream=True,
    )
    
    full_response = ""

    for chunk in stream:
        if chunk.choices[0].delta.content is not None:
            full_response += chunk.choices[0].delta.content
    return(full_response)


# 2. 논문 후보 필터링
def find_top_papers(prompt):
    conn = pymysql.connect(host='localhost', user='root', password='1234', db='papers')
    conditions = extract_conditions(prompt)
    parsed = json.loads(conditions)
    query = "SELECT * FROM papers WHERE 1=1"
    if "journal_name" in parsed:
        query += f" AND publications = '{parsed['journal_name']}'"
    if "min_citation" in parsed:
        query += f" AND citations >= {parsed['min_citation']}"
        
    df = pd.read_sql(query, conn)

    # 'date' 컬럼 기준으로 내림차순 정렬 (오름차순 정렬하려면 ascending=True로 설정)
    df_sorted = df.sort_values(by='date', ascending=False)

    # 상위 3개 데이터 반환
    return df_sorted.head(3).to_dict(orient="records")
