-- 1. 데이터베이스 생성 및 선택
CREATE DATABASE IF NOT EXISTS homini_db;
USE homini_db;

-- 2. 사용자 테이블 (회원가입 기능 보완)
CREATE TABLE IF NOT EXISTS users (
                                     user_id VARCHAR(50) PRIMARY KEY,          -- 사용자 고유 ID (예: 이메일 또는 UUID)
    password VARCHAR(255) NOT NULL,           -- 해싱된 비밀번호
    sex VARCHAR(10) DEFAULT 'NONE', -- 성별
    email VARCHAR(100) UNIQUE NOT NULL,       -- 이메일
    selected_persona VARCHAR(20) DEFAULT 'Beginner', -- 피드백 페르소나
    role VARCHAR(20) DEFAULT 'ROLE_USER',     -- 스프링 시큐리티 연동용 권한
-- [온보딩 데이터] --
    height VARCHAR(10),                       -- 키 (예: "175")
    weight VARCHAR(10),                       -- 몸무게 (예: "70")
    workout_level VARCHAR(20),                -- 운동 수준 (STARTER, BEGINNER 등)
    selected_persona VARCHAR(20) DEFAULT 'BEGINNER', -- 피드백 페르소나
    onboarding_completed BOOLEAN DEFAULT FALSE, -- 온보딩 완료 여부

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- 3. 기준 영상 메타데이터 테이블
CREATE TABLE IF NOT EXISTS reference_videos (
                                                video_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                                user_id VARCHAR(50) NOT NULL,
    title VARCHAR(100) NOT NULL,
    source_type VARCHAR(20) NOT NULL,          -- DEFAULT, YOUTUBE, LOCAL
    video_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_video_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
    );

-- 4. 운동 세션 기록 테이블
CREATE TABLE IF NOT EXISTS workout_sessions (
                                                session_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                                user_id VARCHAR(50) NOT NULL,
    video_id BIGINT NOT NULL,
    exercise_type VARCHAR(50) NOT NULL,       -- SQUAT, PUSH_UP 등
    target_reps INT NOT NULL,
    completed_reps INT DEFAULT 0,
    is_valid BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_session_video FOREIGN KEY (video_id) REFERENCES reference_videos(video_id) ON DELETE CASCADE
    );

-- 5. AI 상세 분석 데이터 테이블 (1:1 관계)
CREATE TABLE IF NOT EXISTS ai_analysis_reports (
                                                   analysis_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                                   session_id BIGINT UNIQUE NOT NULL,        -- 1:1 관계를 위한 UNIQUE 설정
                                                   avg_sync_score INT DEFAULT 0,
                                                   is_failure_reached BOOLEAN DEFAULT FALSE,
                                                   worst_joint VARCHAR(50),
    sync_timeline JSON,                       -- 1초 단위 싱크로율 배열
    error_events JSON,                        -- 오답노트 메타데이터
    gpt_safety_report TEXT,                   -- GPT 분석 코칭 리포트
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_report_session FOREIGN KEY (session_id) REFERENCES workout_sessions(session_id) ON DELETE CASCADE
    );

-- 6. 사용자 세부 설정 테이블
CREATE TABLE IF NOT EXISTS user_settings (
                                             user_id VARCHAR(50) PRIMARY KEY,
    is_recording_enabled BOOLEAN DEFAULT TRUE,    -- F1-2: 영상 동시 녹화 여부
    preferred_persona VARCHAR(20) DEFAULT 'HELLINI', -- F9: 선호 페르소나
    last_calibration_date TIMESTAMP,              -- 마지막 체형 측정일
    CONSTRAINT fk_settings_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
    );

-- 7. 체형 캘리브레이션 데이터
CREATE TABLE IF NOT EXISTS user_calibrations (
                                                 calibration_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                                 user_id VARCHAR(50) NOT NULL,
    shoulder_width_ratio FLOAT,                   -- 기준값 1에 대비한 비율들
    arm_length_ratio FLOAT,
    leg_length_ratio FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_calib_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
    );

-- 8. 안전 및 실패 지점 로그
CREATE TABLE IF NOT EXISTS safety_logs (
                                           log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                           session_id BIGINT NOT NULL,
                                           issue_type VARCHAR(50),                       -- LIGHTING, BODY_NOT_FOUND, FAILURE_DETECTED
    description TEXT,                             -- "조도 낮음", "실패 지점 도달로 중단 권고"
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_safety_session FOREIGN KEY (session_id) REFERENCES workout_sessions(session_id) ON DELETE CASCADE
    );