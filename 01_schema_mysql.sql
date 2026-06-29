-- ============================================================
-- 도서 대여 시스템 - 스키마 생성 스크립트
-- DB: MySQL 8.x
-- ============================================================
-- 테이블 구조:
--   category (1) ──< book (N)       : 1:N 관계
--   member   (1) ──< rental (N)     : 1:N 관계
--   book     (1) ──< rental (N)     : 1:N 관계
--   member   (1) ──< review (N)     : 1:N 관계
--   book     (1) ──< review (N)     : 1:N 관계
-- ============================================================

-- DB 생성 및 선택
CREATE DATABASE IF NOT EXISTS library_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE library_db;

-- ============================================================
-- 1. category 테이블 (도서 카테고리)
-- ============================================================
CREATE TABLE IF NOT EXISTS category (
    category_id   INT           NOT NULL AUTO_INCREMENT,  -- PK (MySQL: AUTO_INCREMENT)
    name          VARCHAR(50)   NOT NULL UNIQUE,           -- 카테고리명 (NOT NULL + UNIQUE)
    description   VARCHAR(200),
    PRIMARY KEY (category_id)
);

-- ============================================================
-- 2. member 테이블 (도서관 회원)
-- ============================================================
CREATE TABLE IF NOT EXISTS member (
    member_id     INT           NOT NULL AUTO_INCREMENT,
    name          VARCHAR(50)   NOT NULL,                  -- 이름 (NOT NULL)
    email         VARCHAR(100)  NOT NULL UNIQUE,           -- 이메일 (UNIQUE)
    phone         VARCHAR(20),
    grade         VARCHAR(10)   NOT NULL DEFAULT 'NORMAL'  -- 회원 등급
                  CHECK (grade IN ('NORMAL', 'VIP')),
    joined_at     DATE          NOT NULL DEFAULT (CURDATE()),  -- 가입일 (MySQL: CURDATE())
    PRIMARY KEY (member_id)
);

-- ============================================================
-- 3. book 테이블 (도서)
-- ============================================================
CREATE TABLE IF NOT EXISTS book (
    book_id           INT           NOT NULL AUTO_INCREMENT,
    category_id       INT           NOT NULL,              -- FK → category
    title             VARCHAR(200)  NOT NULL,
    author            VARCHAR(100)  NOT NULL,
    publisher         VARCHAR(100),
    published_year    INT,
    total_copies      INT           NOT NULL DEFAULT 1
                      CHECK (total_copies >= 1),
    available_copies  INT           NOT NULL DEFAULT 1
                      CHECK (available_copies >= 0),
    PRIMARY KEY (book_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- ============================================================
-- 4. rental 테이블 (대여 기록)
-- ============================================================
CREATE TABLE IF NOT EXISTS rental (
    rental_id     INT           NOT NULL AUTO_INCREMENT,
    member_id     INT           NOT NULL,                  -- FK → member
    book_id       INT           NOT NULL,                  -- FK → book
    rented_at     DATE          NOT NULL DEFAULT (CURDATE()),
    due_date      DATE          NOT NULL,
    returned_at   DATE,                                    -- NULL이면 미반납
    status        VARCHAR(10)   NOT NULL DEFAULT 'RENTING'
                  CHECK (status IN ('RENTING', 'RETURNED', 'OVERDUE')),
    PRIMARY KEY (rental_id),
    FOREIGN KEY (member_id) REFERENCES member(member_id),
    FOREIGN KEY (book_id)   REFERENCES book(book_id)
);

-- ============================================================
-- 5. review 테이블 (도서 리뷰)
-- ============================================================
CREATE TABLE IF NOT EXISTS review (
    review_id     INT           NOT NULL AUTO_INCREMENT,
    member_id     INT           NOT NULL,                  -- FK → member
    book_id       INT           NOT NULL,                  -- FK → book
    rating        INT           NOT NULL
                  CHECK (rating BETWEEN 1 AND 5),
    content       TEXT,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id),
    UNIQUE KEY uq_member_book (member_id, book_id),        -- 동일 도서에 리뷰 1개만
    FOREIGN KEY (member_id) REFERENCES member(member_id),
    FOREIGN KEY (book_id)   REFERENCES book(book_id)
);
