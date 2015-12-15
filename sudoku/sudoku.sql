-- Create table to hold sudoku board possibilities
CREATE TABLE #sudoku (
    id SMALLINT NOT NULL IDENTITY(1, 1) -- values 1-729
        PRIMARY KEY CLUSTERED
,   c  TINYINT  NOT NULL -- column 1-9
,   r  TINYINT  NOT NULL -- row 1-9
,   s  AS (r-1)/3*3+(c-1)/3+1 PERSISTED
       -- section 1-9
,   n  TINYINT  NOT NULL -- numeral 1-9
,   v  AS CAST(POWER(2, n-1) AS SMALLINT) PERSISTED
       -- bitmask value 1, 2, 4, 8, ... 256
,   ns AS CAST(n AS CHAR(1)) -- string representation
);

-- Create covering indices for each attribute
CREATE INDEX #sudoku_crsnv_x1 ON #sudoku (c, r, s, n, v);
CREATE INDEX #sudoku_rcsnv_x1 ON #sudoku (r, c, s, n, v);
CREATE INDEX #sudoku_scrnv_x1 ON #sudoku (s, c, r, n, v);
CREATE INDEX #sudoku_ncrsn_x1 ON #sudoku (n, c, r, s, v);
CREATE INDEX #sudoku_vcrsv_x1 ON #sudoku (v, c, r, s, n);

-- Prepopulate with all possible values (729, nine for each of 81 cells)
WITH val9 (n)
AS
(
              SELECT CAST(1 AS TINYINT) AS n
    UNION ALL SELECT CAST(2 AS TINYINT) AS n
    UNION ALL SELECT CAST(3 AS TINYINT) AS n
    UNION ALL SELECT CAST(4 AS TINYINT) AS n
    UNION ALL SELECT CAST(5 AS TINYINT) AS n
    UNION ALL SELECT CAST(6 AS TINYINT) AS n
    UNION ALL SELECT CAST(7 AS TINYINT) AS n
    UNION ALL SELECT CAST(8 AS TINYINT) AS n
    UNION ALL SELECT CAST(9 AS TINYINT) AS n
)
INSERT INTO #sudoku (c, r, n)
SELECT
    c.n AS c
,   r.n AS r
    -- section s is automatically computed based on c, r
,   v.n AS n
    -- bitmask v is automatically computed based on n
FROM
    val9 AS c
    CROSS JOIN
    val9 AS r
    CROSS JOIN
    val9 AS v
ORDER BY
    r.n
,   c.n
;

-- Variable to hold seed values from puzzle
DECLARE
    @puzzle CHAR(81) -- string of numbers 1-9 or spaces
;
 
-- NY Times Sudoku "Easy" (2015-12-14)
SET	@puzzle =
	'  83   26' +
	' 712  8  ' +
	'342 98 7 ' +
	' 2 957 1 ' +
	'7   12  9' +
	'18    75 ' +
	'  316    ' +
	'8 4   13 ' +
	' 17   2 4';

-- NY Times Sudoku "Hard" (2015-12-14)
SET	@puzzle =
	'     5 19' +
	'   6     ' +
	'5  283   ' +
	'      4  ' +
	'9   58  2' +
	'  34   6 ' +
	'79      3' +
	'4   3 79 ' +
	'  8  7   ';

-- Take the seeds and delete possibilities
WITH val9 (val)
AS
(
              SELECT CAST(1 AS TINYINT) AS val
    UNION ALL SELECT CAST(2 AS TINYINT) AS val
    UNION ALL SELECT CAST(3 AS TINYINT) AS val
    UNION ALL SELECT CAST(4 AS TINYINT) AS val
    UNION ALL SELECT CAST(5 AS TINYINT) AS val
    UNION ALL SELECT CAST(6 AS TINYINT) AS val
    UNION ALL SELECT CAST(7 AS TINYINT) AS val
    UNION ALL SELECT CAST(8 AS TINYINT) AS val
    UNION ALL SELECT CAST(9 AS TINYINT) AS val
)
DELETE
    #sudoku
