WITH qr (r)
AS (
          SELECT 1
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
)
SELECT
  qr1.r AS c1
, qr2.r AS c2
, qr3.r AS c3
, qr4.r AS c4
FROM
           (SELECT 1 AS c, qr.r FROM qr) AS qr1
CROSS JOIN (SELECT 2 AS c, qr.r FROM qr) AS qr2
CROSS JOIN (SELECT 3 AS c, qr.r FROM qr) AS qr3
CROSS JOIN (SELECT 4 AS c, qr.r FROM qr) AS qr4
WHERE 1=1
-- check rows
AND qr1.r <> qr2.r
AND qr1.r <> qr3.r
AND qr1.r <> qr4.r
AND qr2.r <> qr3.r
AND qr2.r <> qr4.r
AND qr3.r <> qr4.r
-- check diagonals
AND ABS(qr1.c - qr2.c) <> ABS(qr1.r - qr2.r)
AND ABS(qr1.c - qr3.c) <> ABS(qr1.r - qr3.r)
AND ABS(qr1.c - qr4.c) <> ABS(qr1.r - qr4.r)
AND ABS(qr2.c - qr3.c) <> ABS(qr2.r - qr3.r)
AND ABS(qr2.c - qr4.c) <> ABS(qr2.r - qr4.r)
AND ABS(qr3.c - qr4.c) <> ABS(qr3.r - qr4.r)
;