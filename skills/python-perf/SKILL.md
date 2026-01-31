---
name: python-perf
description: Python 코드 작성 시 성능 최적화를 위한 가이드. 메모리 효율성, 연산 속도, JSON 직렬화, 비동기 처리 등의 성능 수치와 권장사항 제공. Use this skill when (1) Python 클래스나 데이터 구조 설계, (2) 문자열 처리 및 리스트 연산 최적화, (3) JSON 직렬화 라이브러리 선택, (4) 비동기 vs 동기 처리 결정, (5) 성능 크리티컬한 코드 작성 시.
---

# Python Performance Optimization Guide

## Quick Reference

| 항목 | 권장사항 | 이유 |
|------|----------|------|
| 클래스 | `__slots__` 사용 | 메모리 50% 이상 절감 |
| 리스트 생성 | 컴프리헨션 사용 | for문 대비 26% 빠름 |
| 조회 연산 | dict/set 사용 | list 대비 수백 배 빠름 |
| 문자열 포맷 | f-string 사용 | 가독성 + 성능 균형 |
| JSON 처리 | orjson 사용 | 표준 json 대비 8배 빠름 |
| 비동기 | 병렬성 필요 시에만 | 오버헤드 ~1000배 |
| 예외 | 제어 흐름으로 사용 금지 | 발생 시 6배 느림 |

## Memory Optimization

### `__slots__` 사용

```python
class User:
    __slots__ = ['name', 'email', 'age', 'role', 'active']

    def __init__(self, name, email, age, role, active):
        self.name = name
        self.email = email
        self.age = age
        self.role = role
        self.active = active
```

- 일반 클래스(속성 5개): 694B → `__slots__`: 212B
- 1,000개 인스턴스: 165KB → 79KB (52% 절감)

### 사용 시점
- 대량의 인스턴스 생성 시
- 메모리 제약이 있는 환경
- 속성이 고정된 데이터 클래스

## Operation Speed

### 리스트 컴프리헨션

```python
result = [x * 2 for x in range(1000)]

result = []
for x in range(1000):
    result.append(x * 2)
```

- 컴프리헨션: 9.45µs
- for문: 11.9µs (26% 느림)

### 조회 연산

```python
lookup_set = set(items)
if item in lookup_set:
    ...

lookup_dict = {item: True for item in items}
if item in lookup_dict:
    ...
```

- dict/set 조회: O(1)
- list 조회: O(n) - 수백 배 느림

## String Formatting

| 방식 | 속도 | 권장 |
|------|------|------|
| `+` 연결 | 39.1ns | 단순 연결만 |
| f-string | 64.9ns | **권장** |
| `%` 포맷 | 89.8ns | 레거시 |
| `.format()` | 103ns | 사용 지양 |

```python
name = "World"
greeting = f"Hello, {name}!"
```

## JSON Serialization

| 라이브러리 | 직렬화 | 역직렬화 | 비고 |
|------------|--------|----------|------|
| orjson | 310ns | 839ns | **최고 성능** |
| msgspec | 445ns | - | 빠르고 타입 안전 |
| ujson | 1.64µs | - | 중간 성능 |
| json (표준) | 2.65µs | - | 기본값 |

```python
import orjson

data = {"key": "value", "numbers": [1, 2, 3]}
serialized = orjson.dumps(data)
deserialized = orjson.loads(serialized)
```

### Pydantic 모델
- `model_dump_json()`: 1.54µs
- `model_validate_json()`: 2.99µs

## Async Considerations

### 오버헤드 비교

| 연산 | 시간 |
|------|------|
| 동기 함수 호출 | ~20ns |
| 코루틴 생성 | 47ns |
| `asyncio.sleep(0)` | 39.4µs |
| `gather(10 coroutines)` | 55µs |

**비동기는 동기 대비 약 1,000배 오버헤드**

### 사용 시점
- I/O 바운드 작업 (네트워크, 파일)
- 동시 요청 처리 필요 시
- CPU 바운드 작업에는 사용 금지

## Exception Handling

```python
if condition:
    do_something()

try:
    do_something()
except SomeException:
    pass
```

- try/except (예외 없음): 21.5ns
- 예외 발생 시: 139ns (6배 느림)

**예외는 실제 예외 상황에만 사용, 제어 흐름으로 사용 금지**

## Detailed Benchmarks

→ See [references/benchmarks.md](references/benchmarks.md) for complete benchmark data