FROM
    val9 AS c
    CROSS JOIN
    val9 AS r
    CROSS APPLY
    (
        SELECT
            CAST(SUBSTRING(@puzzle, (r.val-1)*9+c.val, 1) AS TINYINT) AS s
    ) AS s
    INNER JOIN #sudoku
    ON  #sudoku.c = c.val
    AND #sudoku.r = r.val
    AND #sudoku.n <> s.s
WHERE
    s.s IN (1, 2, 3, 4, 5, 6, 7, 8, 9)
;

/*
-- We do this multiple times, as needed

-- For each cell that has only one possibility
-- We can delete all other possibilities with the same numeral
-- in the same row, column, or section
WITH fixed (c, r, s, n)
AS
(
    -- Select only those cells
    -- where there is but one possibility
    SELECT
        c, r, s, min(n) AS n
    FROM
        #sudoku
    GROUP BY
        c, r, s
    HAVING
        COUNT(*) = 1
)
DELETE
    #sudoku
FROM
    #sudoku
    INNER JOIN fixed
    -- Look for cells in the same column, row, or section
    ON  (   fixed.c = #sudoku.c
        OR  fixed.r = #sudoku.r
        OR  fixed.s = #sudoku.s
        )
    -- ...that have the same numeral
    AND fixed.n = #sudoku.n
    -- ...but can't be the same cell
    AND (   fixed.c <> #sudoku.c
        OR  fixed.r <> #sudoku.r
        )
;
*/

DECLARE @rowcount INT = -1;
WHILE @rowcount <> 0
  BEGIN
    -- We have to delete more impossibilities, and we can do this iteratively
    -- For each cell that has only one possibility
    -- We can delete all other possibilities with the same numeral
    -- in the same row, column, or section
    WITH fixed (c, r, s, n)
    AS
    (
        -- Select only those cells
        -- where there is but one possibility
        SELECT
            c, r, s, min(n) AS n
        FROM
            #sudoku
        GROUP BY
            c, r, s
        HAVING
            COUNT(*) = 1
    )
    DELETE
        #sudoku
    FROM
        #sudoku
        INNER JOIN fixed
        -- Look for cells in the same column, row, or section
        ON  (   fixed.c = #sudoku.c
            OR  fixed.r = #sudoku.r
            OR  fixed.s = #sudoku.s
            )
        -- ...that have the same numeral
        AND fixed.n = #sudoku.n
        -- ...but can't be the same cell
        AND (   fixed.c <> #sudoku.c
            OR  fixed.r <> #sudoku.r
            )
    ;
    SET @rowcount = @@ROWCOUNT;
  END;

