-- ============================================================
-- 도서 대여 시스템 - 핵심 쿼리 15개
-- DB: MySQL 8.x
-- ============================================================

USE library_db;

-- ============================================================
-- [기본 조회] Q01. 현재 대출 중인 도서 목록 (최신 대여일 순)
-- WHERE + ORDER BY
-- ============================================================
SELECT
    r.rental_id,
    m.name         AS 회원명,
    b.title        AS 도서명,
    r.rented_at    AS 대여일,
    r.due_date     AS 반납예정일,
    r.status       AS 상태
FROM rental r
JOIN member m ON r.member_id = m.member_id
JOIN book   b ON r.book_id   = b.book_id
WHERE r.status IN ('RENTING', 'OVERDUE')
ORDER BY r.rented_at DESC;

-- ============================================================
-- [기본 조회] Q02. VIP 회원 목록 (가입일 오름차순)
-- WHERE + ORDER BY
-- ============================================================
SELECT
    member_id,
    name,
    email,
    joined_at AS 가입일,
    grade     AS 등급
FROM member
WHERE grade = 'VIP'
ORDER BY joined_at ASC;

-- ============================================================
-- [기본 조회] Q03. 카테고리별 도서 목록 (소설)
-- WHERE + ORDER BY
-- ============================================================
SELECT
    b.book_id,
    b.title,
    b.author,
    b.published_year     AS 출판연도,
    b.total_copies       AS 총보유수,
    b.available_copies   AS 대출가능수
FROM book b
JOIN category c ON b.category_id = c.category_id
WHERE c.name = '소설'
ORDER BY b.published_year DESC;

-- ============================================================
-- [기본 조회] Q04. 별점 4점 이상 리뷰 상위 5건 (최신 등록순)
-- WHERE + ORDER BY + LIMIT
-- ============================================================
SELECT
    rv.review_id,
    m.name        AS 작성자,
    b.title       AS 도서명,
    rv.rating     AS 별점,
    rv.content    AS 리뷰내용,
    rv.created_at AS 작성일시
FROM review rv
JOIN member m ON rv.member_id = m.member_id
JOIN book   b ON rv.book_id   = b.book_id
WHERE rv.rating >= 4
ORDER BY rv.created_at DESC
LIMIT 5;

-- ============================================================
-- [조인] Q05. 전체 대여 이력 (회원명 + 도서명 + 카테고리) INNER JOIN 3중
-- ============================================================
SELECT
    r.rental_id,
    m.name       AS 회원명,
    m.grade      AS 회원등급,
    b.title      AS 도서명,
    c.name       AS 카테고리,
    r.rented_at  AS 대여일,
    IFNULL(r.returned_at, '미반납') AS 반납일,  -- MySQL: IFNULL()
    r.status     AS 상태
FROM rental r
INNER JOIN member   m ON r.member_id   = m.member_id
INNER JOIN book     b ON r.book_id     = b.book_id
INNER JOIN category c ON b.category_id = c.category_id
ORDER BY r.rented_at DESC;

-- ============================================================
-- [조인] Q06. 연체 중인 회원과 연체일수 INNER JOIN
-- MySQL: DATEDIFF() 함수 사용
-- ============================================================
SELECT
    m.name                                    AS 회원명,
    m.email                                   AS 이메일,
    m.phone                                   AS 연락처,
    b.title                                   AS 연체도서,
    r.rented_at                               AS 대여일,
    r.due_date                                AS 반납예정일,
    DATEDIFF(CURDATE(), r.due_date)           AS 연체일수  -- MySQL 전용: DATEDIFF()
FROM rental r
INNER JOIN member m ON r.member_id = m.member_id
INNER JOIN book   b ON r.book_id   = b.book_id
WHERE r.status = 'OVERDUE'
ORDER BY 연체일수 DESC;

-- ============================================================
-- [조인] Q07. 도서별 평균 별점 (리뷰 없는 도서도 포함) LEFT JOIN
-- ============================================================
SELECT
    b.book_id,
    b.title                        AS 도서명,
    b.author                       AS 저자,
    c.name                         AS 카테고리,
    COUNT(rv.review_id)            AS 리뷰수,
    ROUND(AVG(rv.rating), 2)       AS 평균별점
FROM book b
LEFT JOIN review    rv ON b.book_id     = rv.book_id
INNER JOIN category c  ON b.category_id = c.category_id
GROUP BY b.book_id, b.title, b.author, c.name
ORDER BY 평균별점 DESC;

-- ============================================================
-- [조인] Q08. 회원별 총 대여횟수 (대여 0회 회원 포함) LEFT JOIN
-- ============================================================
SELECT
    m.member_id,
    m.name                   AS 회원명,
    m.grade                  AS 등급,
    COUNT(r.rental_id)       AS 총대여횟수
FROM member m
LEFT JOIN rental r ON m.member_id = r.member_id
GROUP BY m.member_id, m.name, m.grade
ORDER BY 총대여횟수 DESC;

-- ============================================================
-- [집계] Q09. 카테고리별 보유 도서 수 및 대출 통계 COUNT + SUM + AVG
-- ============================================================
SELECT
    c.name                           AS 카테고리,
    COUNT(b.book_id)                 AS 도서수,
    SUM(b.total_copies)              AS 총보유권수,
    SUM(b.available_copies)          AS 총대출가능,
    ROUND(AVG(b.available_copies),1) AS 평균대출가능수
