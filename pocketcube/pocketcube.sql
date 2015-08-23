-- pocketcube.sql
-- Generate all possible transformations
-- for a 2x2x2 Rubik's Pocket Cube

-- Each cubie state is represented as 8 numeric values
-- which correspond to 8 cubes and their orientation
-- The positional layout is as follows, where each
-- 
-- (top half)
-- +-+-+
-- |1|2|
-- +-+-+
-- |3|4|
-- +-+-+
-- (bottom half, oriented 180 degrees up)
-- +-+-+
-- |5|6|
-- +-+-+
-- |7|8|
-- +-+-+
-- 
-- Each cube is oriented with the perspective
-- of viewing from the top or bottom
-- Orientations are 0, +, or -
-- for no rotation, clockwise, or anti-clockwise
-- 
-- We persist the cube as cubes and their orientation as TINYINT values
-- / 10 is the cube number, % 10 is the orientation
-- so 42 is cube 4 oriented anti-clockwise
-- 
-- A solved cube has this layout: 10, 20, 30, 40, 50, 60, 70, 80
-- These are persisted as a BIGINT value 1,020,304,050,607,080
-- 
-- This corresponds to a cube with the colours
-- 
--     GREEN                (back)
--     WHITE                (top)
-- RED BLUE   ORANGE (left, front, right)
--     YELLOW              (bottom)
--     GREEN                (back)
-- 
-- We translate cubes and their positions, colours clockwise
-- 
-- 1=WRG, 2=WGO, 3=WBR, 4=WOB (top)
-- 5=YRB, 6=YBO, 7=YGR, 8=YOG (bottom)
-- 

-- Table for what the faces are for each cube and orientation
-- Faces are one of six colours (W)hite, (R)ed, (B)lue, (O)range, (Y)ellow, (G)reen
-- We concatenate three letters together for the cubie three faces
-- Top, right, left faces (going clockwise)
IF	OBJECT_ID('cubie_face') IS NULL
BEGIN
	CREATE TABLE dbo.cubie_face (
		cubenum TINYINT NOT NULL PRIMARY KEY CLUSTERED
	,	faces   CHAR(3) NOT NULL
	)
	-- How cubies look with no orientation
	INSERT INTO cubie_face (cubenum, faces)
	VALUES
		(10, 'WRG') --, (11, 'GWR'), (12, 'RGW')
	,	(20, 'WGO')
	,	(30, 'WBR')
	,	(40, 'WOB')
	,	(50, 'YRB')
	,	(60, 'YBO')
	,	(70, 'YGR')
	,	(80, 'YOG')
	;
	-- ...with clockwise rotation
	INSERT INTO cubie_face (cubenum, faces)
	SELECT cubenum + 1, SUBSTRING(faces, 3, 1) + SUBSTRING(faces, 1, 1) + SUBSTRING(faces, 2, 1)
	FROM cubie_face where cubenum % 10 = 0;
	-- ...with anti-clockwise rotation
	INSERT INTO cubie_face (cubenum, faces)
	SELECT cubenum + 2, SUBSTRING(faces, 2, 1) + SUBSTRING(faces, 3, 1) + SUBSTRING(faces, 1, 1)
	FROM cubie_face where cubenum % 10 = 0;
END;
GO
-- DROP TABLE cubie_face;