-- Now that we have deleted impossibilities
-- We can query for the ONLY possibility that will satisfy
SELECT '
' + s11.ns + s21.ns + s31.ns + s41.ns + s51.ns + s61.ns + s71.ns + s81.ns + s91.ns + '
' + s12.ns + s22.ns + s32.ns + s42.ns + s52.ns + s62.ns + s72.ns + s82.ns + s92.ns + '
' + s13.ns + s23.ns + s33.ns + s43.ns + s53.ns + s63.ns + s73.ns + s83.ns + s93.ns + '
' + s14.ns + s24.ns + s34.ns + s44.ns + s54.ns + s64.ns + s74.ns + s84.ns + s94.ns + '
' + s15.ns + s25.ns + s35.ns + s45.ns + s55.ns + s65.ns + s75.ns + s85.ns + s95.ns + '
' + s16.ns + s26.ns + s36.ns + s46.ns + s56.ns + s66.ns + s76.ns + s86.ns + s96.ns + '
' + s17.ns + s27.ns + s37.ns + s47.ns + s57.ns + s67.ns + s77.ns + s87.ns + s97.ns + '
' + s18.ns + s28.ns + s38.ns + s48.ns + s58.ns + s68.ns + s78.ns + s88.ns + s98.ns + '
' + s19.ns + s29.ns + s39.ns + s49.ns + s59.ns + s69.ns + s79.ns + s89.ns + s99.ns
FROM
	           #sudoku AS s11
	CROSS JOIN #sudoku AS s21
	CROSS JOIN #sudoku AS s31
	CROSS JOIN #sudoku AS s41
	CROSS JOIN #sudoku AS s51
	CROSS JOIN #sudoku AS s61
	CROSS JOIN #sudoku AS s71
	CROSS JOIN #sudoku AS s81
	CROSS JOIN #sudoku AS s91
	CROSS JOIN #sudoku AS s12
	CROSS JOIN #sudoku AS s22
	CROSS JOIN #sudoku AS s32
	CROSS JOIN #sudoku AS s42
	CROSS JOIN #sudoku AS s52
	CROSS JOIN #sudoku AS s62
	CROSS JOIN #sudoku AS s72
	CROSS JOIN #sudoku AS s82
	CROSS JOIN #sudoku AS s92
	CROSS JOIN #sudoku AS s13
	CROSS JOIN #sudoku AS s23
	CROSS JOIN #sudoku AS s33
	CROSS JOIN #sudoku AS s43
	CROSS JOIN #sudoku AS s53
	CROSS JOIN #sudoku AS s63
	CROSS JOIN #sudoku AS s73
	CROSS JOIN #sudoku AS s83
	CROSS JOIN #sudoku AS s93
	CROSS JOIN #sudoku AS s14
	CROSS JOIN #sudoku AS s24
	CROSS JOIN #sudoku AS s34
	CROSS JOIN #sudoku AS s44
	CROSS JOIN #sudoku AS s54
	CROSS JOIN #sudoku AS s64
	CROSS JOIN #sudoku AS s74
	CROSS JOIN #sudoku AS s84
	CROSS JOIN #sudoku AS s94
	CROSS JOIN #sudoku AS s15
	CROSS JOIN #sudoku AS s25
	CROSS JOIN #sudoku AS s35
	CROSS JOIN #sudoku AS s45
	CROSS JOIN #sudoku AS s55
	CROSS JOIN #sudoku AS s65
	CROSS JOIN #sudoku AS s75
	CROSS JOIN #sudoku AS s85
	CROSS JOIN #sudoku AS s95
	CROSS JOIN #sudoku AS s16
	CROSS JOIN #sudoku AS s26
	CROSS JOIN #sudoku AS s36
	CROSS JOIN #sudoku AS s46
	CROSS JOIN #sudoku AS s56
	CROSS JOIN #sudoku AS s66
	CROSS JOIN #sudoku AS s76
	CROSS JOIN #sudoku AS s86
	CROSS JOIN #sudoku AS s96
	CROSS JOIN #sudoku AS s17
	CROSS JOIN #sudoku AS s27
	CROSS JOIN #sudoku AS s37
	CROSS JOIN #sudoku AS s47
	CROSS JOIN #sudoku AS s57
	CROSS JOIN #sudoku AS s67
	CROSS JOIN #sudoku AS s77
	CROSS JOIN #sudoku AS s87
	CROSS JOIN #sudoku AS s97
	CROSS JOIN #sudoku AS s18
	CROSS JOIN #sudoku AS s28
	CROSS JOIN #sudoku AS s38
	CROSS JOIN #sudoku AS s48
	CROSS JOIN #sudoku AS s58
	CROSS JOIN #sudoku AS s68
	CROSS JOIN #sudoku AS s78
	CROSS JOIN #sudoku AS s88
	CROSS JOIN #sudoku AS s98
	CROSS JOIN #sudoku AS s19
	CROSS JOIN #sudoku AS s29
	CROSS JOIN #sudoku AS s39
	CROSS JOIN #sudoku AS s49
	CROSS JOIN #sudoku AS s59
	CROSS JOIN #sudoku AS s69
	CROSS JOIN #sudoku AS s79
	CROSS JOIN #sudoku AS s89
	CROSS JOIN #sudoku AS s99