FROM category c
LEFT JOIN book b ON c.category_id = b.category_id
GROUP BY c.category_id, c.name
ORDER BY 도서수 DESC;

-- ============================================================
-- [집계] Q10. 월별 대여 건수 집계 GROUP BY
-- MySQL: DATE_FORMAT() 함수 사용
-- ============================================================
SELECT
    DATE_FORMAT(r.rented_at, '%Y-%m')                          AS 연월,  -- MySQL 전용: DATE_FORMAT()
    COUNT(*)                                                    AS 대여건수,
    SUM(CASE WHEN r.status = 'RETURNED' THEN 1 ELSE 0 END)    AS 반납완료,
    SUM(CASE WHEN r.status = 'RENTING'  THEN 1 ELSE 0 END)    AS 대출중,
    SUM(CASE WHEN r.status = 'OVERDUE'  THEN 1 ELSE 0 END)    AS 연체
FROM rental r
GROUP BY DATE_FORMAT(r.rented_at, '%Y-%m')
ORDER BY 연월 ASC;

-- ============================================================
-- [집계] Q11. 리뷰를 2개 이상 작성한 회원의 평균 별점 HAVING
-- ============================================================
SELECT
    m.name                   AS 회원명,
    m.grade                  AS 등급,
    COUNT(rv.review_id)      AS 작성리뷰수,
    ROUND(AVG(rv.rating), 2) AS 평균별점
FROM member m
JOIN review rv ON m.member_id = rv.member_id
GROUP BY m.member_id, m.name, m.grade
HAVING COUNT(rv.review_id) >= 2
ORDER BY 평균별점 DESC;

-- ============================================================
-- [서브쿼리] Q12. 전체 평균 별점보다 높은 별점의 도서 목록
-- ============================================================
SELECT
    b.title                    AS 도서명,
    b.author                   AS 저자,
    c.name                     AS 카테고리,
    ROUND(AVG(rv.rating), 2)   AS 평균별점,
    ROUND(
        (SELECT AVG(rating) FROM review), 2
    )                          AS 전체평균별점
FROM book b
JOIN review    rv ON b.book_id     = rv.book_id
JOIN category  c  ON b.category_id = c.category_id
GROUP BY b.book_id, b.title, b.author, c.name
HAVING AVG(rv.rating) > (SELECT AVG(rating) FROM review)
ORDER BY 평균별점 DESC;

-- ============================================================
-- [인덱스] Q13. 인덱스 생성 및 확인
-- rental 테이블의 status, member_id, book_id는 WHERE/JOIN에 빈번히 사용됨
-- review 테이블의 book_id는 도서별 집계 쿼리에서 자주 사용됨
-- ============================================================
CREATE INDEX idx_rental_status ON rental(status);
CREATE INDEX idx_rental_member ON rental(member_id);
CREATE INDEX idx_rental_book   ON rental(book_id);
CREATE INDEX idx_review_book   ON review(book_id);

-- 인덱스 생성 확인 (MySQL 전용)
SHOW INDEX FROM rental;
SHOW INDEX FROM review;

-- ============================================================
-- [수정/삭제] Q14. UPDATE — rental_id=4 연체 도서 반납 처리
-- ============================================================
-- 반납 처리 전 상태 확인
SELECT r.rental_id, m.name AS 회원명, b.title AS 도서명,
       r.status AS 상태, r.returned_at AS 반납일, b.available_copies AS 현재대출가능수
FROM rental r
JOIN member m ON r.member_id = m.member_id
JOIN book   b ON r.book_id   = b.book_id
WHERE r.rental_id = 4;

-- 반납 상태로 업데이트
UPDATE rental
SET
    returned_at = '2024-04-15',
    status      = 'RETURNED'
WHERE rental_id = 4;

-- 해당 도서 대출 가능 권수 +1
UPDATE book
SET available_copies = available_copies + 1
WHERE book_id = (SELECT book_id FROM rental WHERE rental_id = 4);

-- 업데이트 후 확인
SELECT r.rental_id, m.name AS 회원명, b.title AS 도서명,
       r.status AS 상태, r.returned_at AS 반납일, b.available_copies AS 현재대출가능수
FROM rental r
JOIN member m ON r.member_id = m.member_id
JOIN book   b ON r.book_id   = b.book_id
WHERE r.rental_id = 4;

-- ============================================================
-- [수정/삭제] Q15. DELETE — member_id=4의 별점 2점 이하 리뷰 삭제
-- ============================================================
-- 삭제 전 확인
SELECT rv.review_id, m.name AS 작성자, b.title AS 도서명,
       rv.rating AS 별점, rv.content AS 리뷰내용
FROM review rv
JOIN member m ON rv.member_id = m.member_id
JOIN book   b ON rv.book_id   = b.book_id
WHERE rv.member_id = 4 AND rv.rating <= 2;

-- 삭제 실행
DELETE FROM review
WHERE member_id = 4 AND rating <= 2;

-- 삭제 후 확인 (결과 없으면 정상 삭제됨)
SELECT rv.review_id, m.name AS 작성자, b.title AS 도서명,
       rv.rating AS 별점
FROM review rv
JOIN member m ON rv.member_id = m.member_id
JOIN book   b ON rv.book_id   = b.book_id
WHERE rv.member_id = 4;
