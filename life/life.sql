-- 
-- life.sql
-- 
-- 2015-08-13 Paul Chang (pauljchang@gmail.com)
-- 
-- Code to simulate John Conway's Game of Life, implemented in Microsoft SQL Server 2014
-- (https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
-- 
-- This code should be easily modifiable to be run on other RDBMS systems
-- that are compliant with ANSI SQL-92
-- 

-- 
-- dbo.num -- tally table
-- 
-- Tally tables are useful for quickly generating a range of values
-- We can do this with CTEs sometimes, but for large ranges of values
-- a dedicated tally table comes in handy
-- In this case, we use the num table to help us with printing
-- in dbo.print_cells
-- 
IF	OBJECT_ID('num') IS NULL
BEGIN
	CREATE TABLE dbo.num (
		num SMALLINT NOT NULL
	);
	CREATE UNIQUE CLUSTERED INDEX KUX_num ON dbo.num (num);

	-- Populate tally table
	-- First positive integers and zero
	WITH d (d)
	AS (
		          SELECT CAST(0 AS SMALLINT)
		UNION ALL SELECT CAST(1 AS SMALLINT)
		UNION ALL SELECT CAST(2 AS SMALLINT)
		UNION ALL SELECT CAST(3 AS SMALLINT)
		UNION ALL SELECT CAST(4 AS SMALLINT)
		UNION ALL SELECT CAST(5 AS SMALLINT)
		UNION ALL SELECT CAST(6 AS SMALLINT)
		UNION ALL SELECT CAST(7 AS SMALLINT)
		UNION ALL SELECT CAST(8 AS SMALLINT)
		UNION ALL SELECT CAST(9 AS SMALLINT)
	)
	INSERT INTO dbo.num (num)
	SELECT
		d0.d + 10 * d1.d + 100 * d2.d + 1000 * d3.d + 10000 * d4.d AS num
	FROM
		           d AS d0
		CROSS JOIN d AS d1
		CROSS JOIN d AS d2
		CROSS JOIN d AS d3
		CROSS JOIN d AS d4
	WHERE
		CAST(d0.d + 10 * d1.d + 100 * d2.d + 1000 * d3.d + 10000 * d4.d AS INT) BETWEEN 0 AND 32767
	ORDER BY
		d4.d
	,	d3.d
	,	d2.d
	,	d1.d
	,	d0.d
	;

	-- Now negative integers
	INSERT INTO dbo.num (num)
	SELECT
		dbo.num.num - 32768
	FROM
		dbo.num
	WHERE
		dbo.num.num BETWEEN 0 AND 32767
	;
END;
GO

-- 
-- dbo.cell -- Table to hold all cells
-- 
-- Each cell has an entry in the dbo.cell table
-- It knows its (x,y) coordinates, as well as the generation number
-- The generation number is useful for diagnostics
-- and indicates how "old" a cell is
-- 
IF	OBJECT_ID('cell') IS NULL
BEGIN
	CREATE TABLE dbo.cell (
		x   SMALLINT NOT NULL
	,	y   SMALLINT NOT NULL
	,	gen SMALLINT NOT NULL
	);
	CREATE UNIQUE CLUSTERED INDEX KUX_cell ON dbo.cell (y, x);
	CREATE UNIQUE INDEX UX_cell_x_y ON dbo.cell (x, y) INCLUDE (gen);
	CREATE INDEX X_cell_gen ON dbo.cell (gen, y, x);
END;
GO

-- Dummy proc
IF	OBJECT_ID('print_cells') IS NULL EXEC('CREATE PROCEDURE dbo.print_cells AS SELECT 0');
GO

-- 
-- dbo.print_cells -- print current state of cells to standard output
-- 
-- This proc works by looking at the minimum and maximum range of values
-- for x and y in cell and generates a rectangular box for display
-- Within the box, empty spaces indicate no cell, while numbers 0 - 9
-- indicate the generation number modulo 10
-- 
-- Sample output:
/*
# x range = [-1, 1], y range = [-1, 1], gen range = [0, 0]
   +---+
 1 | 00|
 0 |00 |
-1 | 0 |
   +---+
*/
ALTER PROCEDURE dbo.print_cells
AS
BEGIN
	DECLARE
		@y         SMALLINT
	,	@min_y     SMALLINT
	,	@max_y     SMALLINT
	,	@range_y   SMALLINT
	,	@max_y_len TINYINT
	,	@min_x     SMALLINT
	,	@max_x     SMALLINT
	,	@range_x   SMALLINT
	,	@min_gen   SMALLINT
	,	@max_gen   SMALLINT
	,	@line      VARCHAR(MAX)
	;

	-- Find rectangular boundaries of all cells
	SELECT
		@min_y     = MIN(dbo.cell.y)
	,	@max_y     = MAX(dbo.cell.y)
	,	@range_y   = MAX(dbo.cell.y) - MIN(dbo.cell.y)
	,	@max_y_len = MAX(LEN(RTRIM(CAST(dbo.cell.y AS CHAR(6)))))
	FROM
		dbo.cell
	;
	SELECT
		@min_x   = MIN(dbo.cell.x)
	,	@max_x   = MAX(dbo.cell.x)
	,	@range_x = MAX(dbo.cell.x) - MIN(dbo.cell.x)
	FROM
		dbo.cell
	;

	-- And the generation range
	SELECT
		@min_gen = MIN(dbo.cell.gen)
	,	@max_gen = MAX(dbo.cell.gen)
	FROM
		dbo.cell
	;

	-- Display some info
	PRINT '# x range = [' + COALESCE(RTRIM(CAST(@min_x AS CHAR(6))), 'NULL') + ', ' + COALESCE(RTRIM(CAST(@max_y AS CHAR(6))), 'NULL') + ']' +
		', y range = [' + COALESCE(RTRIM(CAST(@min_y AS CHAR(6))), 'NULL') + ', ' + COALESCE(RTRIM(CAST(@max_y AS CHAR(6))), 'NULL') + ']' +
		', gen range = [' + COALESCE(RTRIM(CAST(@min_gen AS CHAR(6))), 'NULL') + ', ' + COALESCE(RTRIM(CAST(@max_gen AS CHAR(6))), 'NULL') + ']';

	-- Start the rectangle
	PRINT REPLICATE(' ', @max_y_len) + ' +' + REPLICATE('-', COALESCE(@range_x, 0) + 1) + '+';

	-- Loop through y, concatenate a string for x
	-- Note, we loop through y backwards, as ascending y values go "up",
	-- so we must go backwards to print each line
	SET	@y = @max_y;
	WHILE
		@y >= @min_y
	BEGIN
		-- Construct a string of characters for all cells on one row of the y-axis
		-- Line starts with the y-value and the left border
		SET	@line = REPLICATE(' ', @max_y_len - LEN(RTRIM(CAST(@y AS CHAR(6))))) + RTRIM(CAST(@y AS CHAR(6))) + ' |';
		SELECT
			@line +=
				-- If the cell is not empty, use the last digit of the generation number
				-- Otherwise, just use a space
				CASE
					WHEN dbo.cell.gen IS NOT NULL
					THEN CAST(dbo.cell.gen % 10 AS CHAR(1))
					ELSE ' '
				END
		FROM
			dbo.num
			LEFT JOIN dbo.cell
			ON	dbo.cell.x = dbo.num.num + @min_x
			AND	dbo.cell.y = @y
		WHERE
			dbo.num.num BETWEEN 0 AND @range_x
		ORDER BY
			dbo.num.num
		;

		-- Line ends with right border
		SET	@line += '|';
		-- Print out the line we just built
		PRINT @line;

		-- Decrement y for the next line
		SET	@y -= 1;
	END;

	-- Close the rectangle
	PRINT REPLICATE(' ', @max_y_len) + ' +' + REPLICATE('-', COALESCE(@range_x, 0) + 1) + '+';
END;
GO

-- Dummy proc
IF	OBJECT_ID('step_cells') IS NULL EXEC('CREATE PROCEDURE dbo.step_cells AS SELECT 0');
GO

-- Step through one generation
ALTER PROCEDURE dbo.step_cells
AS
BEGIN
	DECLARE
		@gen     SMALLINT
	,	@max_gen SMALLINT
	;

	-- Find last generation number
	SELECT
		@max_gen = MAX(dbo.cell.gen)
	FROM
		dbo.cell
	;

	-- This generation is the next generation
	SET	@gen = @max_gen + 1;

	-- Generate new cells to be created based on the 3-neighbour rule
	-- Neighbours are any empty cells that surround current cells
	-- We also have to count how many neighbours there are
	-- so we create some CTEs to help us
	--  * delta -- a simple CTE that has just -1, 0, and 1
	--      used to look at cells to the left, right, above, and below
	--  * empty_neighbour -- a CTE based on empty spaces around every cell,
	--      these empty spaces are potential "birth" places for new cells
	--  * neighbour_count -- a CTE based on neighbour,
	--      we count how many cells surround each empty space,
	--      Note: This neighbour_count differs from the next query
	--      as we are counting neighbours around cells, not spaces
	WITH delta (num) AS (
		          SELECT CAST(-1 AS SMALLINT) AS num
		UNION ALL SELECT CAST( 0 AS SMALLINT) AS num
		UNION ALL SELECT CAST( 1 AS SMALLINT) AS num
	)
	,	empty_neighbour (x, y) AS (
		SELECT DISTINCT
			dbo.cell.x + delta_x.num AS x
		,	dbo.cell.y + delta_y.num AS y
		FROM
			dbo.cell
			CROSS JOIN delta AS delta_x
			CROSS JOIN delta AS delta_y
		WHERE
			NOT EXISTS (
				SELECT *
				FROM
					dbo.cell AS other_cell
				WHERE
					other_cell.x = dbo.cell.x + delta_x.num
				AND	other_cell.y = dbo.cell.y + delta_y.num
			)
	)
	,	neighbour_count (x, y, neighbour_count) AS (
		SELECT
			empty_neighbour.x
		,	empty_neighbour.y
			-- This expression is here to eliminate the silly NULL agregation warning
			-- Otherwise, we could just COUNT(other_cell.gen)
		,	COALESCE(SUM(CASE WHEN other_cell.gen IS NOT NULL THEN 1 ELSE 0 END), 0) AS neighbour_count
		FROM
			empty_neighbour
			CROSS JOIN delta AS delta_x
			CROSS JOIN delta AS delta_y
			LEFT JOIN dbo.cell AS other_cell
			ON	other_cell.x = empty_neighbour.x + delta_x.num
			AND	other_cell.y = empty_neighbour.y + delta_y.num
		GROUP BY
			empty_neighbour.x
		,	empty_neighbour.y
	)
	INSERT INTO dbo.cell (x, y, gen)
	SELECT
		neighbour_count.x
	,	neighbour_count.y
	,	@gen
	FROM
		neighbour_count
	WHERE
		neighbour_count.neighbour_count = 3
	ORDER BY
		neighbour_count.y
	,	neighbour_count.x
	;
	
	-- Now delete any cells with 1 or fewer neighbours (loneliness),
	-- or with 4 or more neighbours (overcrowded)
	-- We will ignore cells with the current generation
	-- because they were just created
	--  * delta -- a simple CTE that has just -1, 0, and 1
	--      used to look at cells to the left, right, above, and below
	--  * neighbour_count -- a CTE based on cell,
	--      we count how many neihbours surround each cell,
	--      Note: This neighbour_count differs from the previous query
	--      as we are counting neighbours around cells, not spaces
	WITH delta (num) AS (
		          SELECT CAST(-1 AS SMALLINT) AS num
		UNION ALL SELECT CAST( 0 AS SMALLINT) AS num
		UNION ALL SELECT CAST( 1 AS SMALLINT) AS num
	)
	,	neighbour_count (x, y, neighbour_count) AS (
		SELECT
			dbo.cell.x
		,	dbo.cell.y
			-- This expression is here to eliminate the silly NULL agregation warning
			-- Otherwise, we could just COUNT(other_cell.gen)
		,	COALESCE(SUM(CASE WHEN other_cell.gen IS NOT NULL THEN 1 ELSE 0 END), 0) AS neighbour_count
		FROM
			dbo.cell
			CROSS JOIN delta AS delta_x
			CROSS JOIN delta AS delta_y
			LEFT JOIN dbo.cell AS other_cell
			ON	other_cell.x = dbo.cell.x + delta_x.num
			AND	other_cell.y = dbo.cell.y + delta_y.num
			-- Don't count the cells we just created
			AND	other_cell.gen < @gen
			-- We don't want to count the cell itself, just neighbours
			AND	(	other_cell.x <> dbo.cell.x
				OR	other_cell.y <> dbo.cell.y
				)
		WHERE
			-- Don't count the cells we just created
			dbo.cell.gen < @gen
		GROUP BY
			dbo.cell.x
		,	dbo.cell.y
	)
	DELETE
		dbo.cell
	FROM
		dbo.cell
		INNER JOIN neighbour_count
		ON	neighbour_count.x = dbo.cell.x
		AND	neighbour_count.y = dbo.cell.y
		AND	(	neighbour_count.neighbour_count <= 1
			OR	neighbour_count.neighbour_count >= 4
			)
	;
END;

/*
-- Clear cells
truncate table dbo.cell;

-- 
-- R-pentamino example
-- (http://www.conwaylife.com/wiki/R-pentomino)
-- 
-- " ##"
-- "##"
-- " #"
-- 
IF NOT EXISTS (SELECT * FROM dbo.cell)
BEGIN
	INSERT INTO dbo.cell (x, y, gen)
	VALUES
		( 0,  1, 0)
	,	( 1,  1, 0)
	,	(-1,  0, 0)
	,	( 0,  0, 0)
	,	( 0, -1, 0)
	;
END;

-- Step through and print
EXEC dbo.step_cells;
EXEC dbo.print_cells;
*/