WHERE
	-- Establish that they are in proper position
	s11.c = 1 AND s11.r = 1
AND	s21.c = 2 AND s21.r = 1
AND	s31.c = 3 AND s31.r = 1
AND	s41.c = 4 AND s41.r = 1
AND	s51.c = 5 AND s51.r = 1
AND	s61.c = 6 AND s61.r = 1
AND	s71.c = 7 AND s71.r = 1
AND	s81.c = 8 AND s81.r = 1
AND	s91.c = 9 AND s91.r = 1
AND	s12.c = 1 AND s12.r = 2
AND	s22.c = 2 AND s22.r = 2
AND	s32.c = 3 AND s32.r = 2
AND	s42.c = 4 AND s42.r = 2
AND	s52.c = 5 AND s52.r = 2
AND	s62.c = 6 AND s62.r = 2
AND	s72.c = 7 AND s72.r = 2
AND	s82.c = 8 AND s82.r = 2
AND	s92.c = 9 AND s92.r = 2
AND	s13.c = 1 AND s13.r = 3
AND	s23.c = 2 AND s23.r = 3
AND	s33.c = 3 AND s33.r = 3
AND	s43.c = 4 AND s43.r = 3
AND	s53.c = 5 AND s53.r = 3
AND	s63.c = 6 AND s63.r = 3
AND	s73.c = 7 AND s73.r = 3
AND	s83.c = 8 AND s83.r = 3
AND	s93.c = 9 AND s93.r = 3
AND	s14.c = 1 AND s14.r = 4
AND	s24.c = 2 AND s24.r = 4
AND	s34.c = 3 AND s34.r = 4
AND	s44.c = 4 AND s44.r = 4
AND	s54.c = 5 AND s54.r = 4
AND	s64.c = 6 AND s64.r = 4
AND	s74.c = 7 AND s74.r = 4
AND	s84.c = 8 AND s84.r = 4
AND	s94.c = 9 AND s94.r = 4
AND	s15.c = 1 AND s15.r = 5
AND	s25.c = 2 AND s25.r = 5
AND	s35.c = 3 AND s35.r = 5
AND	s45.c = 4 AND s45.r = 5
AND	s55.c = 5 AND s55.r = 5
AND	s65.c = 6 AND s65.r = 5
AND	s75.c = 7 AND s75.r = 5
AND	s85.c = 8 AND s85.r = 5
AND	s95.c = 9 AND s95.r = 5
AND	s16.c = 1 AND s16.r = 6
AND	s26.c = 2 AND s26.r = 6
AND	s36.c = 3 AND s36.r = 6
AND	s46.c = 4 AND s46.r = 6
AND	s56.c = 5 AND s56.r = 6
AND	s66.c = 6 AND s66.r = 6
AND	s76.c = 7 AND s76.r = 6
AND	s86.c = 8 AND s86.r = 6
AND	s96.c = 9 AND s96.r = 6
AND	s17.c = 1 AND s17.r = 7
AND	s27.c = 2 AND s27.r = 7
AND	s37.c = 3 AND s37.r = 7
AND	s47.c = 4 AND s47.r = 7
AND	s57.c = 5 AND s57.r = 7
AND	s67.c = 6 AND s67.r = 7
AND	s77.c = 7 AND s77.r = 7
AND	s87.c = 8 AND s87.r = 7
AND	s97.c = 9 AND s97.r = 7
AND	s18.c = 1 AND s18.r = 8
AND	s28.c = 2 AND s28.r = 8
AND	s38.c = 3 AND s38.r = 8
AND	s48.c = 4 AND s48.r = 8
AND	s58.c = 5 AND s58.r = 8
AND	s68.c = 6 AND s68.r = 8
AND	s78.c = 7 AND s78.r = 8
AND	s88.c = 8 AND s88.r = 8
AND	s98.c = 9 AND s98.r = 8
AND	s19.c = 1 AND s19.r = 9
AND	s29.c = 2 AND s29.r = 9
AND	s39.c = 3 AND s39.r = 9
AND	s49.c = 4 AND s49.r = 9
AND	s59.c = 5 AND s59.r = 9
AND	s69.c = 6 AND s69.r = 9
AND	s79.c = 7 AND s79.r = 9
AND	s89.c = 8 AND s89.r = 9
AND	s99.c = 9 AND s99.r = 9
	-- Now sum up by row
