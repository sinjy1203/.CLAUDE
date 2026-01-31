# Python Performance Benchmarks

## Table of Contents
1. [Memory Usage](#memory-usage)
2. [Basic Operations](#basic-operations)
3. [String Formatting](#string-formatting)
4. [List Operations](#list-operations)
5. [JSON Serialization](#json-serialization)
6. [Function Calls](#function-calls)
7. [Async Operations](#async-operations)

---

## Memory Usage

### Class Instance Memory

| 타입 | 메모리 |
|------|--------|
| 일반 클래스 (속성 5개) | 694B |
| `__slots__` 클래스 | 212B |

### Bulk Instance Memory (1,000개)

| 타입 | 메모리 |
|------|--------|
| 일반 클래스 | 165.2KB |
| `__slots__` | 79.1KB |

**절감율: 52%**

---

## Basic Operations

### Arithmetic Operations

| 연산 | 시간 |
|------|------|
| 정수 덧셈 | 19ns |
| 실수 덧셈 | 18.4ns |
| 정수 곱셈 | 19.4ns |

---

## String Formatting

| 방식 | 시간 | 배율 |
|------|------|------|
| 문자열 연결 (`+`) | 39.1ns | 1.0x |
| f-string | 64.9ns | 1.7x |
| `%` 포맷 | 89.8ns | 2.3x |
| `.format()` | 103ns | 2.6x |

**권장**: f-string (가독성과 성능의 균형)

---

## List Operations

### Append vs Comprehension

| 방식 | 시간 (1,000개) | 배율 |
|------|----------------|------|
| 리스트 컴프리헨션 | 9.45µs | 1.0x |
| for + append | 11.9µs | 1.26x |

### Single Append

| 연산 | 시간 |
|------|------|
| `list.append()` | 28.7ns |

**권장**: 리스트 컴프리헨션 (26% 빠름)

---

## JSON Serialization

### Serialization (Dumps)

| 라이브러리 | 시간 | 배율 |
|------------|------|------|
| orjson | 310ns | 1.0x |
| msgspec | 445ns | 1.4x |
| ujson | 1.64µs | 5.3x |
| json (표준) | 2.65µs | 8.5x |

### Deserialization (Loads)

| 라이브러리 | 시간 |
|------------|------|
| orjson | 839ns |

### Pydantic Model Operations

| 연산 | 시간 |
|------|------|
| `model_dump_json()` | 1.54µs |
| `model_validate_json()` | 2.99µs |

**권장**: orjson (표준 json 대비 8배 빠름)

---

## Function Calls

### Call Overhead

| 타입 | 시간 |
|------|------|
| 빈 함수 호출 | 22.4ns |
| 메서드 호출 | 23.3ns |
| lambda 호출 | 19.7ns |

### Exception Handling

| 상황 | 시간 | 배율 |
|------|------|------|
| try/except (예외 없음) | 21.5ns | 1.0x |
| 예외 발생 시 | 139ns | 6.5x |

**주의**: 예외를 제어 흐름으로 사용하지 말 것

---

## Async Operations

### Overhead Comparison

| 연산 | 시간 | 배율 (vs 동기) |
|------|------|----------------|
| 동기 함수 호출 | ~20ns | 1.0x |
| 코루틴 생성 | 47ns | 2.4x |
| `run_until_complete` | 27.6µs | 1,380x |
| `asyncio.sleep(0)` | 39.4µs | 1,970x |
| `gather(10 coroutines)` | 55µs | 2,750x |

**주의**: 비동기는 동기 대비 약 1,000배 오버헤드. I/O 바운드 작업에만 사용할 것.

---

## Key Takeaways

1. **메모리**: `__slots__`로 50% 이상 절감
2. **리스트**: 컴프리헨션이 for문보다 26% 빠름
3. **조회**: dict/set는 O(1), list는 O(n)
4. **문자열**: f-string 권장
5. **JSON**: orjson이 표준 대비 8배 빠름
6. **비동기**: 오버헤드 크므로 신중하게 사용
7. **예외**: 제어 흐름으로 사용 금지