-- Table for which face stickers are visible in specific locations, for any cubie
-- This also corresponds to output order
-- 
-- Cube sticker positions (24 sticker faces)
--       01 02
--       03 04
-- 05 06 07 08 09 10
-- 11 12 13 14 15 16
--       17 18
--       19 20
--       21 22
--       23 24
IF	OBJECT_ID('sticker_face') IS NULL
BEGIN
	CREATE TABLE dbo.sticker_face (
		stickerpos TINYINT NOT NULL -- 1 through 24, corresponding to 24 sticker faces
	,	cubepos    TINYINT NOT NULL -- cube positions 1 through 8
	,	facepos    TINYINT NOT NULL -- which of the three cubie faces, 0, 1, or 2
	)
	INSERT INTO sticker_face (stickerpos, cubepos, facepos)
	VALUES
	-- Top face stickers
		(01, 1, 0) -- top, left-rear
	,	(02, 2, 0) -- top, right-rear
	,	(03, 3, 0) -- top, left-front
	,	(04, 4, 0) -- top, right-front
	-- Front face stickers
	,	(07, 3, 1) -- front, upper-left
	,	(08, 4, 2) -- front, upper-right
	,	(13, 5, 2) -- front, lower-left
	,	(14, 6, 1) -- front, lower-right
	-- Left face stickers
	,	(05, 1, 1) -- left, upper-rear
	,	(06, 3, 2) -- left, upper-front
	,	(11, 7, 2) -- left, lower-rear
	,	(12, 5, 1) -- left, lower-front
	-- Right face stickers
	,	(09, 4, 1) -- right, upper-front
	,	(10, 2, 2) -- right, upper-rear
	,	(15, 6, 2) -- right, lower-front
	,	(16, 8, 1) -- right, lower-rear
	-- Bottom face stickers
	,	(17, 5, 0) -- bottom, left-front
	,	(18, 6, 0) -- bottom, right-front
	,	(19, 7, 0) -- bottom, left-rear
	,	(20, 8, 0) -- bottom, right-rear
	-- Rear face stickers
	,	(21, 7, 1) -- rear, lower-left
	,	(22, 8, 2) -- rear, lower-right
	,	(23, 1, 2) -- rear, upper-left
	,	(24, 2, 1) -- rear, upper-left
	;
	CREATE UNIQUE CLUSTERED INDEX PK_sticker_face ON sticker_face (stickerpos);
END;
GO
-- DROP TABLE sticker_face;

IF	OBJECT_ID('print_cube') IS NULL
BEGIN
	EXEC('CREATE PROCEDURE dbo.print_cube AS SELECT 0;');
END;
GO

ALTER PROCEDURE dbo.print_cube (@cube_layout BIGINT)
AS
BEGIN
	-- For printing
	DECLARE
		@i             TINYINT
	,	@line          VARCHAR(30)
	,	@minstickerpos TINYINT
	,	@maxstickerpos TINYINT
	;
		
	-- Deduce individual cubes
	DECLARE @c TABLE (
		cubepos TINYINT NOT NULL PRIMARY KEY CLUSTERED -- 1 through 8
	,	cubenum TINYINT NOT NULL -- 10 through 83
	);
	INSERT INTO @c (cubepos, cubenum)
	          SELECT 1, (@cube_layout / 100000000000000) % 100
	UNION ALL SELECT 2, (@cube_layout /   1000000000000) % 100
	UNION ALL SELECT 3, (@cube_layout /     10000000000) % 100
	UNION ALL SELECT 4, (@cube_layout /       100000000) % 100
	UNION ALL SELECT 5, (@cube_layout /         1000000) % 100
	UNION ALL SELECT 6, (@cube_layout /           10000) % 100
	UNION ALL SELECT 7, (@cube_layout /             100) % 100
	UNION ALL SELECT 8, (@cube_layout                  ) % 100
	;
	
	-- Start printing
	PRINT '# Cube layout: ' + COALESCE(CAST(@cube_layout AS CHAR(20)), 'NULL');
	SET	@i = 0;
	WHILE
		@i < 8
	BEGIN
		SET	@i += 1;
		SET	@minstickerpos =
				CASE @i
					WHEN 1 THEN  1
					WHEN 2 THEN  3
					WHEN 3 THEN  5
					WHEN 4 THEN 11
					WHEN 5 THEN 17
					WHEN 6 THEN 19
					WHEN 7 THEN 21
					WHEN 8 THEN 23
					ELSE 0
				END;
		SET	@maxstickerpos =
				CASE
					WHEN @i IN (3, 4)
					THEN @minstickerpos + 5 -- middle rows
					ELSE @minstickerpos + 1 -- top or bottom
				END;
		IF	@i IN (1, 2, 6, 7, 8)
		BEGIN
			PRINT '        +---+---+';
		END;
		ELSE
		BEGIN
			PRINT '+---+---+---+---+---+---+';
		END;
		IF	@i IN (1, 2, 5, 6, 7, 8)
		BEGIN
			SET	@line = '        |';
		END;
		ELSE
		BEGIN
			SET	@line = '|';
		END;
		SELECT
			@line += ' ' + ISNULL(SUBSTRING(cubie_face.faces, sticker_face.facepos + 1, 1), '?') + ' |'
		FROM
			@c AS c
			-- cubie_face knows what the sticker colours are
			-- on cubenum, which is cube plus orientation
			INNER JOIN cubie_face
			ON	c.cubenum = cubie_face.cubenum
			-- sticker_face chooses which of the three cube faces
			-- is visible on each sticker location
			INNER JOIN sticker_face
			ON	sticker_face.cubepos = c.cubepos
		WHERE
			sticker_face.stickerpos BETWEEN @minstickerpos AND @maxstickerpos
		ORDER BY
			sticker_face.stickerpos
		;
		PRINT @line;
	  END;
	PRINT '        +---+---+';
