USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GET_CODELIST]') AND type in (N'TF'))
DROP FUNCTION [dbo].[GET_CODELIST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ================================================
-- 名称			: GET_CODELIST
-- 機能			: 範囲設定値レコード変換
-- 引き数		: @STRING CHAR 対象文字列
-- 戻り値		: TABLE
-- 作成日		: 2016/05/13  作成者 : MSYS T.Shibata
-- ================================================

CREATE FUNCTION [dbo].[GET_CODELIST]
(
	@String as varchar(max) --対象文字列
)
RETURNS @RST TABLE 
(
	CD bigint
)
AS
BEGIN

	DECLARE @Delimiter CHAR(1)
	DECLARE @DelimiterSE CHAR(1) --開始終了用デリミタ

	SET @Delimiter = ','
	SET @DelimiterSE = '-'

	DECLARE @Counter integer
	DECLARE @StartNum integer
	DECLARE @EndNum integer
	DECLARE @TEMPTable TABLE (CD bigint)

	DECLARE @curTables CURSOR
	SET @curTables = CURSOR FOR

	--区切り文字「,」でレコード（開始値，終了値）に分解してカーソルに設定
	Select
		CASE WHEN CHARINDEX(@DelimiterSE, VALUE) <> 0 THEN SUBSTRING(VALUE, 1, CHARINDEX(@DelimiterSE, VALUE) - 1) ELSE VALUE END AS START_VALUE,
		CASE WHEN CHARINDEX(@DelimiterSE, VALUE) <> 0 THEN SUBSTRING(VALUE, CHARINDEX(@DelimiterSE, VALUE) + 1, LEN(VALUE) - CHARINDEX(@DelimiterSE, VALUE)) ELSE VALUE END AS START_VALUE
	From SPLIT(@String,@Delimiter)

	OPEN @curTables

	FETCH NEXT FROM @curTables
	INTO @StartNum,@EndNum

	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		SET @Counter = 0

		WHILE (@StartNum + @Counter < @EndNum + 1)
		BEGIN

			INSERT INTO @TEMPTable
			SELECT @StartNum + @Counter

			SET @Counter = @Counter + 1

		END

		FETCH NEXT FROM @curTables
		INTO @StartNum,@EndNum

	END

	CLOSE @curTables
	DEALLOCATE @curTables

	--重複行は除外して結果を返す
	INSERT INTO @RST
	SELECT DISTINCT * FROM @TEMPTable

	RETURN

END

GO
