USE library_db;

-- ============================================================
-- 보너스 1. 같은 요구를 JOIN vs 서브쿼리로 풀기
-- 요구사항: "리뷰를 한 번이라도 작성한 회원의 이름과 이메일을 조회하라"
-- ============================================================

-- 방법 A: INNER JOIN
-- member와 review를 조인해서 review가 존재하는 회원만 추출
-- DISTINCT로 중복 제거 (한 회원이 여러 리뷰를 써도 1번만 나옴)
SELECT DISTINCT
    m.member_id,
    m.name   AS 회원명,
    m.email  AS 이메일,
    m.grade  AS 등급
FROM member m
INNER JOIN review rv ON m.member_id = rv.member_id
ORDER BY m.member_id;

-- 방법 B: 서브쿼리 (IN)
-- review 테이블에서 member_id 목록을 뽑아서, 그 안에 있는 회원만 조회
SELECT
    m.member_id,
    m.name   AS 회원명,
    m.email  AS 이메일,
    m.grade  AS 등급
FROM member m
WHERE m.member_id IN (
    SELECT DISTINCT member_id FROM review
)
ORDER BY m.member_id;



-- ============================================================
-- 보너스 2. FK 에러 깨뜨려보기
-- ============================================================

-- 케이스 A: 존재하지 않는 member_id(999)로 rental INSERT 시도
INSERT INTO rental (member_id, book_id, rented_at, due_date, status)
VALUES (999, 1, '2024-05-01', '2024-05-15', 'RENTING');


-- 케이스 B: 존재하지 않는 book_id(999)로 rental INSERT 시도
INSERT INTO rental (member_id, book_id, rented_at, due_date, status)
VALUES (1, 999, '2024-05-01', '2024-05-15', 'RENTING');


-- 케이스 C: 부모 테이블(book) 행을 자식(rental)이 참조 중인데 삭제 시도
DELETE FROM book WHERE book_id = 1;



-- C 케이스 올바른 순서 예시:
-- 1단계: 자식 먼저 삭제
DELETE FROM rental WHERE book_id = 1;
-- 2단계: 그 다음 부모 삭제 가능
DELETE FROM book WHERE book_id = 1;

-- 실습 후 데이터 복구 (삭제한 book_id=1, rental 복원)
INSERT INTO book (book_id, category_id, title, author, publisher, published_year, total_copies, available_copies)
VALUES (1, 1, '82년생 김지영', '조남주', '민음사', 2016, 3, 2);

INSERT INTO rental (member_id, book_id, rented_at, due_date, returned_at, status)
VALUES (1, 1, '2024-01-05', '2024-01-19', '2024-01-18', 'RETURNED');


-- ============================================================
-- 보너스 3. 미니 리포트 - 핵심 지표 3개
-- ============================================================

-- ============================================================
-- 지표 1. 월별 대여 건수 추이
-- 목적: 도서관 이용량이 월마다 어떻게 변화하는지 파악
--       대여가 많은 달에 도서 확충, 이벤트 기획 등에 활용
-- ============================================================
SELECT
    DATE_FORMAT(rented_at, '%Y-%m')                         AS 월,
    COUNT(*)                                                AS 총대여건수,
    SUM(CASE WHEN status = 'RETURNED' THEN 1 ELSE 0 END)   AS 반납완료,
    SUM(CASE WHEN status = 'RENTING'  THEN 1 ELSE 0 END)   AS 대출중,
    SUM(CASE WHEN status = 'OVERDUE'  THEN 1 ELSE 0 END)   AS 연체,
    ROUND(
        SUM(CASE WHEN status = 'RETURNED' THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 1
    )                                                       AS 반납완료율
FROM rental
GROUP BY DATE_FORMAT(rented_at, '%Y-%m')
ORDER BY 월 ASC;

-- ============================================================
-- 지표 2. 가장 인기 있는 도서 TOP 5
-- 목적: 대여 횟수 + 평균 별점을 함께 보여 인기도와 만족도를 동시에 파악
--       재구매, 추가 확보, 추천 도서 선정에 활용
-- ============================================================
SELECT
    b.title                         AS 도서명,
    b.author                        AS 저자,
    c.name                          AS 카테고리,
    COUNT(DISTINCT r.rental_id)     AS 총대여횟수,
    COUNT(DISTINCT rv.review_id)    AS 리뷰수,
    ROUND(AVG(rv.rating), 2)        AS 평균별점,
    b.total_copies                  AS 보유권수
FROM book b
JOIN category c         ON b.book_id     = c.category_id   -- 카테고리 연결
LEFT JOIN rental r      ON b.book_id     = r.book_id        -- 대여 이력 (없어도 포함)
LEFT JOIN review rv     ON b.book_id     = rv.book_id       -- 리뷰 (없어도 포함)
GROUP BY b.book_id, b.title, b.author, c.name, b.total_copies
ORDER BY 총대여횟수 DESC, 평균별점 DESC
LIMIT 5;

-- ============================================================
-- 지표 3. 연체 경험이 있는 회원 목록 및 연체율
-- 목적: 연체가 잦은 회원을 파악해 알림 발송, 등급 조정, 대출 제한 등에 활용
-- ============================================================
SELECT
    m.member_id,
    m.name                                              AS 회원명,
    m.grade                                             AS 등급,
    COUNT(r.rental_id)                                  AS 총대여횟수,
    SUM(CASE WHEN r.status = 'OVERDUE' THEN 1 ELSE 0 END)  AS 연체횟수,
    ROUND(
        SUM(CASE WHEN r.status = 'OVERDUE' THEN 1 ELSE 0 END)
        / COUNT(r.rental_id) * 100, 1
    )                                                   AS 연체율,
    MAX(CASE WHEN r.status = 'OVERDUE' THEN r.due_date END) AS 마지막연체일
FROM member m
JOIN rental r ON m.member_id = r.member_id
GROUP BY m.member_id, m.name, m.grade
HAVING SUM(CASE WHEN r.status = 'OVERDUE' THEN 1 ELSE 0 END) > 0
ORDER BY 연체율 DESC, 연체횟수 DESC;
