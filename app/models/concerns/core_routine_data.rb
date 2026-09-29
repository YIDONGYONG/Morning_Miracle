# app/models/core_routine_goal.rb
class CoreRoutineGoal
    # 4대 핵심 루틴 키
    ROUTINE_KEYS = %i[exercise meditation reading planning].freeze
  
    # 1~8단계 레벨별 목표 및 스텝 콘셉트 정의
    LEVEL_MAP = {
      1 => {
        concept: "스몰 스타트 (진입 장벽 0)",
        targets: {
          exercise: "현관 앞에 10초 서있기",
          meditation: "심호흡 1회",
          reading: "책 1페이지 읽기",
          planning: "오늘 할 일 1개 적기"
        }
      },
      2 => {
        concept: "행동 개시 (몸 일으키기)",
        targets: {
          exercise: "가벼운 제자리걸음 1분",
          meditation: "명상 2분",
          reading: "독서 3분",
          planning: "메모장에서 오늘 예정 확인하기"
        }
      },
      3 => {
        concept: "습관 고정 (실행의 정착)",
        targets: {
          exercise: "스트레칭 3분",
          meditation: "명상 5분",
          reading: "독서 5분",
          planning: "오늘 할 일 2개 적기"
        }
      },
      4 => {
        concept: "시간 확장 (초급 단계)",
        targets: {
          exercise: "조깅 5분",
          meditation: "명상 8분",
          reading: "독서 8분",
          planning: "간단한 우선순위 정하기"
        }
      },
      5 => {
        concept: "리듬 형성 (중급 단계)",
        targets: {
          exercise: "조깅 8분",
          meditation: "명상 10분",
          reading: "독서 10분",
          planning: "주요 스케줄 시간 설정"
        }
      },
      6 => {
        concept: "몰입 유도 (상급 단계)",
        targets: {
          exercise: "조깅 10분",
          meditation: "명상 13분",
          reading: "독서 13분",
          planning: "하루 스케줄 틀 만들기"
        }
      },
      7 => {
        concept: "최종 정비 (완성 단계)",
        targets: {
          exercise: "조깅 12분",
          meditation: "명상 16분",
          reading: "독서 16분",
          planning: "상세 타임 스케줄 배분"
        }
      },
      8 => {
        concept: "완성기 (아침 1시간 정복)",
        targets: {
          exercise: "조깅 15분 (햇볕 쬐기)",
          meditation: "명상 20분 (최고의 상태)",
          reading: "독서 20분 (깊은 몰입)",
          planning: "하루 스케줄 완성 (5분)"
        }
      }
    }.freeze
  
    # 특정 레벨의 콘셉트 및 목표 반환
    def self.for_level(level)
      LEVEL_MAP[level] || LEVEL_MAP[1]
    end
  
    # 특정 레벨의 콘셉트 문구
    def self.concept_for(level)
      for_level(level)[:concept]
    end
  
    # 특정 레벨의 4대 루틴 목표 맵
    def self.targets_for(level)
      for_level(level)[:targets]
    end
  end