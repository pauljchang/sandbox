-- pocketcube.sql

-- Each cube state is represented as 8 numeric values
-- which correspond to 8 cubes and their orientation
-- The positional layout is as follows
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
IF	OBJECT_ID('cubeface') IS NULL
  BEGIN
	CREATE TABLE dbo.cubeface (
		cubenum TINYINT NOT NULL PRIMARY KEY CLUSTERED
	,	faces   CHAR(3) NOT NULL
	)
	-- How cubies look with no orientation
	INSERT INTO cubeface (cubenum, faces)
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
	INSERT INTO cubeface (cubenum, faces)
	SELECT cubenum + 1, SUBSTRING(faces, 3, 1) + SUBSTRING(faces, 1, 1) + SUBSTRING(faces, 2, 1)
	FROM cubeface where cubenum % 10 = 0;
	-- ...with anti-clockwise rotation
	INSERT INTO cubeface (cubenum, faces)
	SELECT cubenum + 2, SUBSTRING(faces, 2, 1) + SUBSTRING(faces, 3, 1) + SUBSTRING(faces, 1, 1)
	FROM cubeface where cubenum % 10 = 0;
  END;
GO
-- DROP TABLE cubeface;

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
IF	OBJECT_ID('stickerface') IS NULL
  BEGIN
	CREATE TABLE dbo.stickerface (
		stickerpos TINYINT NOT NULL -- 1 through 24, corresponding to 24 sticker faces
	,	cubepos    TINYINT NOT NULL -- cube positions 1 through 8
	,	facepos    TINYINT NOT NULL -- which of the three cubie faces, 0, 1, or 2
	)
	INSERT INTO stickerface (stickerpos, cubepos, facepos)
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
	CREATE UNIQUE CLUSTERED INDEX PK_stickerface ON stickerface (stickerpos);
  END;