AND	s11.v + s21.v + s31.v + s41.v + s51.v + s61.v + s71.v + s81.v + s91.v = 511
AND	s12.v + s22.v + s32.v + s42.v + s52.v + s62.v + s72.v + s82.v + s92.v = 511
AND	s13.v + s23.v + s33.v + s43.v + s53.v + s63.v + s73.v + s83.v + s93.v = 511
AND	s14.v + s24.v + s34.v + s44.v + s54.v + s64.v + s74.v + s84.v + s94.v = 511
AND	s15.v + s25.v + s35.v + s45.v + s55.v + s65.v + s75.v + s85.v + s95.v = 511
AND	s16.v + s26.v + s36.v + s46.v + s56.v + s66.v + s76.v + s86.v + s96.v = 511
AND	s17.v + s27.v + s37.v + s47.v + s57.v + s67.v + s77.v + s87.v + s97.v = 511
AND	s18.v + s28.v + s38.v + s48.v + s58.v + s68.v + s78.v + s88.v + s98.v = 511
AND	s19.v + s29.v + s39.v + s49.v + s59.v + s69.v + s79.v + s89.v + s99.v = 511
	-- Now sum up by column
AND	s11.v + s12.v + s13.v + s14.v + s15.v + s16.v + s17.v + s18.v + s19.v = 511
AND	s21.v + s22.v + s23.v + s24.v + s25.v + s26.v + s27.v + s28.v + s29.v = 511
AND	s31.v + s32.v + s33.v + s34.v + s35.v + s36.v + s37.v + s38.v + s39.v = 511
AND	s41.v + s42.v + s43.v + s44.v + s45.v + s46.v + s47.v + s48.v + s49.v = 511
AND	s51.v + s52.v + s53.v + s54.v + s55.v + s56.v + s57.v + s58.v + s59.v = 511
AND	s61.v + s62.v + s63.v + s64.v + s65.v + s66.v + s67.v + s68.v + s69.v = 511
AND	s71.v + s72.v + s73.v + s74.v + s75.v + s76.v + s77.v + s78.v + s79.v = 511
AND	s81.v + s82.v + s83.v + s84.v + s85.v + s86.v + s87.v + s88.v + s89.v = 511
AND	s91.v + s92.v + s93.v + s94.v + s95.v + s96.v + s97.v + s98.v + s99.v = 511
	-- Now sum up by section
AND	s11.v + s21.v + s31.v + s12.v + s22.v + s32.v + s13.v + s23.v + s33.v = 511
AND	s41.v + s51.v + s61.v + s42.v + s52.v + s62.v + s43.v + s53.v + s63.v = 511
AND	s71.v + s81.v + s91.v + s72.v + s82.v + s92.v + s73.v + s83.v + s93.v = 511
AND	s14.v + s24.v + s34.v + s15.v + s25.v + s35.v + s16.v + s26.v + s36.v = 511
AND	s44.v + s54.v + s64.v + s45.v + s55.v + s65.v + s46.v + s56.v + s66.v = 511
AND	s74.v + s84.v + s94.v + s75.v + s85.v + s95.v + s76.v + s86.v + s96.v = 511
AND	s17.v + s27.v + s37.v + s18.v + s28.v + s38.v + s19.v + s29.v + s39.v = 511
AND	s47.v + s57.v + s67.v + s48.v + s58.v + s68.v + s49.v + s59.v + s69.v = 511
AND	s77.v + s87.v + s97.v + s78.v + s88.v + s98.v + s79.v + s89.v + s99.v = 511
;

