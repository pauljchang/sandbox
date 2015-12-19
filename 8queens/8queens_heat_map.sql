WITH qr (r)
AS (
          SELECT 1
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5
UNION ALL SELECT 6
UNION ALL SELECT 7
UNION ALL SELECT 8
)
,	sols (c1, c2, c3, c4, c5, c6, c7, c8)
AS (
SELECT
  qr1.r AS c1
, qr2.r AS c2
, qr3.r AS c3
, qr4.r AS c4
, qr5.r AS c5
, qr6.r AS c6
, qr7.r AS c7
, qr8.r AS c8
FROM
           (SELECT 1 AS c, qr.r FROM qr) AS qr1
CROSS JOIN (SELECT 2 AS c, qr.r FROM qr) AS qr2
CROSS JOIN (SELECT 3 AS c, qr.r FROM qr) AS qr3
CROSS JOIN (SELECT 4 AS c, qr.r FROM qr) AS qr4
CROSS JOIN (SELECT 5 AS c, qr.r FROM qr) AS qr5
CROSS JOIN (SELECT 6 AS c, qr.r FROM qr) AS qr6
CROSS JOIN (SELECT 7 AS c, qr.r FROM qr) AS qr7
CROSS JOIN (SELECT 8 AS c, qr.r FROM qr) AS qr8
WHERE 1=1
-- check rows
AND qr1.r NOT IN (qr2.r, qr3.r, qr4.r, qr5.r, qr6.r, qr7.r, qr8.r)
AND qr2.r NOT IN (qr3.r, qr4.r, qr5.r, qr6.r, qr7.r, qr8.r)
AND qr3.r NOT IN (qr4.r, qr5.r, qr6.r, qr7.r, qr8.r)
AND qr4.r NOT IN (qr5.r, qr6.r, qr7.r, qr8.r)
AND qr5.r NOT IN (qr6.r, qr7.r, qr8.r)
AND qr6.r NOT IN (qr7.r, qr8.r)
AND qr7.r NOT IN (qr8.r)
-- check diagonals
AND ABS(qr1.c - qr2.c) <> ABS(qr1.r - qr2.r)
AND ABS(qr1.c - qr3.c) <> ABS(qr1.r - qr3.r)
AND ABS(qr1.c - qr4.c) <> ABS(qr1.r - qr4.r)
AND ABS(qr1.c - qr5.c) <> ABS(qr1.r - qr5.r)
AND ABS(qr1.c - qr6.c) <> ABS(qr1.r - qr6.r)
AND ABS(qr1.c - qr7.c) <> ABS(qr1.r - qr7.r)
AND ABS(qr1.c - qr8.c) <> ABS(qr1.r - qr8.r)
AND ABS(qr2.c - qr3.c) <> ABS(qr2.r - qr3.r)
AND ABS(qr2.c - qr4.c) <> ABS(qr2.r - qr4.r)
AND ABS(qr2.c - qr5.c) <> ABS(qr2.r - qr5.r)
AND ABS(qr2.c - qr6.c) <> ABS(qr2.r - qr6.r)
AND ABS(qr2.c - qr7.c) <> ABS(qr2.r - qr7.r)
AND ABS(qr2.c - qr8.c) <> ABS(qr2.r - qr8.r)
AND ABS(qr3.c - qr4.c) <> ABS(qr3.r - qr4.r)
AND ABS(qr3.c - qr5.c) <> ABS(qr3.r - qr5.r)
AND ABS(qr3.c - qr6.c) <> ABS(qr3.r - qr6.r)
AND ABS(qr3.c - qr7.c) <> ABS(qr3.r - qr7.r)
AND ABS(qr3.c - qr8.c) <> ABS(qr3.r - qr8.r)
AND ABS(qr4.c - qr5.c) <> ABS(qr4.r - qr5.r)
AND ABS(qr4.c - qr6.c) <> ABS(qr4.r - qr6.r)
AND ABS(qr4.c - qr7.c) <> ABS(qr4.r - qr7.r)
AND ABS(qr4.c - qr8.c) <> ABS(qr4.r - qr8.r)
AND ABS(qr5.c - qr6.c) <> ABS(qr5.r - qr6.r)
AND ABS(qr5.c - qr7.c) <> ABS(qr5.r - qr7.r)
AND ABS(qr5.c - qr8.c) <> ABS(qr5.r - qr8.r)
AND ABS(qr6.c - qr7.c) <> ABS(qr6.r - qr7.r)
AND ABS(qr6.c - qr8.c) <> ABS(qr6.r - qr8.r)
AND ABS(qr7.c - qr8.c) <> ABS(qr7.r - qr8.r)
)
,	c1_count AS (
SELECT
	sols.c1, COUNT(*) AS c1_count
FROM
	sols
GROUP BY
	sols.c1
)
,	c2_count AS (
SELECT
	sols.c2, COUNT(*) AS c2_count
FROM
	sols
GROUP BY
	sols.c2
)
,	c3_count AS (
SELECT
	sols.c3, COUNT(*) AS c3_count
FROM
	sols
GROUP BY
	sols.c3
)
,	c4_count AS (
SELECT
	sols.c4, COUNT(*) AS c4_count
FROM
	sols
GROUP BY
	sols.c4
)
,	c5_count AS (
SELECT
	sols.c5, COUNT(*) AS c5_count
FROM
	sols
GROUP BY
	sols.c5
)
,	c6_count AS (
SELECT
	sols.c6, COUNT(*) AS c6_count
FROM
	sols
GROUP BY
	sols.c6
)
,	c7_count AS (
SELECT
	sols.c7, COUNT(*) AS c7_count
FROM
	sols
GROUP BY
	sols.c7
)
,	c8_count AS (
SELECT
	sols.c8, COUNT(*) AS c8_count
FROM
	sols
GROUP BY
	sols.c8
)
SELECT
	qr.r AS r
,	c1_count.c1_count AS c1
,	c2_count.c2_count AS c2
,	c3_count.c3_count AS c3
,	c4_count.c4_count AS c4
,	c5_count.c5_count AS c5
,	c6_count.c6_count AS c6
,	c7_count.c7_count AS c7
,	c8_count.c8_count AS c8
FROM
	qr
	LEFT JOIN c1_count ON c1_count.c1 = qr.r
	LEFT JOIN c2_count ON c2_count.c2 = qr.r
	LEFT JOIN c3_count ON c3_count.c3 = qr.r
	LEFT JOIN c4_count ON c4_count.c4 = qr.r
	LEFT JOIN c5_count ON c5_count.c5 = qr.r
	LEFT JOIN c6_count ON c6_count.c6 = qr.r
	LEFT JOIN c7_count ON c7_count.c7 = qr.r
	LEFT JOIN c8_count ON c8_count.c8 = qr.r
;
