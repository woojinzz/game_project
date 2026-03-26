# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Simulation Game은 Godot Engine 4.6을 사용한 AI 시뮬레이션 프로젝트입니다. 20마리의 자율 AI 에이전트가 유틸리티 AI를 통해 의사결정을 하며, 자원 경쟁과 사회적 상호작용을 시뮬레이션합니다.

## Running the Project

**게임 실행:**
- Godot Engine에서 프로젝트를 열고 F5 키 또는 재생 버튼으로 실행
- 메인 씬: `res://scenes/Main.tscn`

**개발 환경:**
- Godot Engine 4.6 이상 필요
- GDScript 언어 사용
- 테스트/빌드 명령어는 Godot 에디터 내에서 실행

## Architecture

### 핵심 시스템

**GameManager (scripts/GameManager.gd):**
- 전체 시뮬레이션 제어 및 관리
- 타일맵 생성, 에이전트/자원 스폰, 충돌 감지
- 20마리 에이전트와 30개 자원을 50x30 타일맵에 배치
- 실시간 통계 업데이트 담당

**Agent 시스템 (scripts/Agent.gd):**
- `CharacterBody2D` 기반 AI 에이전트
- 3가지 핵심 수치: hunger, energy, trust (0-100)
- 5가지 행동 타입: WANDER, SEEK_FOOD, REST, TRADE, FLEE
- 1초마다 유틸리티 AI로 행동 결정

**Utility AI (scripts/UtilityAI.gd):**
- `RefCounted` 기반 유틸리티 계산 엔진
- 각 행동의 utility 값을 상황에 따라 계산
- hunger/energy/trust 수치를 입력으로 최적 행동 선택

**Resource 시스템 (scripts/Resource.gd):**
- `Area2D` 기반 게임 자원
- 10초 후 자동 리스폰
- 에이전트 충돌 감지로 소비 처리

### 중요한 명명 규칙

- `var GameResource = preload("res://scripts/Resource.gd")` 사용 (Godot의 네이티브 Resource 클래스 충돌 방지)
- `@onready` 어노테이션 사용 (Godot 4 문법)
- `load()` 함수로 런타임 스크립트 로딩 (`preload()` 대신)

### UI 구조

**StatsPanel (scripts/StatsPanel.gd):**
- 왼쪽 패널에 실시간 시뮬레이션 통계 표시
- 평균 수치, 자원 개수, 충돌/교역 횟수 추적
- 0.5초 간격으로 업데이트

### 시뮬레이션 로직

**의사결정 흐름:**
1. 각 에이전트가 1초마다 현재 상태 평가
2. UtilityAI가 5가지 행동의 utility 점수 계산
3. 가장 높은 점수의 행동 선택 및 실행
4. 행동에 따른 수치 변화 (hunger/energy/trust)

**상호작용:**
- 자원 소비시 hunger 감소, energy/trust 증가
- 교역시 상호 hunger 감소, trust 증가 (trust > 30 조건)
- 충돌시 trust 감소
- 에이전트 밀도가 높을 때 자동 충돌 발생

## Godot 4 호환성

이 프로젝트는 Godot 4.6에 최적화되어 있으며, 다음 사항들이 적용되어 있습니다:
- `CharacterBody2D`의 내장 `velocity` 속성 사용
- 신호 연결: `signal.connect(method)` 방식
- 씬 인스턴스화: `instantiate()` 메서드
- 수학 함수: `randf_range()`, `snapped()` 등