END;
GO
-- DROP PROCEDURE print_cube;

IF	OBJECT_ID('transform_cube') IS NULL
BEGIN
	EXEC('CREATE FUNCTION dbo.transform_cube () RETURNS BIGINT AS BEGIN RETURN 0; END;');
END;
GO

-- Given a cube layout, transform into a new layout given a move
-- There are 18 possible single-face moves
--   U or U+ -- rotate upper face clockwise
--   U', U3, or U- -- rotate upper face anti-clockwise
--   U2 or U= -- rotate upper face 180 degrees
--   ...same for (D)own, (F)ront, (B)ack, (L)eft, (R)ight
-- There are 9 possible whole-cube rotations
--   x or x+ -- rotate entire cube along x-axis, clockwise from right
--   x', x3, or x- -- rotate entire cube along x-axis, anti-clockwise from right
--   x2 or x= -- rotate entire cube along x-axis, 180 degrees
--   ...same for y-axis (rotate from top) and z-axis (rotate from front)
ALTER FUNCTION dbo.transform_cube (@cube_layout BIGINT, @move CHAR(2))
	RETURNS BIGINT
AS
BEGIN
	DECLARE
		@movetype   CHAR(1) = LEFT(@move, 1)
	,	@rot        CHAR(1) = SUBSTRING(@move, 2, 1)
	,	@new_layout BIGINT
	;
	     IF @rot = ''   SET @rot = '+';
	ELSE IF @rot = '''' SET @rot = '-';
	ELSE IF @rot = '3'  SET @rot = '-';
	ELSE IF @rot = '2'  SET @rot = '=';
	SET	@move = @movetype + @rot;

	-- Decompose individual cubes in each of 8 positions
	DECLARE
		@c1 TINYINT = (@cube_layout / 100000000000000) % 100
	,	@c2 TINYINT = (@cube_layout /   1000000000000) % 100
	,	@c3 TINYINT = (@cube_layout /     10000000000) % 100
	,	@c4 TINYINT = (@cube_layout /       100000000) % 100
	,	@c5 TINYINT = (@cube_layout /         1000000) % 100
	,	@c6 TINYINT = (@cube_layout /           10000) % 100
	,	@c7 TINYINT = (@cube_layout /             100) % 100
	,	@c8 TINYINT = (@cube_layout                  ) % 100
	;

	-- New positions initially based on old ones
	DECLARE
		@d1 TINYINT = @c1
	,	@d2 TINYINT = @c2
	,	@d3 TINYINT = @c3
	,	@d4 TINYINT = @c4
	,	@d5 TINYINT = @c5
	,	@d6 TINYINT = @c6
	,	@d7 TINYINT = @c7
	,	@d8 TINYINT = @c8
	;
	
	-- Depending on the type of move, reposition cubies
	-- along with reorientation, if needed
	-- Note that, because of our conventions
	-- (U)p and (D)own faces never need cubes reoriented
	-- during those face turns

	-- Single face turns
	-- Up face
	     IF @move = 'U+' SELECT @d1 = @c3, @d2 = @c1, @d3 = @c4, @d4 = @c2;
	ELSE IF @move = 'U-' SELECT @d1 = @c2, @d2 = @c4, @d3 = @c1, @d4 = @c3;
	ELSE IF @move = 'U=' SELECT @d1 = @c4, @d2 = @c3, @d3 = @c2, @d4 = @c1;
	-- Down face
	ELSE IF	@move = 'D+' SELECT @d5 = @c7, @d6 = @c5, @d7 = @c8, @d8 = @c6;
	ELSE IF	@move = 'D-' SELECT @d5 = @c6, @d6 = @c8, @d7 = @c5, @d8 = @c7;
	ELSE IF	@move = 'D=' SELECT @d5 = @c8, @d6 = @c7, @d7 = @c6, @d8 = @c5;
	-- Front face
	ELSE IF	@move = 'F+' SELECT @d3 = @c5 + 2, @d4 = @c3 + 1, @d5 = @c6 + 1, @d6 = @c4 + 2;
	ELSE IF	@move = 'F-' SELECT @d3 = @c4 + 2, @d4 = @c6 + 1, @d5 = @c3 + 1, @d6 = @c5 + 2;
	ELSE IF	@move = 'F=' SELECT @d3 = @c6 + 0, @d4 = @c5 + 0, @d5 = @c4 + 0, @d6 = @c3 + 0;
	-- Back face
	ELSE IF	@move = 'B+' SELECT @d1 = @c2 + 1, @d2 = @c8 + 2, @d7 = @c1 + 2, @d8 = @c7 + 1;
	ELSE IF	@move = 'B-' SELECT @d1 = @c7 + 1, @d2 = @c1 + 2, @d7 = @c8 + 2, @d8 = @c2 + 1;
	ELSE IF	@move = 'B=' SELECT @d1 = @c8 + 0, @d2 = @c7 + 0, @d7 = @c2 + 0, @d8 = @c1 + 0;
	-- Left face
	ELSE IF @move = 'L+' SELECT @d1 = @c7 + 2, @d3 = @c1 + 1, @d5 = @c3 + 2, @d7 = @c5 + 1;
	ELSE IF @move = 'L-' SELECT @d1 = @c3 + 2, @d3 = @c5 + 1, @d5 = @c7 + 2, @d7 = @c1 + 1;
	ELSE IF @move = 'L=' SELECT @d1 = @c5 + 0, @d3 = @c7 + 0, @d5 = @c1 + 0, @d7 = @c3 + 0;
	-- Right face
	ELSE IF @move = 'R+' SELECT @d2 = @c4 + 1, @d4 = @c6 + 2, @d6 = @c8 + 1, @d8 = @c2 + 2;
	ELSE IF @move = 'R-' SELECT @d2 = @c8 + 1, @d4 = @c2 + 2, @d6 = @c4 + 1, @d8 = @c6 + 2;
	ELSE IF @move = 'R=' SELECT @d2 = @c6 + 0, @d4 = @c8 + 0, @d6 = @c2 + 0, @d8 = @c4 + 0;
	-- Whole cube rotations (no slicing)
	-- x-axis rotation, like R and -L
	ELSE IF @move = 'x+' SELECT @d2 = @c4 + 1, @d4 = @c6 + 2, @d6 = @c8 + 1, @d8 = @c2 + 2, @d1 = @c3 + 2, @d3 = @c5 + 1, @d5 = @c7 + 2, @d7 = @c1 + 1;
	ELSE IF @move = 'x-' SELECT @d2 = @c8 + 1, @d4 = @c2 + 2, @d6 = @c4 + 1, @d8 = @c6 + 2, @d1 = @c7 + 2, @d3 = @c1 + 1, @d5 = @c3 + 2, @d7 = @c5 + 1;
	ELSE IF @move = 'x=' SELECT @d2 = @c6 + 0, @d4 = @c8 + 0, @d6 = @c2 + 0, @d8 = @c4 + 0, @d1 = @c5 + 0, @d3 = @c7 + 0, @d5 = @c1 + 0, @d7 = @c3 + 0;
	-- y-axis rotation, like U and -D
	ELSE IF @move = 'y+' SELECT @d1 = @c3, @d2 = @c1, @d3 = @c4, @d4 = @c2, @d5 = @c6, @d6 = @c8, @d7 = @c5, @d8 = @c7;
	ELSE IF @move = 'y-' SELECT @d1 = @c2, @d2 = @c4, @d3 = @c1, @d4 = @c3, @d5 = @c7, @d6 = @c5, @d7 = @c8, @d8 = @c6;
	ELSE IF @move = 'y=' SELECT @d1 = @c4, @d2 = @c3, @d3 = @c2, @d4 = @c1, @d5 = @c8, @d6 = @c7, @d7 = @c6, @d8 = @c5;
	-- z-axis rotation, like F and -B
	ELSE IF @move = 'z+' SELECT @d3 = @c5 + 2, @d4 = @c3 + 1, @d5 = @c6 + 1, @d6 = @c4 + 2, @d1 = @c7 + 1, @d2 = @c1 + 2, @d7 = @c8 + 2, @d8 = @c2 + 1;
	ELSE IF @move = 'z-' SELECT @d3 = @c4 + 2, @d4 = @c6 + 1, @d5 = @c3 + 1, @d6 = @c5 + 2, @d1 = @c2 + 1, @d2 = @c8 + 2, @d7 = @c1 + 2, @d8 = @c7 + 1;
	ELSE IF @move = 'z=' SELECT @d3 = @c6 + 0, @d4 = @c5 + 0, @d5 = @c4 + 0, @d6 = @c3 + 0, @d1 = @c8 + 0, @d2 = @c7 + 0, @d7 = @c2 + 0, @d8 = @c1 + 0;
	-- Otherwise, signal an error
	-- We can't actually throw an error in a UDF
	ELSE                 SELECT @d1 = 0, @d2 = 0, @d3 = 0, @d4 = 0, @d5 = 0, @d6 = 0, @d7 = 0, @d8 = 0;

	-- Normalise rotations
	-- All rotations are clockwise
	-- An anti-clockwise rotation is really two clockwise ones
	-- So all rotations are clockwise, and we can modulo 3
	SELECT
		@d1 = (@d1 / 10) * 10 + ((@d1 % 10) % 3)
	,	@d2 = (@d2 / 10) * 10 + ((@d2 % 10) % 3)
	,	@d3 = (@d3 / 10) * 10 + ((@d3 % 10) % 3)
	,	@d4 = (@d4 / 10) * 10 + ((@d4 % 10) % 3)
	,	@d5 = (@d5 / 10) * 10 + ((@d5 % 10) % 3)
	,	@d6 = (@d6 / 10) * 10 + ((@d6 % 10) % 3)
	,	@d7 = (@d7 / 10) * 10 + ((@d7 % 10) % 3)
	,	@d8 = (@d8 / 10) * 10 + ((@d8 % 10) % 3)
	;

	-- Return new layout
	SET	@new_layout =
			CAST(@d1 AS BIGINT) * 100000000000000
		+	CAST(@d2 AS BIGINT) *   1000000000000
		+	CAST(@d3 AS BIGINT) *     10000000000
		+	CAST(@d4 AS BIGINT) *       100000000
		+	CAST(@d5 AS BIGINT) *         1000000
		+	CAST(@d6 AS BIGINT) *           10000
		+	CAST(@d7 AS BIGINT) *             100
		+	CAST(@d8 AS BIGINT)
	RETURN @new_layout;
END;
GO
-- DROP function dbo.transform_cube;

-- Table to hold all possible pocket cube transformations
IF	OBJECT_ID('cube_state') IS NULL
BEGIN
	CREATE TABLE dbo.cube_state (
		id          INT     NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED
	,	cube_layout BIGINT  NOT NULL -- cube position encoded as decimal value
	,	step_count  INT     NOT NULL -- number of steps away from a complete solution
	,	solve_id    INT     NULL -- ref to self pointing toward solution
	,	solvemove   CHAR(2) NULL -- move to make toward solution
	);
	CREATE UNIQUE INDEX UX_cube_state_cube_layout ON dbo.cube_state (cube_layout);
	CREATE        INDEX X_cube_state_solve_id     ON dbo.cube_state (solve_id);
END;
GO
-- DROP TABLE dbo.cube_state;

-- Static table for solve moves and their inverses
IF	OBJECT_ID('cube_move') IS NULL
BEGIN
	CREATE TABLE dbo.cube_move (
		id                 INT     NOT NULL IDENTITY(1, 1) -- For sorting
	,	transformationmove CHAR(2) NOT NULL PRIMARY KEY
	,	inversemove        CHAR(2) NOT NULL
	);
END;
IF	NOT EXISTS (
		SELECT *
		FROM
			dbo.cube_move
	)
BEGIN
	WITH mini_turn (id, mini_turn) AS (
		          SELECT 1, 'U'
		UNION ALL SELECT 2, 'D'
		UNION ALL SELECT 3, 'F'
		UNION ALL SELECT 4, 'B'
		UNION ALL SELECT 5, 'L'
		UNION ALL SELECT 6, 'R'
		UNION ALL SELECT 7, 'x'
		UNION ALL SELECT 8, 'y'
		UNION ALL SELECT 9, 'z'
	)
	,	mini_move (id, mini_move, inverse_mini_move) AS (
		          SELECT 1, '+', '-'
		UNION ALL SELECT 2, '-', '+'
		UNION ALL SELECT 3, '=', '='
	)
	INSERT INTO cube_move (transformationmove, inversemove)
	SELECT
		mini_turn.mini_turn + mini_move.mini_move         AS transformationmove
	,	mini_turn.mini_turn + mini_move.inverse_mini_move AS inversemove
	FROM
		mini_turn
		CROSS JOIN mini_move
	ORDER BY
		mini_turn.id
	,	mini_move.id
	;
END;
GO
-- DROP TABLE dbo.cube_move;

-- Seed very first row
IF	NOT EXISTS (
		SELECT *
		FROM
			dbo.cube_state
		WHERE
			dbo.cube_state.cube_layout = 1020304050607080
	)
BEGIN
	INSERT INTO dbo.cube_state (cube_layout, step_count, solve_id, solvemove)
	VALUES (1020304050607080, 0, NULL, NULL);
END;
GO

-- Set up counter
IF	OBJECT_ID('cube_state_counter') IS NULL
BEGIN
	CREATE TABLE dbo.cube_state_counter (
		last_id INT NULL
	);
END;
IF	NOT EXISTS (
	SELECT *
	FROM
		dbo.cube_state_counter
	)
BEGIN
	INSERT INTO dbo.cube_state_counter (last_id)
	SELECT
		MAX(cube_state.id) - 1
	FROM
		cube_state
	;
END;
GO
-- DROP TABLE dbo.cube_state_counter

-- Step through
DECLARE
	@i          INT = 0       -- for iterations
,	@maxi       INT = 1000000 -- how many iterations do we want?
,	@cc         INT           -- last cube counter
,	@c          BIGINT        -- cube layout
,	@step_count INT           -- number of steps from solution
,	@id         INT           -- PK of current row
;
WHILE
	@i < @maxi
BEGIN
	SET	@i += 1;
	PRINT '# Iteration @i = ' + ISNULL(RTRIM(@i), 'NULL');
	SELECT
		@id = dbo.cube_state_counter.last_id
	FROM
		dbo.cube_state_counter
	;
	SET	@c          = NULL;
	SET	@step_count = NULL;
	SELECT TOP 1
		@id         = dbo.cube_state.id
	,	@c          = dbo.cube_state.cube_layout
	,	@step_count = dbo.cube_state.step_count
	FROM
		dbo.cube_state
	WHERE
		dbo.cube_state.id > @id
	ORDER BY
		dbo.cube_state.id
	;
	PRINT '# Processing @id = ' + ISNULL(RTRIM(@id), 'NULL') + ', @c = ' + ISNULL(RTRIM(@c), 'NULL') + ', @step_count = ' + ISNULL(RTRIM(@step_count), 'NULL');
	IF	@c IS NOT NULL
	BEGIN
		WITH transformations (id, cube_layout, transformationmove, inversemove) AS (
			SELECT
				dbo.cube_move.id
			,	dbo.transform_cube(@c, dbo.cube_move.transformationmove)
			,	dbo.cube_move.transformationmove
			,	dbo.cube_move.inversemove
			FROM
				dbo.cube_move
			-- NOTE: I have decided to reduce the number of possible cube states
			-- by locking the very first cube while allowing remaining seven to move
			-- This means that certain moves that alter the first cube
			-- are no longer permitted
			-- The first cube is upper-left-rear, so U, L, B moves not permitted
			-- Also, entire cube rotations x, y, z are not permitted
			WHERE
				dbo.cube_move.transformationmove IN (
					'D+', 'D-', 'D=', 'R+', 'R-', 'R=', 'F+', 'F-', 'F='
				)
		)
		INSERT INTO dbo.cube_state (
			cube_layout
		,	solve_id
		,	solvemove
		,	step_count
		)
		-- We do not need distinct layouts
		-- as no two transformations are identical
		SELECT
			transformations.cube_layout
		,	@id                         AS solve_id
		,	transformations.inversemove AS solvemove
		,	@step_count + 1             AS step_count
		FROM
			transformations
		WHERE
			NOT EXISTS (
					SELECT *
					FROM
						dbo.cube_state AS other_transformations
					WHERE
						other_transformations.cube_layout = transformations.cube_layout
			)
		ORDER BY
			transformations.id
		;
		UPDATE
			dbo.cube_state_counter
		SET
			dbo.cube_state_counter.last_id = @id
		FROM
			dbo.cube_state_counter
		;
	END;
	ELSE
	BEGIN
		BREAK;
	END;
END;
GO
-- SELECT * FROM dbo.cube_state_counter;
-- SELECT * FROM dbo.cube_state;
-- TRUNCATE TABLE dbo.cube_state;

/*
-- Solve a cube that requires 11 transformations
DECLARE
	@initial_cube_layout BIGINT = 1080527041322061
;
WITH solve_steps (cube_layout, step_count, solve_id, solvemove) AS (
	-- "Seed" query for the recursive query
	SELECT
		dbo.cube_state.cube_layout
	,	dbo.cube_state.step_count
	,	dbo.cube_state.solve_id
	,	dbo.cube_state.solvemove
	FROM
		dbo.cube_state
	WHERE
		dbo.cube_state.cube_layout = @initial_cube_layout
	-- Recursive portion
	UNION ALL
	SELECT
		dbo.cube_state.cube_layout
	,	dbo.cube_state.step_count
	,	dbo.cube_state.solve_id
	,	dbo.cube_state.solvemove
	FROM
		dbo.cube_state
		INNER JOIN solve_steps
		ON	dbo.cube_state.id = solve_steps.solve_id
)
SELECT *
FROM
	solve_steps
ORDER BY
	solve_steps.step_count DESC
;
*/

/*
-- Unit tests based on solved cube transformations
EXEC print_cube @cube_layout = 1020304050607080;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'U+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'U-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'U='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'D+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'D-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'U='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'F+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'F-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'F='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'B+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'B-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'B='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'L+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'L-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'L='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'R+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'R-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'R='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'x+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'x-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'x='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'y+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'y-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'y='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'z+'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'z-'); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'z='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'U='), 'U+'), 'U-'), 'U='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'D='), 'D+'), 'D-'), 'D='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'F='), 'F+'), 'F-'), 'F='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'B='), 'B+'), 'B-'), 'B='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'L='), 'L+'), 'L-'), 'L='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'R='), 'R+'), 'R-'), 'R='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'x='), 'x+'), 'x-'), 'x='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'y='), 'y+'), 'y-'), 'y='); EXEC print_cube @cube_layout = @foo;
DECLARE @foo BIGINT = dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(dbo.transform_cube(1020304050607080, 'z='), 'z+'), 'z-'), 'z='); EXEC print_cube @cube_layout = @foo;
*/