GO
-- DROP TABLE stickerface;

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
			@line += ' ' + ISNULL(SUBSTRING(cubeface.faces, stickerface.facepos + 1, 1), '?') + ' |'
		FROM
			@c AS c
			-- cubeface knows what the sticker colours are
			-- on cubenum, which is cube plus orientation
			INNER JOIN cubeface
			ON	c.cubenum = cubeface.cubenum
			-- stickerface chooses which of the three cube faces
			-- is visible on each sticker location
			INNER JOIN stickerface
			ON	stickerface.cubepos = c.cubepos
		WHERE
			stickerface.stickerpos BETWEEN @minstickerpos AND @maxstickerpos
		ORDER BY
			stickerface.stickerpos
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
	
	-- Depending on the type of move, reposition cubies
	-- along with reorientation, if needed
	-- Note that, because of our conventions
	-- (U)p and (D)own faces never need cubes reoriented
	-- during those face turns

	-- Single face turns
	-- Up face
	     IF @move = 'U+' SELECT @c1 = @c3, @c2 = @c1, @c3 = @c4, @c4 = @c2;
	ELSE IF @move = 'U-' SELECT @c1 = @c2, @c2 = @c4, @c3 = @c1, @c4 = @c3;
	ELSE IF @move = 'U=' SELECT @c1 = @c4, @c2 = @c3, @c3 = @c2, @c4 = @c1;
	-- Down face
	ELSE IF	@move = 'D+' SELECT @c5 = @c7, @c6 = @c5, @c7 = @c8, @c8 = @c6;
	ELSE IF	@move = 'D-' SELECT @c5 = @c6, @c6 = @c8, @c7 = @c5, @c8 = @c7;
	ELSE IF	@move = 'D=' SELECT @c5 = @c8, @c6 = @c7, @c7 = @c6, @c8 = @c5;
	-- Front face
	ELSE IF	@move = 'F+' SELECT @c3 = @c5 + 2, @c4 = @c3 + 1, @c5 = @c6 + 1, @c6 = @c4 + 2;
	ELSE IF	@move = 'F-' SELECT @c3 = @c4 + 2, @c4 = @c6 + 1, @c5 = @c3 + 1, @c6 = @c5 + 2;
	ELSE IF	@move = 'F=' SELECT @c3 = @c6 + 0, @c4 = @c5 + 0, @c5 = @c4 + 0, @c6 = @c3 + 0;
	-- Back face
	ELSE IF	@move = 'B+' SELECT @c1 = @c2 + 1, @c2 = @c8 + 2, @c7 = @c1 + 2, @c8 = @c7 + 1;
	ELSE IF	@move = 'B-' SELECT @c1 = @c7 + 1, @c2 = @c1 + 2, @c7 = @c8 + 2, @c8 = @c2 + 1;
	ELSE IF	@move = 'B=' SELECT @c1 = @c8 + 0, @c2 = @c7 + 0, @c7 = @c2 + 0, @c8 = @c1 + 0;
	-- Left face
	ELSE IF @move = 'L+' SELECT @c1 = @c7 + 2, @c3 = @c1 + 1, @c5 = @c3 + 2, @c7 = @c5 + 1;
	ELSE IF @move = 'L-' SELECT @c1 = @c3 + 2, @c3 = @c5 + 1, @c5 = @c7 + 2, @c7 = @c1 + 1;
	ELSE IF @move = 'L=' SELECT @c1 = @c5 + 0, @c3 = @c7 + 0, @c5 = @c1 + 0, @c7 = @c3 + 0;
	-- Right face
	ELSE IF @move = 'R+' SELECT @c2 = @c4 + 1, @c4 = @c6 + 2, @c6 = @c8 + 1, @c8 = @c2 + 2;
	ELSE IF @move = 'R-' SELECT @c2 = @c8 + 1, @c4 = @c2 + 2, @c6 = @c4 + 1, @c8 = @c6 + 2;
	ELSE IF @move = 'R=' SELECT @c2 = @c6 + 0, @c4 = @c8 + 0, @c6 = @c2 + 0, @c8 = @c4 + 0;
	-- Whole cube rotations (no slicing)
	-- x-axis rotation, like R and -L
	ELSE IF @move = 'x+' SELECT @c2 = @c4 + 1, @c4 = @c6 + 2, @c6 = @c8 + 1, @c8 = @c2 + 2, @c1 = @c3 + 2, @c3 = @c5 + 1, @c5 = @c7 + 2, @c7 = @c1 + 1;
	ELSE IF @move = 'x-' SELECT @c2 = @c8 + 1, @c4 = @c2 + 2, @c6 = @c4 + 1, @c8 = @c6 + 2, @c1 = @c7 + 2, @c3 = @c1 + 1, @c5 = @c3 + 2, @c7 = @c5 + 1;
	ELSE IF @move = 'x=' SELECT @c2 = @c6 + 0, @c4 = @c8 + 0, @c6 = @c2 + 0, @c8 = @c4 + 0, @c1 = @c5 + 0, @c3 = @c7 + 0, @c5 = @c1 + 0, @c7 = @c3 + 0;
	-- y-axis rotation, like U and -D
	ELSE IF @move = 'y+' SELECT @c1 = @c3, @c2 = @c1, @c3 = @c4, @c4 = @c2, @c5 = @c6, @c6 = @c8, @c7 = @c5, @c8 = @c7;
	ELSE IF @move = 'y-' SELECT @c1 = @c2, @c2 = @c4, @c3 = @c1, @c4 = @c3, @c5 = @c7, @c6 = @c5, @c7 = @c8, @c8 = @c6;
	ELSE IF @move = 'y=' SELECT @c2 = @c6 + 0, @c4 = @c8 + 0, @c6 = @c2 + 0, @c8 = @c4 + 0, @c1 = @c5 + 0, @c3 = @c7 + 0, @c5 = @c1 + 0, @c7 = @c3 + 0;
	-- z-axis rotation, like F and -B
	ELSE IF @move = 'z+' SELECT @c3 = @c5 + 2, @c4 = @c3 + 1, @c5 = @c6 + 1, @c6 = @c4 + 2, @c1 = @c7 + 1, @c2 = @c1 + 2, @c7 = @c8 + 2, @c8 = @c2 + 1;
	ELSE IF @move = 'z-' SELECT @c1 = @c2 + 1, @c2 = @c8 + 2, @c7 = @c1 + 2, @c8 = @c7 + 1, @c1 = @c2 + 1, @c2 = @c8 + 2, @c7 = @c1 + 2, @c8 = @c7 + 1;
	ELSE IF @move = 'z=' SELECT @c3 = @c6 + 0, @c4 = @c5 + 0, @c5 = @c4 + 0, @c6 = @c3 + 0, @c1 = @c8 + 0, @c2 = @c7 + 0, @c7 = @c2 + 0, @c8 = @c1 + 0;
	-- Otherwise, signal an error
	-- We can't actually throw an error in a UDF
	ELSE                 SELECT @c1 = 0, @c2 = 0, @c3 = 0, @c4 = 0, @c5 = 0, @c6 = 0, @c7 = 0, @c8 = 0;

	-- Normalise rotations
	-- All rotations are clockwise
	-- An anti-clockwise rotation is really two clockwise ones
	-- So all rotations are clockwise, and we can modulo 3
	SELECT
		@c1 = (@c1 / 10) * 10 + ((@c1 % 10) % 3)
	,	@c2 = (@c2 / 10) * 10 + ((@c2 % 10) % 3)
	,	@c3 = (@c3 / 10) * 10 + ((@c3 % 10) % 3)
	,	@c4 = (@c4 / 10) * 10 + ((@c4 % 10) % 3)
	,	@c5 = (@c5 / 10) * 10 + ((@c5 % 10) % 3)
	,	@c6 = (@c6 / 10) * 10 + ((@c6 % 10) % 3)
	,	@c7 = (@c7 / 10) * 10 + ((@c7 % 10) % 3)
	,	@c8 = (@c8 / 10) * 10 + ((@c8 % 10) % 3)
	;

	-- Return new layout
	SET	@new_layout =
			@c1 * 100000000000000
		+	@c2 *   1000000000000
		+	@c3 *     10000000000
		+	@c4 *       100000000
		+	@c5 *         1000000
		+	@c6 *           10000
		+	@c7 *             100
		+	@c8
	;
	RETURN @new_layout;
END;
GO

/*
EXEC print_cube @cube_layout = 1020304050607080;
DECLARE @foo BIGINT = dbo.transform_cube(1020304050607080, 'U+');

*/