-- Query to print a partially solved board
SELECT '
' + s11.ns + s21.ns + s31.ns + s41.ns + s51.ns + s61.ns + s71.ns + s81.ns + s91.ns + '
' + s12.ns + s22.ns + s32.ns + s42.ns + s52.ns + s62.ns + s72.ns + s82.ns + s92.ns + '
' + s13.ns + s23.ns + s33.ns + s43.ns + s53.ns + s63.ns + s73.ns + s83.ns + s93.ns + '
' + s14.ns + s24.ns + s34.ns + s44.ns + s54.ns + s64.ns + s74.ns + s84.ns + s94.ns + '
' + s15.ns + s25.ns + s35.ns + s45.ns + s55.ns + s65.ns + s75.ns + s85.ns + s95.ns + '
' + s16.ns + s26.ns + s36.ns + s46.ns + s56.ns + s66.ns + s76.ns + s86.ns + s96.ns + '
' + s17.ns + s27.ns + s37.ns + s47.ns + s57.ns + s67.ns + s77.ns + s87.ns + s97.ns + '
' + s18.ns + s28.ns + s38.ns + s48.ns + s58.ns + s68.ns + s78.ns + s88.ns + s98.ns + '
' + s19.ns + s29.ns + s39.ns + s49.ns + s59.ns + s69.ns + s79.ns + s89.ns + s99.ns
FROM
               (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=1) AS s11
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=1) AS s21
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=1) AS s31
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=1) AS s41
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=1) AS s51
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=1) AS s61
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=1) AS s71
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=1) AS s81
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=1) AS s91
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=2) AS s12
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=2) AS s22
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=2) AS s32
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=2) AS s42
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=2) AS s52
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=2) AS s62
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=2) AS s72
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=2) AS s82
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=2) AS s92
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=3) AS s13
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=3) AS s23
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=3) AS s33
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=3) AS s43
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=3) AS s53
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=3) AS s63
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=3) AS s73
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=3) AS s83
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=3) AS s93
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=4) AS s14
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=4) AS s24
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=4) AS s34
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=4) AS s44
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=4) AS s54
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=4) AS s64
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=4) AS s74
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=4) AS s84
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=4) AS s94
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=5) AS s15
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=5) AS s25
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=5) AS s35
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=5) AS s45
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=5) AS s55
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=5) AS s65
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=5) AS s75
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=5) AS s85
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=5) AS s95
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=6) AS s16
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=6) AS s26
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=6) AS s36
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=6) AS s46
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=6) AS s56
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=6) AS s66
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=6) AS s76
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=6) AS s86
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=6) AS s96
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=7) AS s17
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=7) AS s27
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=7) AS s37
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=7) AS s47
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=7) AS s57
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=7) AS s67
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=7) AS s77
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=7) AS s87
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=7) AS s97
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=8) AS s18
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=8) AS s28
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=8) AS s38
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=8) AS s48
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=8) AS s58
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=8) AS s68
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=8) AS s78
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=8) AS s88
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=8) AS s98
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=1 AND r=9) AS s19
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=2 AND r=9) AS s29
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=3 AND r=9) AS s39
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=4 AND r=9) AS s49
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=5 AND r=9) AS s59
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=6 AND r=9) AS s69
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=7 AND r=9) AS s79
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=8 AND r=9) AS s89
    CROSS JOIN (SELECT CASE WHEN COUNT(*) = 1 THEN MIN(ns) ELSE ' ' END AS ns FROM #sudoku WHERE c=9 AND r=9) AS s99
;

DROP TABLE #sudoku;
