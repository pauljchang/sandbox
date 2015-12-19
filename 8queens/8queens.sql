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
-- Ordering
ORDER BY
	qr1.r
,	qr2.r
,	qr3.r
,	qr4.r
,	qr5.r
,	qr6.r
,	qr7.r
,	qr8.r
;
